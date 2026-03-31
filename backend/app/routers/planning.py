"""
Planning Router - intelligent planning endpoints.
"""

from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Path, Response, status
from sqlalchemy.orm import Session

from app import crud, schemas
from app.deps import get_current_user, get_db
from app.models.models import ChatDocument, StudySession, User
from app.services.planning_service import generate_daily_schedule
from app.services.schedule_parser import is_csv_schedule, parse_csv_schedule

router = APIRouter(prefix="/api/v1/planning", tags=["Planning"])


def _to_day_response(day: date, sessions: list[StudySession]) -> schemas.PlanningDayOut:
    sessions_out = [schemas.StudySessionOut.model_validate(s) for s in sessions]
    return schemas.PlanningDayOut(
        planning=schemas.PlanningOut(date=day),
        sessions=sessions_out,
    )


def _week_days(anchor_day: date) -> list[date]:
    start_of_week = anchor_day - timedelta(days=anchor_day.weekday())
    return [start_of_week + timedelta(days=offset) for offset in range(7)]


def _load_planning_document(
    db: Session,
    current_user: User,
    document_id: int | None,
) -> tuple[str | None, str | None]:
    if document_id is None:
        return None, None

    doc = (
        db.query(ChatDocument)
        .filter(ChatDocument.id == document_id, ChatDocument.user_id == current_user.id)
        .first()
    )
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")

    return doc.chroma_collection, doc.file_path


def _generate_sessions_for_day(
    target_day: date,
    *,
    db: Session,
    current_user: User,
    preferences: schemas.PlanningPreferences | None,
    collection_name: str | None,
    doc_file_path: str | None,
    week_type: str | None,
    allow_empty_csv: bool = False,
) -> list[dict]:
    crud.delete_study_sessions_by_date(db, current_user.id, target_day, only_ai=True)
    existing_sessions = crud.get_study_sessions_by_date(db, current_user.id, target_day)

    if doc_file_path and is_csv_schedule(doc_file_path):
        generated_sessions = parse_csv_schedule(
            file_path=doc_file_path,
            target_date=target_day,
            week_type=week_type,
        )
        if not generated_sessions and not allow_empty_csv:
            from app.services.schedule_parser import _DAY_TO_WEEKDAY

            day_name = {v: k for k, v in _DAY_TO_WEEKDAY.items()}.get(target_day.weekday(), "?")
            iso_week = target_day.isocalendar()[1]
            auto_week = "A" if iso_week % 2 == 1 else "B"
            wt = week_type or auto_week
            raise ValueError(
                f"Aucun cours trouve pour {day_name.capitalize()} en semaine {wt}. "
                f"Verifiez votre fichier CSV."
            )
        return generated_sessions

    return generate_daily_schedule(
        day=target_day,
        existing_sessions=existing_sessions,
        profile=current_user.profile,
        preferences=preferences,
        collection_name=collection_name,
    )


def _create_ai_sessions_for_day(
    target_day: date,
    generated_sessions: list[dict],
    *,
    db: Session,
    current_user: User,
) -> schemas.PlanningDayOut:
    created: list[StudySession] = []
    for item in generated_sessions:
        payload = schemas.StudySessionCreate(
            subject=item["subject"],
            start=item["start"],
            end=item["end"],
            priority=item.get("priority", "medium"),
        )
        created.append(
            crud.create_study_session(db, current_user.id, payload, is_ai_generated=True)
        )

    return _to_day_response(target_day, created)


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
    collection_name, doc_file_path = _load_planning_document(
        db,
        current_user,
        body.document_id,
    )

    try:
        generated_sessions = _generate_sessions_for_day(
            body.date,
            db=db,
            current_user=current_user,
            preferences=body.preferences,
            collection_name=collection_name,
            doc_file_path=doc_file_path,
            week_type=body.week_type,
        )
        return _create_ai_sessions_for_day(
            body.date,
            generated_sessions,
            db=db,
            current_user=current_user,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except (KeyError, TypeError) as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Planning generation failed: {e}",
        )


@router.post("/generate/week", response_model=schemas.PlanningWeekOut, status_code=status.HTTP_201_CREATED)
def generate_week_planning(
    body: schemas.PlanningGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    collection_name, doc_file_path = _load_planning_document(
        db,
        current_user,
        body.document_id,
    )
    target_days = _week_days(body.date)
    days_out: list[schemas.PlanningDayOut] = []

    try:
        for target_day in target_days:
            generated_sessions = _generate_sessions_for_day(
                target_day,
                db=db,
                current_user=current_user,
                preferences=body.preferences,
                collection_name=collection_name,
                doc_file_path=doc_file_path,
                week_type=body.week_type,
                allow_empty_csv=True,
            )
            days_out.append(
                _create_ai_sessions_for_day(
                    target_day,
                    generated_sessions,
                    db=db,
                    current_user=current_user,
                )
            )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except (KeyError, TypeError) as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Weekly planning generation failed: {e}",
        )

    return schemas.PlanningWeekOut(
        week_start=target_days[0],
        week_end=target_days[-1],
        days=days_out,
    )


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
