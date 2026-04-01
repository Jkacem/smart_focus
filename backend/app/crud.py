# backend/crud.py
"""
CRUD helpers for SQLAlchemy models.
"""

from datetime import datetime, date
from typing import Optional, List

from sqlalchemy.orm import Session

from . import models, schemas
from .utils.security import hash_password


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
    user.last_login = datetime.utcnow()
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
    since = datetime.utcnow() - timedelta(days=days)

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
    )
    db.add(session)
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
            session_obj.completed_at = datetime.utcnow()
        else:
            session_obj.completed_at = None

    if "notes" in payload:
        session_obj.notes = payload["notes"]

    db.commit()
    db.refresh(session_obj)
    return session_obj


def complete_study_session(db: Session, session_obj: models.StudySession) -> models.StudySession:
    """Mark a session as completed."""
    session_obj.status = "completed"
    session_obj.completed_at = datetime.utcnow()
    db.commit()
    db.refresh(session_obj)
    return session_obj


def delete_study_session(db: Session, session_obj: models.StudySession) -> None:
    """Delete a single study session."""
    db.delete(session_obj)
    db.commit()
