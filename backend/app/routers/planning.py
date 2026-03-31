"""
Planning Router — intelligent planning endpoints.
"""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Path, Response, status
from sqlalchemy.orm import Session

from app import crud, schemas
from app.deps import get_current_user, get_db
from app.models.models import StudySession, User, ChatDocument
from app.services.planning_service import generate_daily_schedule
from app.services.schedule_parser import is_csv_schedule, parse_csv_schedule

router = APIRouter(prefix="/api/v1/planning", tags=["Planning"])


def _to_day_response(day: date, sessions: list[StudySession]) -> schemas.PlanningDayOut:
    sessions_out = [schemas.StudySessionOut.model_validate(s) for s in sessions]
    return schemas.PlanningDayOut(
        planning=schemas.PlanningOut(date=day),
        sessions=sessions_out,
    )


@router.get("/today", response_model=schemas.PlanningDayOut)
def get_today(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    day = date.today()
    sessions = crud.get_study_sessions_by_date(db, current_user.id, day)
    return _to_day_response(day, sessions)


@router.post("/generate", response_model=schemas.PlanningDayOut, status_code=status.HTTP_201_CREATED)
def generate_planning(
    body: schemas.PlanningGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Only remove AI-generated sessions, keeping manual ones.
    crud.delete_study_sessions_by_date(db, current_user.id, body.date, only_ai=True)

    # Fetch remaining manual sessions for this day to serve as constraints
    existing_sessions = crud.get_study_sessions_by_date(db, current_user.id, body.date)
    profile = current_user.profile
    collection_name = None
    doc_file_path = None

    if body.document_id is not None:
        doc = (
            db.query(ChatDocument)
            .filter(ChatDocument.id == body.document_id, ChatDocument.user_id == current_user.id)
            .first()
        )
        if not doc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")
        collection_name = doc.chroma_collection
        doc_file_path = doc.file_path

    try:
        # If the document is a CSV schedule template, use deterministic parsing
        if doc_file_path and is_csv_schedule(doc_file_path):
            generated_sessions = parse_csv_schedule(
                file_path=doc_file_path,
                target_date=body.date,
                week_type=body.week_type,
            )
            if not generated_sessions:
                from app.services.schedule_parser import _FRENCH_DAYS, _DAY_TO_WEEKDAY
                day_name = {v: k for k, v in _DAY_TO_WEEKDAY.items()}.get(body.date.weekday(), "?")
                iso_week = body.date.isocalendar()[1]
                auto_week = "A" if iso_week % 2 == 1 else "B"
                wt = body.week_type or auto_week
                raise ValueError(
                    f"Aucun cours trouvé pour {day_name.capitalize()} en semaine {wt}. "
                    f"Vérifiez votre fichier CSV."
                )
        else:
            # Use LLM-based planning (existing Gemini approach)
            generated_sessions = generate_daily_schedule(
                day=body.date,
                existing_sessions=existing_sessions,
                profile=profile,
                preferences=body.preferences,
                collection_name=collection_name,
            )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Planning generation failed: {e}")

    created = []
    for item in generated_sessions:
        try:
            payload = schemas.StudySessionCreate(
                subject=item["subject"],
                start=item["start"],
                end=item["end"],
                priority=item.get("priority", "medium"),
            )
            created.append(
                crud.create_study_session(db, current_user.id, payload, is_ai_generated=True)
            )
        except (ValueError, KeyError) as e:
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))

    return _to_day_response(body.date, created)


@router.get("/{day}", response_model=schemas.PlanningDayOut)
def get_by_day(
    day: date = Path(..., description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sessions = crud.get_study_sessions_by_date(db, current_user.id, day)
    return _to_day_response(day, sessions)


@router.post("/sessions", response_model=schemas.StudySessionOut, status_code=status.HTTP_201_CREATED)
def create_session(
    body: schemas.StudySessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        session_obj = crud.create_study_session(db, current_user.id, body, is_ai_generated=False)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    return session_obj


@router.patch("/sessions/{id}", response_model=schemas.StudySessionOut)
def patch_session(
    id: int,
    body: schemas.StudySessionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session_obj = (
        db.query(StudySession)
        .filter(StudySession.id == id, StudySession.user_id == current_user.id)
        .first()
    )
    if not session_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    session_obj = crud.update_study_session(db, session_obj, body)
    return session_obj


@router.delete("/sessions/{id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_session(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session_obj = (
        db.query(StudySession)
        .filter(StudySession.id == id, StudySession.user_id == current_user.id)
        .first()
    )
    if not session_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    crud.delete_study_session(db, session_obj)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.patch("/sessions/{id}/complete", response_model=schemas.StudySessionOut)
def complete_session(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session_obj = (
        db.query(StudySession)
        .filter(StudySession.id == id, StudySession.user_id == current_user.id)
        .first()
    )
    if not session_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    session_obj = crud.complete_study_session(db, session_obj)
    return session_obj

