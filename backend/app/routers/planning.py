"""
Planning Router - intelligent planning endpoints.
"""

import logging
import math
from datetime import date, datetime, time, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Path, Response, status
from sqlalchemy.orm import Session

from app import crud, schemas
from app.deps import get_current_user, get_db
from app.models.models import ChatDocument, Exam, SleepRecord, StudySession, User
from app.services.planning_service import generate_daily_schedule
from app.services.schedule_parser import is_csv_schedule, parse_csv_schedule

logger = logging.getLogger(__name__)

# Day boundaries for revision slots
_DAY_START_HOUR = 8
_DAY_END_HOUR = 22
_BUFFER_MINUTES = 15

router = APIRouter(prefix="/api/v1/planning", tags=["Planning"])


def _to_day_response(day: date, sessions: list[StudySession]) -> schemas.PlanningDayOut:
    sessions_out = [schemas.StudySessionOut.model_validate(s) for s in sessions]
    return schemas.PlanningDayOut(
        planning=schemas.PlanningOut(date=day),
        sessions=sessions_out,
    )


def _resolve_period_window(
    period: schemas.PlanningInsightsPeriod,
    anchor_day: date,
) -> tuple[date, date, int]:
    lookback_days = 7 if period == "week" else 30
    start_day = anchor_day - timedelta(days=lookback_days - 1)
    return start_day, anchor_day, lookback_days


def _session_topic_label(session_obj: StudySession) -> str:
    if session_obj.document_name:
        return session_obj.document_name

    prefixes = (
        "revision flashcards:",
        "revision quiz:",
        "revision:",
    )
    normalized = session_obj.subject.strip()
    lowered = normalized.lower()
    for prefix in prefixes:
        if lowered.startswith(prefix):
            return normalized[len(prefix):].strip() or normalized
    return normalized


def _compute_sleep_study_correlation(
    sessions: list[StudySession],
    sleep_records: list[SleepRecord],
) -> str:
    if not sessions or not sleep_records:
        return "insufficient_data"

    completed_minutes_by_day: dict[date, int] = {}
    for session_obj in sessions:
        if session_obj.status != "completed":
            continue
        completed_minutes_by_day.setdefault(session_obj.date, 0)
        completed_minutes_by_day[session_obj.date] += int(
            (session_obj.end - session_obj.start).total_seconds() // 60
        )

    pairs: list[tuple[int, int]] = []
    for record in sleep_records:
        if record.sleep_score is None:
            continue
        study_day = (record.sleep_start + timedelta(days=1)).date()
        if study_day in completed_minutes_by_day:
            pairs.append((record.sleep_score, completed_minutes_by_day[study_day]))

    if len(pairs) < 2:
        return "insufficient_data"

    avg_score = sum(score for score, _ in pairs) / len(pairs)
    avg_minutes = sum(minutes for _, minutes in pairs) / len(pairs)
    covariance = sum(
        (score - avg_score) * (minutes - avg_minutes)
        for score, minutes in pairs
    )
    if covariance > 50:
        return "positive"
    if covariance < -50:
        return "negative"
    return "neutral"


def _build_recommendation(
    *,
    sessions: list[StudySession],
    avg_sleep_score: float | None,
    weakest_subject: str | None,
) -> str:
    ended_sessions = [
        session_obj
        for session_obj in sessions
        if session_obj.status in {"completed", "cancelled"} or session_obj.end <= datetime.utcnow()
    ]
    if ended_sessions:
        buckets = {
            "morning": {"label": "le matin", "completed": 0, "total": 0},
            "afternoon": {"label": "l'apres-midi", "completed": 0, "total": 0},
            "evening": {"label": "apres 19h", "completed": 0, "total": 0},
        }
        for session_obj in ended_sessions:
            bucket_key = (
                "morning"
                if session_obj.start.hour < 12
                else "afternoon"
                if session_obj.start.hour < 19
                else "evening"
            )
            buckets[bucket_key]["total"] += 1
            if session_obj.status == "completed":
                buckets[bucket_key]["completed"] += 1

        rates = {
            key: (bucket["completed"] / bucket["total"])
            for key, bucket in buckets.items()
            if bucket["total"] > 0
        }
        if len(rates) >= 2:
            best_key = max(rates, key=rates.get)
            worst_key = min(rates, key=rates.get)
            if rates[best_key] - rates[worst_key] >= 0.2:
                return (
                    f"Votre taux de completion est plus fort {buckets[best_key]['label']}. "
                    f"Essayez de reduire les sessions {buckets[worst_key]['label']}."
                )

    if avg_sleep_score is not None and avg_sleep_score < 60:
        return (
            "Votre score de sommeil est bas sur cette periode. "
            "Essayez de privilegier des sessions plus courtes et plus tot dans la journee."
        )

    if weakest_subject:
        return (
            f"{weakest_subject} ressort comme votre sujet le plus fragile. "
            "Ajoutez une courte revision ciblee avant votre prochaine session."
        )

    return (
        "Votre rythme est globalement stable. Continuez a valider vos sessions "
        "pour affiner les prochaines recommandations."
    )


