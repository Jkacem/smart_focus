# backend/crud.py
"""
CRUD helpers for SQLAlchemy models.
"""

from datetime import date, datetime, time, timedelta, timezone
from typing import List, Optional

from sqlalchemy.orm import Session

from . import models, schemas
from .utils.datetime_utils import utc_now_naive
from .utils.security import hash_password


def _resolve_document_ids(
    document_id: int | None,
    document_ids: list[int] | None,
) -> list[int]:
    ordered_ids: list[int] = []
    if document_id is not None:
        ordered_ids.append(document_id)
    if document_ids:
        ordered_ids.extend(document_ids)

    unique_ids: list[int] = []
    seen: set[int] = set()
    for item in ordered_ids:
        if item in seen:
            continue
        seen.add(item)
        unique_ids.append(item)
    return unique_ids


def _sync_session_document_links(
    session_obj: models.StudySession,
    document_ids: list[int],
) -> None:
    target_ids = set(document_ids)

    session_obj.session_document_links = [
        link
        for link in session_obj.session_document_links
        if link.document_id in target_ids
    ]

    current_ids = {
        link.document_id
        for link in session_obj.session_document_links
        if link.document_id is not None
    }
    for document_id in document_ids:
        if document_id in current_ids:
            continue
        session_obj.session_document_links.append(
            models.StudySessionDocumentLink(document_id=document_id)
        )


# ══════════════════════════════════════════════
# USER
# ══════════════════════════════════════════════

