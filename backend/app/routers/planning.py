"""
Planning Router - intelligent planning endpoints.
"""

import logging
from datetime import date, datetime, time, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Path, Response, status
from sqlalchemy.orm import Session

from app import crud, schemas
from app.deps import get_current_user, get_db
from app.models.models import ChatDocument, SleepRecord, StudySession, User
from app.services.planning_service import generate_daily_schedule
from app.services.schedule_parser import is_csv_schedule, parse_csv_schedule

logger = logging.getLogger(__name__)

# ── Day boundaries for revision slots ─────────────────────────────────────────
_DAY_START_HOUR = 8   # 08:00
_DAY_END_HOUR = 22    # 22:00
_BUFFER_MINUTES = 15  # buffer before/after each class

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


# ── Sleep-based revision calibration ──────────────────────────────────────────

def _get_sleep_profile(
    db: Session,
    user_id: int,
    target_day: date,
) -> dict[str, Any]:
    """Return revision parameters calibrated on the user's latest sleep score.

    Returns a dict with:
      - max_session_min:  max duration of a single revision session
      - break_min:        minimum break between revision sessions
      - max_sessions:     cap on revision sessions for the day
      - priority:         priority tag for generated sessions
      - label:            human-readable sleep quality label
    """
    record: SleepRecord | None = crud.get_latest_sleep_record(db, user_id, target_day)
    score: int | None = record.sleep_score if record else None

    if score is not None and score >= 80:
        profile = {
            "max_session_min": 50,
            "break_min": 10,
            "max_sessions": 6,
            "priority": "high",
            "label": "Bien reposé",
        }
    elif score is not None and score < 50:
        profile = {
            "max_session_min": 25,
            "break_min": 20,
            "max_sessions": 2,
            "priority": "low",
            "label": "Sommeil insuffisant",
        }
    else:
        # Average sleep (50-79) or no data available
        profile = {
            "max_session_min": 35,
            "break_min": 15,
            "max_sessions": 4,
            "priority": "medium",
            "label": "Sommeil moyen" if score is not None else "Pas de données sommeil",
        }

    logger.info(
        "Sleep profile for user %d on %s: score=%s → %s (max %d min × %d sessions)",
        user_id, target_day.isoformat(), score, profile["label"],
        profile["max_session_min"], profile["max_sessions"],
    )
    return profile


def _build_revision_sessions(
    target_day: date,
    class_sessions: list[dict[str, Any]],
    sleep_profile: dict[str, Any],
) -> list[dict[str, Any]]:
    """Generate revision sessions in the free slots around *class_sessions*.

    The number, duration, and priority of revision sessions is driven by
    *sleep_profile* (see `_get_sleep_profile`).
    """
    if not class_sessions:
        return []

    max_min = sleep_profile["max_session_min"]
    break_min = sleep_profile["break_min"]
    max_sessions = sleep_profile["max_sessions"]
    priority = sleep_profile["priority"]

    day_start = datetime.combine(target_day, time(_DAY_START_HOUR, 0))
    day_end = datetime.combine(target_day, time(_DAY_END_HOUR, 0))
    buffer = timedelta(minutes=_BUFFER_MINUTES)

    # Sort classes chronologically
    sorted_classes = sorted(class_sessions, key=lambda s: s["start"])

    # Collect subjects for revision labelling (round-robin)
    subjects = [s["subject"] for s in sorted_classes]

    # ── Compute free slots ────────────────────────────────────────────────
    free_slots: list[tuple[datetime, datetime]] = []

    # Before first class
    first_start = sorted_classes[0]["start"]
    slot_end = first_start - buffer
    if slot_end > day_start:
        free_slots.append((day_start, slot_end))

    # Between classes
    for i in range(len(sorted_classes) - 1):
        gap_start = sorted_classes[i]["end"] + buffer
        gap_end = sorted_classes[i + 1]["start"] - buffer
        if gap_end > gap_start:
            free_slots.append((gap_start, gap_end))

    # After last class
    last_end = sorted_classes[-1]["end"]
    slot_start = last_end + buffer
    if slot_start < day_end:
        free_slots.append((slot_start, day_end))

    # ── Fill free slots with revision sessions ────────────────────────────
    revision_sessions: list[dict[str, Any]] = []
    subject_idx = 0
    session_duration = timedelta(minutes=max_min)
    break_delta = timedelta(minutes=break_min)

    for slot_start_dt, slot_end_dt in free_slots:
        if len(revision_sessions) >= max_sessions:
            break

        cursor = slot_start_dt
        while cursor + session_duration <= slot_end_dt and len(revision_sessions) < max_sessions:
            subject_label = f"Révision: {subjects[subject_idx % len(subjects)]}"
            revision_sessions.append({
                "subject": subject_label,
                "start": cursor,
                "end": cursor + session_duration,
                "priority": priority,
            })
            logger.info(
                "  + Revision: '%s' %s → %s [%s]",
                subject_label,
                cursor.strftime("%H:%M"),
                (cursor + session_duration).strftime("%H:%M"),
                priority,
            )
            subject_idx += 1
            cursor = cursor + session_duration + break_delta

    logger.info(
        "Generated %d revision sessions for %s (%s)",
        len(revision_sessions), target_day.isoformat(), sleep_profile["label"],
    )
    return revision_sessions


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
        class_sessions = parse_csv_schedule(
            file_path=doc_file_path,
            target_date=target_day,
            week_type=week_type,
        )
        if not class_sessions and not allow_empty_csv:
            from app.services.schedule_parser import _DAY_TO_WEEKDAY

            day_name = {v: k for k, v in _DAY_TO_WEEKDAY.items()}.get(target_day.weekday(), "?")
            iso_week = target_day.isocalendar()[1]
            auto_week = "A" if iso_week % 2 == 1 else "B"
            wt = week_type or auto_week
            raise ValueError(
                f"Aucun cours trouve pour {day_name.capitalize()} en semaine {wt}. "
                f"Verifiez votre fichier CSV."
            )

        # ── Sleep-aware revision sessions ─────────────────────────────────
        if class_sessions:
            sleep_profile = _get_sleep_profile(db, current_user.id, target_day)
            revision_sessions = _build_revision_sessions(
                target_day, class_sessions, sleep_profile,
            )
            return class_sessions + revision_sessions

        return class_sessions

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