def _build_planning_insights(
    db: Session,
    current_user: User,
    *,
    period: schemas.PlanningInsightsPeriod,
    anchor_day: date | None = None,
) -> schemas.PlanningInsightsOut:
    reference_day = anchor_day or date.today()
    start_day, end_day, lookback_days = _resolve_period_window(period, reference_day)
    sessions = crud.get_study_sessions_in_range(db, current_user.id, start_day, end_day)
    sleep_records = crud.get_sleep_records_in_range(db, current_user.id, start_day, end_day)
    quiz_performance = crud.get_recent_quiz_performance(
        db,
        current_user.id,
        target_date=end_day,
        lookback_days=lookback_days,
    )

    total_study_minutes = sum(
        int((session_obj.end - session_obj.start).total_seconds() // 60)
        for session_obj in sessions
        if session_obj.status != "cancelled"
    )
    completed_sessions = sum(1 for session_obj in sessions if session_obj.status == "completed")
    skipped_sessions = sum(
        1
        for session_obj in sessions
        if session_obj.status == "cancelled"
        or (
            session_obj.status in {"pending", "in_progress"}
            and session_obj.end <= datetime.utcnow()
        )
    )
    measured_sessions = completed_sessions + skipped_sessions
    completion_rate = round(
        completed_sessions / measured_sessions,
        2,
    ) if measured_sessions > 0 else 0.0

    scored_sleep = [record.sleep_score for record in sleep_records if record.sleep_score is not None]
    avg_sleep_score = round(sum(scored_sleep) / len(scored_sleep), 1) if scored_sleep else None
    sleep_study_correlation = _compute_sleep_study_correlation(sessions, sleep_records)

    weakest_subject = quiz_performance[0]["document_name"] if quiz_performance else None
    strongest_subject = quiz_performance[-1]["document_name"] if quiz_performance else None

    if not quiz_performance and sessions:
        completed_minutes_by_topic: dict[str, int] = {}
        for session_obj in sessions:
            if session_obj.status != "completed":
                continue
            topic = _session_topic_label(session_obj)
            completed_minutes_by_topic.setdefault(topic, 0)
            completed_minutes_by_topic[topic] += int(
                (session_obj.end - session_obj.start).total_seconds() // 60
            )
        if completed_minutes_by_topic:
            strongest_subject = max(completed_minutes_by_topic, key=completed_minutes_by_topic.get)

    recommendation = _build_recommendation(
        sessions=sessions,
        avg_sleep_score=avg_sleep_score,
        weakest_subject=weakest_subject,
    )

    return schemas.PlanningInsightsOut(
        period=period,
        total_study_minutes=total_study_minutes,
        completed_sessions=completed_sessions,
        skipped_sessions=skipped_sessions,
        completion_rate=completion_rate,
        avg_sleep_score=avg_sleep_score,
        sleep_study_correlation=sleep_study_correlation,
        weakest_subject=weakest_subject,
        strongest_subject=strongest_subject,
        recommendation=recommendation,
    )


def _week_days(anchor_day: date) -> list[date]:
    start_of_week = anchor_day - timedelta(days=anchor_day.weekday())
    return [start_of_week + timedelta(days=offset) for offset in range(7)]


def _load_planning_document(
    db: Session,
    current_user: User,
    document_id: int | None,
) -> tuple[str | None, str | None]:
    doc = _get_owned_document(db, current_user, document_id)
    if doc is None:
        return None, None

    return doc.chroma_collection, doc.file_path


def _get_owned_document(
    db: Session,
    current_user: User,
    document_id: int | None,
) -> ChatDocument | None:
    if document_id is None:
        return None

    doc = (
        db.query(ChatDocument)
        .filter(ChatDocument.id == document_id, ChatDocument.user_id == current_user.id)
        .first()
    )
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")

    return doc


def _get_owned_documents(
    db: Session,
    current_user: User,
    document_ids: list[int] | None,
) -> list[ChatDocument]:
    if not document_ids:
        return []

    docs = (
        db.query(ChatDocument)
        .filter(
            ChatDocument.id.in_(document_ids),
            ChatDocument.user_id == current_user.id,
        )
        .all()
    )
    docs_by_id = {doc.id: doc for doc in docs}
    ordered_docs = [docs_by_id[document_id] for document_id in document_ids if document_id in docs_by_id]
    if len(ordered_docs) != len(document_ids):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")
    return ordered_docs


def _get_owned_exam(db: Session, current_user: User, exam_id: int) -> Exam:
    exam = crud.get_exam(db, current_user.id, exam_id)
    if not exam:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exam not found.")
    return exam


def _get_selected_exams(
    db: Session,
    current_user: User,
    target_day: date,
    exam_ids: list[int] | None,
) -> list[Exam]:
    return crud.get_upcoming_exams(
        db,
        current_user.id,
        on_or_after=target_day,
        exam_ids=exam_ids,
    )


def _get_owned_session(db: Session, current_user: User, session_id: int) -> StudySession:
    session_obj = (
        db.query(StudySession)
        .filter(StudySession.id == session_id, StudySession.user_id == current_user.id)
        .first()
    )
    if not session_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    return session_obj


def _get_sleep_profile(
    db: Session,
    user_id: int,
    target_day: date,
) -> dict[str, Any]:
    """Return revision parameters calibrated on the user's latest sleep score."""
    record: SleepRecord | None = crud.get_latest_sleep_record(db, user_id, target_day)
    score: int | None = record.sleep_score if record else None

    if score is not None and score >= 80:
        profile = {
            "max_session_min": 50,
            "break_min": 10,
            "max_sessions": 6,
            "priority": "high",
            "label": "Bien repose",
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
        profile = {
            "max_session_min": 35,
            "break_min": 15,
            "max_sessions": 4,
            "priority": "medium",
            "label": "Sommeil moyen" if score is not None else "Pas de donnees sommeil",
        }

    logger.info(
        "Sleep profile for user %d on %s: score=%s -> %s (max %d min x %d sessions)",
        user_id,
        target_day.isoformat(),
        score,
        profile["label"],
        profile["max_session_min"],
        profile["max_sessions"],
    )
    return profile


def _compute_free_slots(
    target_day: date,
    class_sessions: list[dict[str, Any]],
) -> list[tuple[datetime, datetime]]:
    day_start = datetime.combine(target_day, time(_DAY_START_HOUR, 0))
    day_end = datetime.combine(target_day, time(_DAY_END_HOUR, 0))
    buffer = timedelta(minutes=_BUFFER_MINUTES)

    if not class_sessions:
        return [(day_start, day_end)]

    sorted_classes = sorted(class_sessions, key=lambda s: s["start"])
    free_slots: list[tuple[datetime, datetime]] = []

    first_start = sorted_classes[0]["start"]
    slot_end = first_start - buffer
    if slot_end > day_start:
        free_slots.append((day_start, slot_end))

    for i in range(len(sorted_classes) - 1):
        gap_start = sorted_classes[i]["end"] + buffer
        gap_end = sorted_classes[i + 1]["start"] - buffer
        if gap_end > gap_start:
            free_slots.append((gap_start, gap_end))

    last_end = sorted_classes[-1]["end"]
    slot_start = last_end + buffer
    if slot_start < day_end:
        free_slots.append((slot_start, day_end))

    return free_slots


def _preferred_schedule_hours(preferred_schedule: str | None) -> set[int]:
    schedule = (preferred_schedule or "morning").strip().lower()
    if schedule in {"afternoon", "noon"}:
        return set(range(12, 18))
    if schedule in {"night", "evening", "late"}:
        return set(range(18, 22))
    return set(range(8, 12))


def _resolve_allowed_revision_hours(
    completion_rate_by_hour: dict[int, dict[str, float | int]] | None,
    preferred_schedule: str | None,
) -> set[int]:
    stats = completion_rate_by_hour or {}
    golden_hours = {
        hour
        for hour, entry in stats.items()
        if float(entry.get("completion_rate", 0.0)) > 0.5
    }
    if golden_hours:
        return golden_hours
    return _preferred_schedule_hours(preferred_schedule)


def _filter_free_slots_by_allowed_hours(
    target_day: date,
    free_slots: list[tuple[datetime, datetime]],
    allowed_hours: set[int],
) -> list[tuple[datetime, datetime]]:
    if not free_slots or not allowed_hours:
        return free_slots

    segments: list[tuple[datetime, datetime]] = []
    for slot_start, slot_end in free_slots:
        for hour in sorted(allowed_hours):
            hour_start = datetime.combine(target_day, time(hour, 0))
            hour_end = datetime.combine(target_day, time(hour + 1, 0))
            segment_start = max(slot_start, hour_start)
            segment_end = min(slot_end, hour_end)
            if segment_end > segment_start:
                segments.append((segment_start, segment_end))

    if not segments:
        return []

    merged: list[tuple[datetime, datetime]] = [segments[0]]
    for segment_start, segment_end in segments[1:]:
        last_start, last_end = merged[-1]
        if segment_start <= last_end:
            merged[-1] = (last_start, max(last_end, segment_end))
        else:
            merged.append((segment_start, segment_end))
    return merged


def _align_to_slot_boundary(value: datetime, *, minutes: int = 5) -> datetime:
    aligned = value.replace(second=0, microsecond=0)
    remainder = aligned.minute % minutes
    if remainder == 0:
        return aligned
    return aligned + timedelta(minutes=minutes - remainder)


def _find_next_reschedule_slot(
    db: Session,
    user_id: int,
    *,
    duration: timedelta,
    reference_time: datetime,
    skip_session_id: int | None = None,
    max_days: int = 2,
) -> tuple[datetime, datetime]:
    search_start = _align_to_slot_boundary(reference_time)
    for day_offset in range(max_days):
        target_day = search_start.date() + timedelta(days=day_offset)
        day_sessions = crud.get_study_sessions_by_date(db, user_id, target_day)
        occupied_sessions = [
            {
                "subject": session_obj.subject,
                "start": session_obj.start,
                "end": session_obj.end,
            }
            for session_obj in day_sessions
            if session_obj.id != skip_session_id and session_obj.status != "cancelled"
        ]
        free_slots = _compute_free_slots(target_day, occupied_sessions)

        for slot_start, slot_end in free_slots:
            candidate_start = slot_start
            if target_day == search_start.date():
                candidate_start = max(candidate_start, search_start)
            candidate_start = _align_to_slot_boundary(candidate_start)
            candidate_end = candidate_start + duration
            if candidate_end <= slot_end:
                return candidate_start, candidate_end

    raise HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail="No free slot available today or tomorrow to reschedule this session.",
    )


def _reschedule_study_session(
    db: Session,
    current_user: User,
    session_obj: StudySession,
    *,
    reference_time: datetime | None = None,
) -> StudySession:
    now = reference_time or datetime.utcnow()
    if session_obj.status == "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Completed sessions cannot be rescheduled.",
        )
    if session_obj.status != "cancelled" and session_obj.end > now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only missed or cancelled sessions can be rescheduled.",
        )

    duration = session_obj.end - session_obj.start
    if duration <= timedelta(0):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Session duration must be positive to reschedule.",
        )

    effective_reference = max(now, session_obj.end)
    new_start, new_end = _find_next_reschedule_slot(
        db,
        current_user.id,
        duration=duration,
        reference_time=effective_reference,
        skip_session_id=session_obj.id,
    )

    payload = schemas.StudySessionCreate(
        subject=session_obj.subject,
        start=new_start,
        end=new_end,
        priority=session_obj.priority,
        document_id=session_obj.document_id,
        document_ids=session_obj.document_ids,
    )
    new_session = crud.create_study_session(
        db,
        current_user.id,
        payload,
        is_ai_generated=session_obj.is_ai_generated,
    )

    if session_obj.notes:
        new_session.notes = session_obj.notes

    session_obj.status = "cancelled"
    session_obj.completed_at = None
    db.commit()
    db.refresh(session_obj)
    db.refresh(new_session)
    return new_session