def get_user(db: Session, user_id: int) -> Optional[models.User]:
    """Return a single User by its primary key or None."""
    return db.query(models.User).filter(models.User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """Lookup a user by email."""
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, user_in: schemas.UserCreate) -> models.User:
    """Create a new User with a hashed password and a default profile."""
    db_user = models.User(
        email=user_in.email,
        full_name=user_in.full_name,
        hashed_password=hash_password(user_in.password),
        role=user_in.role,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Auto-create a default profile
    db_profile = models.UserProfile(user_id=db_user.id)
    db.add(db_profile)


# ══════════════════════════════════════════════
# USER
# ══════════════════════════════════════════════

def get_user(db: Session, user_id: int) -> Optional[models.User]:
    """Return a single User by its primary key or None."""
    return db.query(models.User).filter(models.User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """Lookup a user by email."""
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, user_in: schemas.UserCreate) -> models.User:
    """Create a new User with a hashed password and a default profile."""
    db_user = models.User(
        email=user_in.email,
        full_name=user_in.full_name,
        hashed_password=hash_password(user_in.password),
        role=user_in.role,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Auto-create a default profile
    db_profile = models.UserProfile(user_id=db_user.id)
    db.add(db_profile)
    db.commit()

    return db_user


def update_last_login(db: Session, user: models.User) -> None:
    """Set last_login to now."""
    user.last_login = utc_now_naive()
    db.commit()


# ══════════════════════════════════════════════
# USER PROFILE
# ══════════════════════════════════════════════

def get_user_profile(db: Session, user_id: int) -> Optional[models.UserProfile]:
    """Return a user's profile."""
    return db.query(models.UserProfile).filter(
        models.UserProfile.user_id == user_id
    ).first()


def update_user_profile(
    db: Session,
    profile: models.UserProfile,
    updates: schemas.UserProfileUpdate,
) -> models.UserProfile:
    """Apply partial updates to a UserProfile."""
    for field, value in updates.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    db.commit()
    db.refresh(profile)
    return profile


def update_current_user_profile(
    db: Session,
    user: models.User,
    profile: models.UserProfile,
    updates: "schemas.CurrentUserProfileUpdate",
) -> tuple[models.User, models.UserProfile]:
    """Apply partial updates to both the user and profile models."""
    payload = updates.model_dump(exclude_unset=True)

    full_name = payload.pop("full_name", None)
    if full_name is not None:
        user.full_name = full_name.strip()

    role = payload.pop("role", None)
    if role is not None:
        user.role = role

    for field, value in payload.items():
        setattr(profile, field, value)

    db.commit()
    db.refresh(user)
    db.refresh(profile)
    return user, profile


# ══════════════════════════════════════════════
# SLEEP RECORDS
# ══════════════════════════════════════════════

def _compute_score(total_hours: Optional[float], deep_hours: Optional[float]) -> Optional[int]:
    """Simple heuristic sleep score (0-100) based on total and deep sleep hours."""
    if total_hours is None:
        return None
    # Target: 8 h total, 2 h deep
    score = min(total_hours / 8.0, 1.0) * 70
    if deep_hours is not None:
        score += min(deep_hours / 2.0, 1.0) * 30
    return round(min(score, 100))


def get_latest_sleep_record(
    db: Session,
    user_id: int,
    target_date: date,
) -> Optional[models.SleepRecord]:
    """Return the most recent sleep record on or before target_date for a user."""
    from datetime import datetime as _dt, time as _time
    end_of_day = _dt.combine(target_date, _time(23, 59, 59))
    return (
        db.query(models.SleepRecord)
        .filter(
            models.SleepRecord.user_id == user_id,
            models.SleepRecord.sleep_start <= end_of_day,
        )
        .order_by(models.SleepRecord.sleep_start.desc())
        .first()
    )


def create_sleep_record(
    db: Session,
    user_id: int,
    data: "schemas.SleepLogCreate",
) -> models.SleepRecord:
    """Insert a new SleepRecord and compute its score."""
    total_hours: Optional[float] = None
    if data.sleep_end:
        delta = data.sleep_end - data.sleep_start
        total_hours = round(delta.total_seconds() / 3600, 2)

    score = _compute_score(total_hours, data.deep_sleep_hours)

    record = models.SleepRecord(
        user_id=user_id,
        sleep_start=data.sleep_start,
        sleep_end=data.sleep_end,
        total_hours=total_hours,
        deep_sleep_hours=data.deep_sleep_hours,
        light_sleep_hours=data.light_sleep_hours,
        sleep_score=score,
        raw_sensor_data=data.raw_sensor_data,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def get_sleep_history(
    db: Session,
    user_id: int,
    limit: int = 30,
) -> list:
    """Return the most recent sleep records for a user."""
    return (
        db.query(models.SleepRecord)
        .filter(models.SleepRecord.user_id == user_id)
        .order_by(models.SleepRecord.sleep_start.desc())
        .limit(limit)
        .all()
    )


def get_sleep_stats(
    db: Session,
    user_id: int,
    period: str = "week",
) -> dict:
    """Return aggregated stats for the given period (week=7 days, month=30 days)."""
    from datetime import timedelta
    days = {"week": 7, "month": 30}.get(period, 7)
    since = utc_now_naive() - timedelta(days=days)

    records = (
        db.query(models.SleepRecord)
        .filter(
            models.SleepRecord.user_id == user_id,
            models.SleepRecord.sleep_start >= since,
            models.SleepRecord.total_hours.isnot(None),
        )
        .order_by(models.SleepRecord.sleep_start.asc())
        .all()
    )

    if not records:
        return {
            "period": period,
            "avg_hours": 0.0,
            "score_avg": None,
            "trend": "stable",
            "num_records": 0,
        }

    hours_list = [r.total_hours for r in records]
    scores = [r.sleep_score for r in records if r.sleep_score is not None]

    avg_hours = round(sum(hours_list) / len(hours_list), 2)
    score_avg = round(sum(scores) / len(scores), 1) if scores else None

    # Simple trend: compare first half vs second half average hours
    mid = len(hours_list) // 2
    if mid > 0:
        first_avg = sum(hours_list[:mid]) / mid
        second_avg = sum(hours_list[mid:]) / (len(hours_list) - mid)
        diff = second_avg - first_avg
        trend = "improving" if diff > 0.3 else ("declining" if diff < -0.3 else "stable")
    else:
        trend = "stable"

    return {
        "period": period,
        "avg_hours": avg_hours,
        "score_avg": score_avg,
        "trend": trend,
        "num_records": len(records),
    }


def get_due_flashcard_subjects(
    db: Session,
    user_id: int,
    target_date: date,
) -> list[dict]:
    """Group due flashcards by document and rank the most urgent decks first."""
    end_of_day = datetime.combine(target_date, time(23, 59, 59))
    cards = (
        db.query(models.Flashcard)
        .join(models.ChatDocument, models.ChatDocument.id == models.Flashcard.document_id)
        .filter(
            models.Flashcard.user_id == user_id,
            models.Flashcard.next_review <= end_of_day,
        )
        .order_by(models.Flashcard.next_review.asc())
        .all()
    )

    grouped: dict[int, dict] = {}
    for card in cards:
        document = card.document
        if document is None:
            continue

        days_overdue = max((end_of_day - card.next_review).total_seconds() / 86400, 0.0)
        difficulty_penalty = max(2.5 - card.ease_factor, 0.0)
        urgency = 1.0 + (days_overdue * 0.25) + difficulty_penalty

        entry = grouped.setdefault(
            document.id,
            {
                "document_id": document.id,
                "document_name": document.filename,
                "due_count": 0,
                "avg_ease_factor": 0.0,
                "priority_score": 0.0,
            },
        )
        entry["due_count"] += 1
        entry["avg_ease_factor"] += card.ease_factor
        entry["priority_score"] += urgency

    results = []
    for entry in grouped.values():
        entry["avg_ease_factor"] = round(entry["avg_ease_factor"] / entry["due_count"], 2)
        entry["priority_score"] = round(entry["priority_score"], 2)
        results.append(entry)

    results.sort(
        key=lambda item: (
            -item["priority_score"],
            -item["due_count"],
            item["document_name"].lower(),
        )
    )
    return results


def get_recent_quiz_performance(
    db: Session,
    user_id: int,
    *,
    target_date: date | None = None,
    lookback_days: int = 7,
) -> list[dict]:
    """Return recent quiz weakness signals grouped by document."""
    end_of_window = datetime.combine(target_date or date.today(), time(23, 59, 59))
    start_of_window = end_of_window - timedelta(days=lookback_days)

    quizzes = (
        db.query(models.Quiz)
        .join(models.ChatDocument, models.ChatDocument.id == models.Quiz.document_id)
        .filter(
            models.Quiz.user_id == user_id,
            models.Quiz.completed_at.isnot(None),
            models.Quiz.completed_at >= start_of_window,
            models.Quiz.completed_at <= end_of_window,
            models.Quiz.num_questions > 0,
        )
        .order_by(models.Quiz.completed_at.desc())
        .all()
    )

    grouped: dict[int, dict] = {}
    for quiz in quizzes:
        document = quiz.document
        if document is None or quiz.score is None or quiz.num_questions <= 0:
            continue

        weakness = max(0.0, 1.0 - (quiz.score / quiz.num_questions))
        entry = grouped.setdefault(
            document.id,
            {
                "document_id": document.id,
                "document_name": document.filename,
                "weakness_score_total": 0.0,
                "attempt_count": 0,
            },
        )
        entry["weakness_score_total"] += weakness
        entry["attempt_count"] += 1

    results = []
    for entry in grouped.values():
        weakness_score = entry["weakness_score_total"] / entry["attempt_count"]
        results.append(
            {
                "document_id": entry["document_id"],
                "document_name": entry["document_name"],
                "attempt_count": entry["attempt_count"],
                "weakness_score": round(weakness_score, 3),
            }
        )

    results.sort(
        key=lambda item: (
            -item["weakness_score"],
            -item["attempt_count"],
            item["document_name"].lower(),
        )
    )
    return results


def get_upcoming_exams(
    db: Session,
    user_id: int,
    *,
    on_or_after: date | None = None,
    exam_ids: list[int] | None = None,
) -> list[models.Exam]:
    """Return upcoming exams ordered by closest deadline first."""
    query = db.query(models.Exam).filter(models.Exam.user_id == user_id)

    if on_or_after is not None:
        query = query.filter(models.Exam.exam_date >= on_or_after)

    if exam_ids is not None:
        if not exam_ids:
            return []
        query = query.filter(models.Exam.id.in_(exam_ids))

    return (
        query.order_by(models.Exam.exam_date.asc(), models.Exam.title.asc())
        .all()
    )


def get_exam(db: Session, user_id: int, exam_id: int) -> Optional[models.Exam]:
    """Return a single exam if it belongs to the user."""
    return (
        db.query(models.Exam)
        .filter(models.Exam.user_id == user_id, models.Exam.id == exam_id)
        .first()
    )


def create_exam(
    db: Session,
    user_id: int,
    data: "schemas.ExamCreate",
) -> models.Exam:
    """Create a saved exam target for planning."""
    exam = models.Exam(
        user_id=user_id,
        title=data.title.strip(),
        exam_date=data.exam_date,
        document_id=data.document_id,
    )
    db.add(exam)
    db.commit()
    db.refresh(exam)
    return exam


def delete_exam(db: Session, exam: models.Exam) -> None:
    """Delete a saved exam."""
    db.delete(exam)
    db.commit()


# ══════════════════════════════════════════════
# SMART ALARM
# ══════════════════════════════════════════════

def get_alarm_config(db: Session, user_id: int) -> Optional[models.SmartAlarm]:
    return db.query(models.SmartAlarm).filter(models.SmartAlarm.user_id == user_id).first()


def upsert_alarm_config(
    db: Session,
    user_id: int,
    data: "schemas.AlarmConfigUpdate",
) -> models.SmartAlarm:
    """Create or fully replace the alarm configuration for a user."""
    alarm = get_alarm_config(db, user_id)
    if alarm is None:
        alarm = models.SmartAlarm(user_id=user_id)
        db.add(alarm)

    for field, value in data.model_dump().items():
        setattr(alarm, field, value)

    db.commit()
    db.refresh(alarm)
    return alarm


# ══════════════════════════════════════════════
# PLANNING SESSIONS
# ══════════════════════════════════════════════

def get_study_sessions_by_date(
    db: Session,
    user_id: int,
    day: date,
) -> List[models.StudySession]:
    """Return all sessions for a given user and day."""
    return (
        db.query(models.StudySession)
        .filter(models.StudySession.user_id == user_id, models.StudySession.date == day)
        .order_by(models.StudySession.start.asc())
        .all()
    )


def get_study_sessions_in_range(
    db: Session,
    user_id: int,
    start_day: date,
    end_day: date,
) -> List[models.StudySession]:
    """Return all sessions for a user between two inclusive dates."""
    return (
        db.query(models.StudySession)
        .filter(
            models.StudySession.user_id == user_id,
            models.StudySession.date >= start_day,
            models.StudySession.date <= end_day,
        )
        .order_by(models.StudySession.start.asc())
        .all()
    )


def get_sleep_records_in_range(
    db: Session,
    user_id: int,
    start_day: date,
    end_day: date,
) -> List[models.SleepRecord]:
    """Return sleep records overlapping the given inclusive date range."""
    range_start = datetime.combine(start_day, time.min)
    range_end = datetime.combine(end_day, time.max)
    return (
        db.query(models.SleepRecord)
        .filter(
            models.SleepRecord.user_id == user_id,
            models.SleepRecord.sleep_start >= range_start,
            models.SleepRecord.sleep_start <= range_end,
        )
        .order_by(models.SleepRecord.sleep_start.asc())
        .all()
    )


def get_completion_rate_by_hour(
    db: Session,
    user_id: int,
    *,
    target_date: date | None = None,
    lookback_days: int = 14,
) -> dict[int, dict[str, float | int]]:
    """Return per-start-hour completion stats for past sessions."""
    anchor_day = target_date or date.today()
    end_day = anchor_day - timedelta(days=1)
    start_day = end_day - timedelta(days=lookback_days - 1)
    if end_day < start_day:
        return {}

    sessions = get_study_sessions_in_range(db, user_id, start_day, end_day)
    grouped: dict[int, dict[str, float | int]] = {}

    for session_obj in sessions:
        hour = session_obj.start.hour
        entry = grouped.setdefault(hour, {"completed": 0, "total": 0, "completion_rate": 0.0})
        entry["total"] = int(entry["total"]) + 1
        if session_obj.status == "completed":
            entry["completed"] = int(entry["completed"]) + 1

    for hour, entry in grouped.items():
        total = int(entry["total"])
        completed = int(entry["completed"])
        entry["completion_rate"] = round(completed / total, 3) if total > 0 else 0.0
        grouped[hour] = entry

    return grouped


def delete_study_sessions_by_date(db: Session, user_id: int, day: date, only_ai: bool = False) -> int:
    """Delete all (or only AI) sessions for a user/day. Returns the deleted count."""
    sessions = get_study_sessions_by_date(db, user_id, day)
    deleted = 0
    for s in sessions:
        if only_ai and not s.is_ai_generated:
            continue
        db.delete(s)
        deleted += 1
    if deleted > 0:
        db.commit()
    return deleted


def create_study_session(
    db: Session,
    user_id: int,
    data: "schemas.StudySessionCreate",
    *,
    is_ai_generated: bool = False,
) -> models.StudySession:
    """Create a single study session."""
    if data.end <= data.start:
        raise ValueError("end must be after start")
    session_day = data.start.date()
    if data.end.date() != session_day:
        raise ValueError("end must be on the same day as start")
    resolved_document_ids = _resolve_document_ids(data.document_id, data.document_ids)

    session = models.StudySession(
        user_id=user_id,
        date=session_day,
        start=data.start,
        end=data.end,
        subject=data.subject,
        priority=data.priority,
        status="pending",
        notes=None,
        is_ai_generated=is_ai_generated,
        completed_at=None,
        document_id=resolved_document_ids[0] if resolved_document_ids else None,
    )
    db.add(session)
    _sync_session_document_links(session, resolved_document_ids)
    db.commit()
    db.refresh(session)
    return session


def update_study_session(
    db: Session,
    session_obj: models.StudySession,
    updates: "schemas.StudySessionUpdate",
) -> models.StudySession:
    """Apply partial updates (status/notes)."""
    payload = updates.model_dump(exclude_unset=True)
    if "status" in payload:
        new_status = payload["status"]
        session_obj.status = new_status
        if new_status == "completed":
            session_obj.completed_at = utc_now_naive()
        else:
            session_obj.completed_at = None

    if "notes" in payload:
        session_obj.notes = payload["notes"]

    if "document_id" in payload or "document_ids" in payload:
        resolved_document_ids = _resolve_document_ids(
            payload.get("document_id"),
            payload.get("document_ids"),
        )
        session_obj.document_id = resolved_document_ids[0] if resolved_document_ids else None
        _sync_session_document_links(session_obj, resolved_document_ids)

    db.commit()
    db.refresh(session_obj)
    return session_obj


def complete_study_session(db: Session, session_obj: models.StudySession) -> models.StudySession:
    """Mark a session as completed."""
    session_obj.status = "completed"
    session_obj.completed_at = utc_now_naive()
    db.commit()
    db.refresh(session_obj)
    return session_obj


def delete_study_session(db: Session, session_obj: models.StudySession) -> None:
    """Delete a single study session."""
    db.delete(session_obj)
    db.commit()


# ============================================================================
# VISION / MONITORING
# ============================================================================

def _parse_iso_timestamp(value: str | None) -> datetime:
    """Parse ISO timestamps sent by the CV client, falling back to UTC now."""
    if not value:
        return utc_now_naive()

    normalized = value.strip().replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return utc_now_naive()

    if parsed.tzinfo is None:
        return parsed
    return parsed.astimezone(timezone.utc).replace(tzinfo=None)


def create_work_session(
    db: Session,
    session_id: str,
    user_id: int | None = None,
    metadata_json: dict | None = None,
) -> models.WorkSession:
    """Create (or return existing) CV work session."""
    existing = get_work_session(db, session_id)
    if existing:
        return existing

    session_obj = models.WorkSession(
        id=session_id,
        user_id=user_id,
        metadata_json=metadata_json,
    )
    db.add(session_obj)
    db.commit()
    db.refresh(session_obj)
    return session_obj


def get_work_session(db: Session, session_id: str) -> models.WorkSession | None:
    """Lookup a CV work session by UUID."""
    return (
        db.query(models.WorkSession)
        .filter(models.WorkSession.id == session_id)
        .first()
    )


def finalize_work_session(
    db: Session,
    session_id: str,
    summary_data: dict,
) -> models.WorkSession | None:
    """Mark a CV session as completed and persist final summary payload.

    Also computes the average ``global_focus_score`` from all snapshots and
    writes it to the linked ``StudySession`` (if ``planning_session_id`` is
    present in the work session's metadata).
    """
    from sqlalchemy import func

    session_obj = get_work_session(db, session_id)
    if not session_obj:
        return None

    metadata = dict(session_obj.metadata_json or {})
    metadata["final_summary"] = summary_data
    session_obj.metadata_json = metadata
    session_obj.is_active = False
    session_obj.end_time = utc_now_naive()

    # ── Compute avg focus score from snapshots ────────────────────────────
    avg_focus_row = (
        db.query(func.avg(models.Snapshot.global_focus_score))
        .filter(
            models.Snapshot.session_id == session_id,
            models.Snapshot.global_focus_score.isnot(None),
        )
        .scalar()
    )
    avg_focus_score: float | None = (
        round(float(avg_focus_row), 2) if avg_focus_row is not None else None
    )

    # Persist avg score into the final_summary for convenience
    if avg_focus_score is not None:
        metadata["final_summary"]["avg_focus_score"] = avg_focus_score
        session_obj.metadata_json = metadata

    # ── Write focus score to the linked StudySession if present ───────────
    planning_session_id = metadata.get("planning_session_id")
    if planning_session_id is not None and avg_focus_score is not None:
        try:
            planning_id = int(planning_session_id)
            study_session = (
                db.query(models.StudySession)
                .filter(models.StudySession.id == planning_id)
                .first()
            )
            if study_session is not None:
                study_session.focus_score = avg_focus_score
        except (ValueError, TypeError):
            pass  # Non-integer planning_session_id — skip silently

    db.commit()
    db.refresh(session_obj)
    return session_obj


def create_snapshot(
    db: Session,
    payload: schemas.SnapshotCreate,
    *,
    user_id: int | None = None,
) -> models.Snapshot:
    """Insert a CV snapshot for an existing active work session."""
    session_obj = get_work_session(db, payload.session_id)
    if session_obj is None:
        raise ValueError(
            f"Work session '{payload.session_id}' does not exist. "
            "Start the session before sending snapshots."
        )
    if not session_obj.is_active:
        raise ValueError(
            f"Work session '{payload.session_id}' is not active. "
            "Start a new session before sending snapshots."
        )

    scores = payload.scores or {}
    snapshot = models.Snapshot(
        session_id=session_obj.id,
        timestamp=_parse_iso_timestamp(payload.timestamp),
        work_mode=payload.work_mode,
        attention_score=scores.get("attention_score"),
        posture_score=scores.get("posture_score"),
        vigilance_score=scores.get("vigilance_score"),
        stress_risk_score=scores.get("stress_risk_score"),
        global_focus_score=scores.get("focus_score_global", scores.get("global_focus_score")),
        raw_payload_json=payload.model_dump(),
    )
    db.add(snapshot)
    db.commit()
    db.refresh(snapshot)
    return snapshot


def create_focus_event(
    db: Session,
    payload: schemas.EventCreate,
    *,
    user_id: int | None = None,
) -> models.FocusEvent:
    """Insert a CV event for an existing active work session."""
    session_obj = get_work_session(db, payload.session_id)
    if session_obj is None:
        raise ValueError(
            f"Work session '{payload.session_id}' does not exist. "
            "Start the session before sending events."
        )
    if not session_obj.is_active:
        raise ValueError(
            f"Work session '{payload.session_id}' is not active. "
            "Start a new session before sending events."
        )

    focus_event = models.FocusEvent(
        session_id=session_obj.id,
        timestamp=_parse_iso_timestamp(payload.timestamp),
        event_type=payload.event_type,
        level=payload.level,
        description=payload.description,
        raw_payload_json=payload.metadata,
    )
    db.add(focus_event)
    db.commit()
    db.refresh(focus_event)
    return focus_event


def get_latest_snapshot(db: Session, session_id: str) -> models.Snapshot | None:
    """Return the latest snapshot by timestamp for the given session."""
    return (
        db.query(models.Snapshot)
        .filter(models.Snapshot.session_id == session_id)
        .order_by(models.Snapshot.timestamp.desc())
        .first()
    )


_STALE_WORK_SESSION_AFTER = timedelta(minutes=2)


def _close_stale_work_sessions(
    db: Session,
    sessions: list[models.WorkSession],
) -> None:
    """Auto-close active CV sessions that have gone silent.

    The pi_client currently cannot always finalize with auth, so stale
    ``is_active=True`` rows can accumulate and confuse the mobile app into
    treating old sessions as still running. We consider a session stale when
    its latest snapshot (or its start_time if it never produced one) is older
    than ``_STALE_WORK_SESSION_AFTER``.
    """
    from sqlalchemy import func

    active_sessions = [session for session in sessions if session.is_active]
    if not active_sessions:
        return

    active_ids = [session.id for session in active_sessions]
    latest_rows = (
        db.query(
            models.Snapshot.session_id,
            func.max(models.Snapshot.timestamp),
        )
        .filter(models.Snapshot.session_id.in_(active_ids))
        .group_by(models.Snapshot.session_id)
        .all()
    )
    latest_by_session_id = {
        session_id: timestamp for session_id, timestamp in latest_rows
    }

    cutoff = utc_now_naive() - _STALE_WORK_SESSION_AFTER
    did_change = False

    for session in active_sessions:
        last_activity = latest_by_session_id.get(session.id) or session.start_time
        if last_activity >= cutoff:
            continue
        session.is_active = False
        session.end_time = session.end_time or last_activity
        did_change = True

    if did_change:
        db.commit()


def list_work_sessions(
    db: Session,
    user_id: int,
    skip: int = 0,
    limit: int = 100,
) -> list[models.WorkSession]:
    """List persisted CV work sessions for a specific user.

    Also includes sessions with ``user_id = NULL`` which are created by
    the pi_client (unauthenticated ingestion).
    """
    from sqlalchemy import or_

    sessions = (
        db.query(models.WorkSession)
        .filter(
            or_(
                models.WorkSession.user_id == user_id,
                models.WorkSession.user_id.is_(None),
            )
        )
        .order_by(models.WorkSession.start_time.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    _close_stale_work_sessions(db, sessions)
    return sessions


def get_recent_focus_stats(
    db: Session,
    user_id: int,
    target_date: date,
) -> dict | None:
    """Return focus statistics from the most recent finalized CV work session.

    Queries the latest completed WorkSession (is_active=False) for the user
    — including pi_client sessions with user_id=NULL — and computes the
    average global_focus_score across all its Snapshot rows.

    Returns a dict with ``avg_focus_score``, ``focus_time_ratio``,
    ``distraction_time_ratio``, and ``snapshot_count``, or *None* when
    no finalized session with scored snapshots exists.
    """
    from sqlalchemy import or_, func

    end_of_day = datetime.combine(target_date, time(23, 59, 59))

    recent_session: models.WorkSession | None = (
        db.query(models.WorkSession)
        .filter(
            or_(
                models.WorkSession.user_id == user_id,
                models.WorkSession.user_id.is_(None),
            ),
            models.WorkSession.is_active == False,  # noqa: E712
            models.WorkSession.end_time <= end_of_day,
        )
        .order_by(models.WorkSession.end_time.desc())
        .first()
    )

    if recent_session is None:
        return None

    # Compute average global_focus_score from snapshots
    row = (
        db.query(
            func.avg(models.Snapshot.global_focus_score),
            func.count(models.Snapshot.id),
        )
        .filter(
            models.Snapshot.session_id == recent_session.id,
            models.Snapshot.global_focus_score.isnot(None),
        )
        .one()
    )

    avg_focus: float | None = row[0]
    snapshot_count: int = row[1]

    if avg_focus is None or snapshot_count == 0:
        return None

    # Extract final_summary fields from metadata if available
    metadata = recent_session.metadata_json or {}
    final_summary = metadata.get("final_summary", {})

    return {
        "avg_focus_score": round(float(avg_focus), 3),
        "focus_time_ratio": final_summary.get("focus_time_ratio"),
        "distraction_time_ratio": final_summary.get("distraction_time_ratio"),
        "snapshot_count": snapshot_count,
    }


def _normalize_focus_percent(value) -> float | None:
    if value is None:
        return None
    try:
        normalized = float(value)
    except (TypeError, ValueError):
        return None

    if normalized <= 1.0:
        normalized *= 100.0
    if normalized < 0:
        return 0.0
    if normalized > 100:
        return 100.0
    return normalized


def get_daily_focus_stats(
    db: Session,
    user_id: int,
    target_date: date,
) -> dict | None:
    """Return day-level focus score, aligned with dashboard global score logic.

    For each work session started on ``target_date``:
    - prefer ``final_summary.final_score`` if present
    - else fallback to latest snapshot ``global_focus_score``
    - else fallback to ``final_summary.focus_time_ratio``

    Then returns the average across scored sessions.
    """
    from sqlalchemy import or_

    day_start = datetime.combine(target_date, time(0, 0, 0))
    next_day_start = day_start + timedelta(days=1)

    sessions: list[models.WorkSession] = (
        db.query(models.WorkSession)
        .filter(
            or_(
                models.WorkSession.user_id == user_id,
                models.WorkSession.user_id.is_(None),
            ),
            models.WorkSession.start_time >= day_start,
            models.WorkSession.start_time < next_day_start,
        )
        .order_by(models.WorkSession.start_time.asc())
        .all()
    )

    if not sessions:
        return None

    score_values: list[float] = []

    for session_obj in sessions:
        metadata = session_obj.metadata_json or {}
        summary = metadata.get("final_summary")
        if not isinstance(summary, dict):
            summary = {}

        final_score = _normalize_focus_percent(summary.get("final_score"))
        if final_score is not None:
            score_values.append(final_score)
            continue

        latest_snapshot = get_latest_snapshot(db, session_obj.id)
        snapshot_score = _normalize_focus_percent(
            latest_snapshot.global_focus_score if latest_snapshot is not None else None
        )
        if snapshot_score is not None:
            score_values.append(snapshot_score)
            continue

        summary_focus = _normalize_focus_percent(summary.get("focus_time_ratio"))
        if summary_focus is not None:
            score_values.append(summary_focus)

    if not score_values:
        return None

    avg_focus_score = sum(score_values) / len(score_values)
    return {
        "avg_focus_score": round(avg_focus_score, 3),
        "session_count": len(sessions),
        "scored_session_count": len(score_values),
    }