def _build_weighted_rotation(
    targets: list[dict[str, Any]],
    count: int,
) -> list[dict[str, Any]]:
    if count <= 0 or not targets:
        return []

    weighted_targets = [
        {
            **target,
            "weight": max(float(target.get("weight", 1.0)), 0.1),
            "current_weight": 0.0,
        }
        for target in targets
    ]
    total_weight = sum(target["weight"] for target in weighted_targets)
    rotation: list[dict[str, Any]] = []

    for _ in range(count):
        best_target: dict[str, Any] | None = None
        for target in weighted_targets:
            target["current_weight"] += target["weight"]
            if best_target is None or target["current_weight"] > best_target["current_weight"]:
                best_target = target

        if best_target is None:
            break

        best_target["current_weight"] -= total_weight
        rotation.append(best_target)

    return rotation


def _build_class_revision_targets(
    class_sessions: list[dict[str, Any]],
    default_priority: str,
    session_duration_min: int,
) -> list[dict[str, Any]]:
    subject_counts: dict[str, int] = {}
    for session in class_sessions:
        subject = session["subject"]
        subject_counts[subject] = subject_counts.get(subject, 0) + 1

    return [
        {
            "subject": f"Revision: {subject}",
            "priority": default_priority,
            "duration_min": session_duration_min,
            "min_duration_min": min(session_duration_min, 25),
            "document_id": None,
            "weight": float(count),
        }
        for subject, count in subject_counts.items()
    ]


def _build_quiz_revision_targets(
    quiz_performance: list[dict[str, Any]],
    default_priority: str,
    session_duration_min: int,
) -> list[dict[str, Any]]:
    targets: list[dict[str, Any]] = []

    for item in quiz_performance:
        weakness = item["weakness_score"]
        if weakness <= 0:
            continue

        targets.append(
            {
                "subject": f"Revision quiz: {item['document_name']}",
                "priority": "high" if weakness >= 0.6 else default_priority,
                "duration_min": session_duration_min,
                "min_duration_min": min(session_duration_min, 25),
                "document_id": item["document_id"],
                "weight": 1.0 + (weakness * 3.0),
            }
        )

    return targets


def _collect_recent_schedule_subjects(
    *,
    file_path: str,
    target_day: date,
    week_type: str | None,
) -> list[dict[str, Any]]:
    """Reuse subjects already studied earlier in the week for weekend revisions."""
    start_of_week = target_day - timedelta(days=target_day.weekday())
    collected: list[dict[str, Any]] = []

    for offset in range((target_day - start_of_week).days):
        history_day = start_of_week + timedelta(days=offset)
        collected.extend(
            parse_csv_schedule(
                file_path=file_path,
                target_date=history_day,
                week_type=week_type,
            )
        )

    return collected


def _should_schedule_exam_revision(target_day: date, exam_date: date) -> bool:
    days_until = (exam_date - target_day).days
    if days_until < 0:
        return False
    if days_until > 14:
        return target_day.weekday() == exam_date.weekday()
    if days_until >= 7:
        return days_until in {7, 10, 13}
    return True


def _build_exam_targets(
    target_day: date,
    exams: list[Exam],
    default_duration_min: int,
) -> list[dict[str, Any]]:
    targets: list[dict[str, Any]] = []
    for exam in exams:
        days_until = (exam.exam_date - target_day).days
        if not _should_schedule_exam_revision(target_day, exam.exam_date):
            continue

        if days_until <= 2:
            duration_min = max(default_duration_min + 20, 60)
            priority = "high"
        elif days_until <= 6:
            duration_min = max(default_duration_min, 50)
            priority = "high"
        elif days_until <= 14:
            duration_min = max(default_duration_min, 45)
            priority = "high" if days_until <= 10 else "medium"
        else:
            duration_min = max(default_duration_min, 35)
            priority = "medium"

        targets.append(
            {
                "subject": f"Revision examen: {exam.title}",
                "priority": priority,
                "duration_min": duration_min,
                "min_duration_min": min(duration_min, 30),
                "document_id": exam.document_id,
            }
        )

    return targets


def _prioritize_revision_free_slots(
    free_slots: list[tuple[datetime, datetime]],
    class_sessions: list[dict[str, Any]],
) -> list[tuple[datetime, datetime]]:
    if not free_slots or not class_sessions:
        return free_slots

    first_class_start = min(session["start"] for session in class_sessions)
    return sorted(
        free_slots,
        key=lambda slot: (
            0 if slot[0] >= first_class_start else 1,
            slot[0],
        ),
    )


def _allocate_revision_budgets(
    max_sessions: int,
    *,
    has_class_day: bool,
    course_count: int,
    exam_count: int,
    flashcard_count: int,
    quiz_count: int,
) -> dict[str, int]:
    budgets = {
        "course": 0,
        "exam": 0,
        "flashcard": 0,
        "quiz": 0,
    }
    if max_sessions <= 0:
        return budgets

    remaining = max_sessions

    if course_count:
        if has_class_day:
            min_course = 2 if max_sessions >= 2 else 1
            side_categories = sum(
                1 for count in (exam_count, flashcard_count, quiz_count) if count > 0
            )
            reserved_side_slots = min(max(0, max_sessions - min_course), min(2, side_categories))
            course_target = max(min_course, max_sessions - reserved_side_slots)
        else:
            course_target = max(1, math.ceil(max_sessions * 0.5))
        budgets["course"] = min(course_target, remaining)
        remaining -= budgets["course"]

    for category, count in (
        ("exam", exam_count),
        ("flashcard", flashcard_count),
        ("quiz", quiz_count),
    ):
        if remaining <= 0:
            break
        if count > 0:
            budgets[category] = 1
            remaining -= 1

    if remaining > 0:
        if course_count:
            budgets["course"] += remaining
            remaining = 0
        else:
            for category, count in (
                ("exam", exam_count),
                ("flashcard", flashcard_count),
                ("quiz", quiz_count),
            ):
                while remaining > 0 and budgets[category] < count:
                    budgets[category] += 1
                    remaining -= 1
                    if remaining <= 0:
                        break

    return budgets


def _take_unique_targets(
    targets: list[dict[str, Any]],
    count: int,
    *,
    used_subjects: set[str],
) -> list[dict[str, Any]]:
    if count <= 0 or not targets:
        return []

    ranked_targets = sorted(
        enumerate(targets),
        key=lambda item: (-float(item[1].get("weight", 1.0)), item[0]),
    )

    selected: list[dict[str, Any]] = []
    for _, target in ranked_targets:
        subject = target["subject"]
        if subject in used_subjects:
            continue
        selected.append(target)
        used_subjects.add(subject)
        if len(selected) >= count:
            break

    return selected


def _target_min_duration(target: dict[str, Any]) -> timedelta:
    min_duration = int(target.get("min_duration_min", target["duration_min"]))
    return timedelta(minutes=min_duration)


def _build_revision_sessions(
    target_day: date,
    class_sessions: list[dict[str, Any]],
    sleep_profile: dict[str, Any],
    revision_source_sessions: list[dict[str, Any]] | None = None,
    exams: list[Exam] | None = None,
    due_flashcard_subjects: list[dict[str, Any]] | None = None,
    quiz_performance: list[dict[str, Any]] | None = None,
    completion_rate_by_hour: dict[int, dict[str, float | int]] | None = None,
    preferred_schedule: str | None = None,
) -> list[dict[str, Any]]:
    """Generate adaptive revision sessions in the free slots for the day."""
    revision_source_sessions = revision_source_sessions or class_sessions
    exams = exams or []
    due_flashcard_subjects = due_flashcard_subjects or []
    quiz_performance = quiz_performance or []

    if (
        not class_sessions
        and not revision_source_sessions
        and not exams
        and not due_flashcard_subjects
        and not quiz_performance
    ):
        return []

    max_min = sleep_profile["max_session_min"]
    break_min = sleep_profile["break_min"]
    max_sessions = sleep_profile["max_sessions"]
    priority = sleep_profile["priority"]
    break_delta = timedelta(minutes=break_min)
    free_slots = _compute_free_slots(target_day, class_sessions)
    allowed_hours = _resolve_allowed_revision_hours(
        completion_rate_by_hour,
        preferred_schedule,
    )
    if class_sessions:
        # On timetable days, preserve the real gaps around classes.
        # Restrictive hour filtering was preventing revisions from appearing
        # after courses, unlike the original planner behavior.
        free_slots = _prioritize_revision_free_slots(free_slots, class_sessions)
    else:
        free_slots = _filter_free_slots_by_allowed_hours(target_day, free_slots, allowed_hours)

    class_revision_targets = _build_class_revision_targets(
        revision_source_sessions,
        priority,
        max_min,
    )
    quiz_revision_targets = _build_quiz_revision_targets(
        quiz_performance,
        priority,
        max_min,
    )
    exam_targets = _build_exam_targets(target_day, exams, max_min)
    flashcard_duration_min = max(15, min(25, max_min - 15))
    flashcard_targets = [
        {
            "subject": f"Revision flashcards: {item['document_name']}",
            "priority": priority,
            "duration_min": flashcard_duration_min,
            "min_duration_min": 15,
            "document_id": item["document_id"],
        }
        for item in due_flashcard_subjects
    ]

    planned_targets: list[dict[str, Any]] = []
    used_subjects: set[str] = set()
    remaining_capacity = max_sessions
    budgets = _allocate_revision_budgets(
        max_sessions,
        has_class_day=bool(class_sessions),
        course_count=len(class_revision_targets),
        exam_count=len(exam_targets),
        flashcard_count=len(flashcard_targets),
        quiz_count=len(quiz_revision_targets),
    )

    for targets, budget in (
        (class_revision_targets, budgets["course"]),
        (exam_targets, budgets["exam"]),
        (flashcard_targets, budgets["flashcard"]),
        (quiz_revision_targets, budgets["quiz"]),
    ):
        selected = _take_unique_targets(
            targets,
            budget,
            used_subjects=used_subjects,
        )
        planned_targets.extend(selected)
        remaining_capacity = max_sessions - len(planned_targets)
        if remaining_capacity <= 0:
            break

    if remaining_capacity > 0 and class_sessions:
        selected = _take_unique_targets(
            class_revision_targets,
            remaining_capacity,
            used_subjects=used_subjects,
        )
        planned_targets.extend(selected)
        remaining_capacity = max_sessions - len(planned_targets)

        if class_revision_targets and remaining_capacity > 0:
            # On class days, spare capacity should keep reinforcing the
            # studied courses before expanding into extra quiz/flashcard work.
            planned_targets.extend(_build_weighted_rotation(class_revision_targets, remaining_capacity))
            remaining_capacity = max_sessions - len(planned_targets)

    if remaining_capacity > 0:
        for targets in (
            class_revision_targets,
            exam_targets,
            flashcard_targets,
            quiz_revision_targets,
        ):
            selected = _take_unique_targets(
                targets,
                remaining_capacity,
                used_subjects=used_subjects,
            )
            planned_targets.extend(selected)
            remaining_capacity = max_sessions - len(planned_targets)
            if remaining_capacity <= 0:
                break

    if class_revision_targets and remaining_capacity > 0:
        # Duplicate course revisions are only allowed as a true fallback once
        # every unique target for the day has already been used.
        planned_targets.extend(_build_weighted_rotation(class_revision_targets, remaining_capacity))

    if not planned_targets:
        return []

    revision_sessions: list[dict[str, Any]] = []
    pending_targets = list(planned_targets)

    for slot_start_dt, slot_end_dt in free_slots:
        if not pending_targets:
            break

        cursor = slot_start_dt
        while pending_targets:
            available = slot_end_dt - cursor
            fitting_index = next(
                (
                    idx
                    for idx, candidate in enumerate(pending_targets)
                    if available >= _target_min_duration(candidate)
                ),
                None,
            )
            if fitting_index is None:
                break

            target = pending_targets.pop(fitting_index)
            desired_duration = timedelta(minutes=target["duration_min"])
            session_duration = min(desired_duration, available)
            revision_sessions.append(
                {
                    "subject": target["subject"],
                    "start": cursor,
                    "end": cursor + session_duration,
                    "priority": target["priority"],
                    "document_id": target["document_id"],
                }
            )
            logger.info(
                "  + Planned: '%s' %s -> %s [%s]",
                target["subject"],
                cursor.strftime("%H:%M"),
                (cursor + session_duration).strftime("%H:%M"),
                target["priority"],
            )
            cursor = cursor + session_duration + break_delta

    logger.info(
        "Generated %d adaptive sessions for %s (%s)",
        len(revision_sessions),
        target_day.isoformat(),
        sleep_profile["label"],
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
    exams: list[Exam] | None,
    week_type: str | None,
    allow_empty_csv: bool = False,
) -> list[dict]:
    crud.delete_study_sessions_by_date(db, current_user.id, target_day, only_ai=True)
    existing_sessions = crud.get_study_sessions_by_date(db, current_user.id, target_day)
    due_flashcard_subjects = crud.get_due_flashcard_subjects(db, current_user.id, target_day)
    completion_rate_by_hour = crud.get_completion_rate_by_hour(
        db,
        current_user.id,
        target_date=target_day,
    )
    quiz_performance = crud.get_recent_quiz_performance(
        db,
        current_user.id,
        target_date=target_day,
    )

    if doc_file_path and is_csv_schedule(doc_file_path):
        class_sessions = parse_csv_schedule(
            file_path=doc_file_path,
            target_date=target_day,
            week_type=week_type,
        )
        revision_source_sessions = class_sessions or _collect_recent_schedule_subjects(
            file_path=doc_file_path,
            target_day=target_day,
            week_type=week_type,
        )
        if not class_sessions and not allow_empty_csv and not (
            revision_source_sessions or exams or due_flashcard_subjects or quiz_performance
        ):
            from app.services.schedule_parser import _DAY_TO_WEEKDAY

            day_name = {v: k for k, v in _DAY_TO_WEEKDAY.items()}.get(target_day.weekday(), "?")
            iso_week = target_day.isocalendar()[1]
            auto_week = "A" if iso_week % 2 == 1 else "B"
            wt = week_type or auto_week
            raise ValueError(
                f"Aucun cours trouve pour {day_name.capitalize()} en semaine {wt}. "
                f"Verifiez votre fichier CSV."
            )

        if revision_source_sessions or exams or due_flashcard_subjects or quiz_performance:
            sleep_profile = _get_sleep_profile(db, current_user.id, target_day)
            revision_sessions = _build_revision_sessions(
                target_day,
                class_sessions,
                sleep_profile,
                revision_source_sessions=revision_source_sessions,
                exams=exams,
                due_flashcard_subjects=due_flashcard_subjects,
                quiz_performance=quiz_performance,
                completion_rate_by_hour=completion_rate_by_hour,
                preferred_schedule=current_user.profile.preferred_schedule
                if current_user.profile
                else "morning",
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
            document_id=item.get("document_id"),
            document_ids=item.get("document_ids"),
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
    selected_exams = _get_selected_exams(db, current_user, body.date, body.exam_ids)

    try:
        generated_sessions = _generate_sessions_for_day(
            body.date,
            db=db,
            current_user=current_user,
            preferences=body.preferences,
            collection_name=collection_name,
            doc_file_path=doc_file_path,
            exams=selected_exams,
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
    selected_exams = _get_selected_exams(
        db,
        current_user,
        target_days[0],
        body.exam_ids,
    )

    try:
        for target_day in target_days:
            generated_sessions = _generate_sessions_for_day(
                target_day,
                db=db,
                current_user=current_user,
                preferences=body.preferences,
                collection_name=collection_name,
                doc_file_path=doc_file_path,
                exams=selected_exams,
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


@router.get("/insights", response_model=schemas.PlanningInsightsOut)
def get_planning_insights(
    period: schemas.PlanningInsightsPeriod = "week",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return _build_planning_insights(
        db,
        current_user,
        period=period,
    )


@router.get("/exams", response_model=list[schemas.ExamOut])
def list_exams(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return crud.get_upcoming_exams(db, current_user.id)


@router.post("/exams", response_model=schemas.ExamOut, status_code=status.HTTP_201_CREATED)
def create_exam(
    body: schemas.ExamCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _get_owned_document(db, current_user, body.document_id)
    return crud.create_exam(db, current_user.id, body)


@router.delete("/exams/{exam_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_exam(
    exam_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    exam = _get_owned_exam(db, current_user, exam_id)
    crud.delete_exam(db, exam)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reschedule/{session_id}", response_model=schemas.StudySessionOut)
def reschedule_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session_obj = _get_owned_session(db, current_user, session_id)
    return _reschedule_study_session(db, current_user, session_obj)


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
    _get_owned_document(db, current_user, body.document_id)
    _get_owned_documents(db, current_user, body.document_ids)
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
    session_obj = _get_owned_session(db, current_user, id)
    _get_owned_document(db, current_user, body.document_id)
    _get_owned_documents(db, current_user, body.document_ids)

    session_obj = crud.update_study_session(db, session_obj, body)
    return session_obj


@router.delete("/sessions/{id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_session(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session_obj = _get_owned_session(db, current_user, id)
    crud.delete_study_session(db, session_obj)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.patch("/sessions/{id}/complete", response_model=schemas.StudySessionOut)
def complete_session(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session_obj = _get_owned_session(db, current_user, id)
    session_obj = crud.complete_study_session(db, session_obj)
    return session_obj
