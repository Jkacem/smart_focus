"""
Planning Service — Generate daily sessions using Gemini, respecting user blocks.
Optionally uses RAG (Chroma + Gemini) to extract timetable constraints from a PDF.

Architecture: Deterministic slot computation + AI-powered subject assignment.
- Free slots, session durations, and conflict avoidance are computed in Python.
- Gemini is used for subject naming, personalization, and priority suggestions.
- A deterministic fallback ensures valid output even when AI fails.
"""

from __future__ import annotations

import json
import logging
import re
from datetime import date, datetime, time, timedelta
from typing import Any

import google.generativeai as genai
from langchain_community.vectorstores import Chroma

from app.config import settings
from app.models.models import StudySession, UserProfile
from app.services.rag_service import _get_embeddings, _chroma_path

logger = logging.getLogger(__name__)

# ── Constants ─────────────────────────────────────────────────────────────────
_DAY_START_HOUR = 8
_DAY_END_HOUR = 22
_BUFFER_MINUTES = 15
_MIN_SESSION_MINUTES = 25
_MAX_SESSION_MINUTES = 90
_DEFAULT_SESSION_MINUTES = 50

# ── French day-of-week mapping ────────────────────────────────────────────────
_FRENCH_DAYS = {
    0: "Lundi",
    1: "Mardi",
    2: "Mercredi",
    3: "Jeudi",
    4: "Vendredi",
    5: "Samedi",
    6: "Dimanche",
}

# ── Preferred schedule → hour ranges ──────────────────────────────────────────
_SCHEDULE_HOURS = {
    "morning": (8, 12),
    "afternoon": (12, 18),
    "noon": (12, 18),
    "evening": (18, 22),
    "night": (18, 22),
    "late": (18, 22),
}

# ── AI prompt: Gemini only assigns subjects to pre-computed slots ─────────────
_PLANNING_PROMPT = """Tu es un expert en gestion du temps et en pédagogie.
L'utilisateur a {num_slots} créneaux de révision disponibles pour la date du {date_str}.

PROFIL UTILISATEUR:
- Objectif de concentration quotidien: {daily_focus_goal} minutes
- Préférence de moment: {preferred_schedule}
- Préférences spécifiques: {preferences}

COURS DU JOUR (contexte pour choisir les matières de révision):
{class_context}

CRÉNEAUX DISPONIBLES (tu dois assigner une matière à chaque créneau):
{slots_description}

INSTRUCTIONS:
1. Pour chaque créneau, propose un sujet de révision pertinent et une priorité.
2. Inspire-toi des cours du jour et des préférences pour choisir les matières.
3. Varie les matières entre les créneaux si possible.
4. Les heures sont DÉJÀ FIXÉES — ne les modifie pas.

FORMAT STRICT (JSON uniquement, sans markdown, un objet par créneau):
[
  {{
    "slot_index": 0,
    "subject": "Nom de la session",
    "priority": "high"
  }}
]"""

# ── Dedicated timetable extraction prompt ─────────────────────────────────────
_TIMETABLE_EXTRACTION_PROMPT = """Tu es un assistant spécialisé dans l'extraction d'emplois du temps.

On te fournit le contenu textuel d'un document PDF qui contient un emploi du temps (planning de cours / schedule).
L'emploi du temps est probablement organisé par JOUR DE LA SEMAINE (Lundi, Mardi, Mercredi, Jeudi, Vendredi, Samedi, Dimanche).

JOUR CIBLE : {day_name} (correspondant à la date {date_str})

Ta tâche : Extraire TOUS les cours / créneaux / événements prévus pour le jour "{day_name}" dans ce document.

CONTENU DU DOCUMENT :
{document_text}

INSTRUCTIONS :
1. Cherche dans le document tous les cours ou événements associés au jour "{day_name}".
2. Chaque cours a généralement un nom/matière, une heure de début et une heure de fin.
3. Utilise le format ISO pour les dates/heures, en combinant la date {date_str} avec les heures trouvées.
4. Si tu ne trouves AUCUN cours pour "{day_name}", retourne un tableau vide [].
5. NE RETOURNE QUE DU JSON VALIDE, sans markdown, sans explication, juste le tableau.

FORMAT DE SORTIE :
[
  {{
    "title": "Nom du cours ou de la matière",
    "start": "{date_str}T08:00:00",
    "end": "{date_str}T10:00:00"
  }}
]

Retourne UNIQUEMENT le JSON :"""


# ══════════════════════════════════════════════════════════════════════════════
# FREE SLOT COMPUTATION (deterministic)
# ══════════════════════════════════════════════════════════════════════════════

def _compute_free_slots(
    day: date,
    blocks: list[tuple[str, datetime, datetime]],
    *,
    start_hour: int = _DAY_START_HOUR,
    end_hour: int = _DAY_END_HOUR,
    buffer_minutes: int = _BUFFER_MINUTES,
) -> list[tuple[datetime, datetime]]:
    """Compute free time windows around existing blocks for a given day.

    Returns a list of (start, end) datetime tuples representing available slots,
    with a configurable buffer around each existing block.
    """
    day_start = datetime.combine(day, time(start_hour, 0))
    day_end = datetime.combine(day, time(end_hour, 0))
    buffer = timedelta(minutes=buffer_minutes)

    if not blocks:
        return [(day_start, day_end)]

    # Sort blocks chronologically
    sorted_blocks = sorted(blocks, key=lambda b: b[1])
    free_slots: list[tuple[datetime, datetime]] = []

    # Gap before the first block
    first_start = sorted_blocks[0][1]
    slot_end = first_start - buffer
    if slot_end > day_start:
        free_slots.append((day_start, slot_end))

    # Gaps between consecutive blocks
    for i in range(len(sorted_blocks) - 1):
        gap_start = sorted_blocks[i][2] + buffer
        gap_end = sorted_blocks[i + 1][1] - buffer
        if gap_end > gap_start:
            free_slots.append((gap_start, gap_end))

    # Gap after the last block
    last_end = sorted_blocks[-1][2]
    slot_start = last_end + buffer
    if slot_start < day_end:
        free_slots.append((slot_start, day_end))

    return free_slots


def _filter_slots_by_preference(
    free_slots: list[tuple[datetime, datetime]],
    preferred_schedule: str,
) -> list[tuple[datetime, datetime]]:
    """Sort free slots to prioritize the user's preferred time of day.

    Preferred-hour slots come first, others follow. Never removes slots entirely
    — this ensures the daily focus goal can still be met even if preferred hours
    are occupied.
    """
    pref_start, pref_end = _SCHEDULE_HOURS.get(
        preferred_schedule.strip().lower(),
        (8, 12),
    )

    def _preference_score(slot: tuple[datetime, datetime]) -> int:
        slot_hour = slot[0].hour
        if pref_start <= slot_hour < pref_end:
            return 0  # preferred
        return 1  # non-preferred

    return sorted(free_slots, key=_preference_score)


# ══════════════════════════════════════════════════════════════════════════════
# SESSION FITTING (deterministic)
# ══════════════════════════════════════════════════════════════════════════════

def _fit_sessions_into_slots(
    free_slots: list[tuple[datetime, datetime]],
    daily_focus_goal: int,
    *,
    max_session_min: int = _DEFAULT_SESSION_MINUTES,
    min_session_min: int = _MIN_SESSION_MINUTES,
    break_min: int = _BUFFER_MINUTES,
) -> list[tuple[datetime, datetime]]:
    """Create session time windows from free slots to meet the daily focus goal.

    Args:
        free_slots: Available time windows (already sorted by preference).
        daily_focus_goal: Target total study minutes for the day.
        max_session_min: Maximum duration per session.
        min_session_min: Minimum duration per session (shorter slots are skipped).
        break_min: Break duration between consecutive sessions within a slot.

    Returns:
        List of (start, end) tuples for each session.
    """
    sessions: list[tuple[datetime, datetime]] = []
    remaining = daily_focus_goal
    break_delta = timedelta(minutes=break_min)

    for slot_start, slot_end in free_slots:
        if remaining <= 0:
            break

        cursor = slot_start
        while remaining > 0:
            available_minutes = int((slot_end - cursor).total_seconds() / 60)

            if available_minutes < min_session_min:
                break

            # Use the smaller of: max session, remaining goal, available time
            session_minutes = min(max_session_min, remaining, available_minutes)

            # Don't create tiny sessions unless it's all we need
            if session_minutes < min_session_min and remaining >= min_session_min:
                break

            session_end = cursor + timedelta(minutes=session_minutes)
            sessions.append((cursor, session_end))
            remaining -= session_minutes

            # Move cursor past the session + break
            cursor = session_end + break_delta

    logger.info(
        "Fitted %d sessions (total %d min, goal %d min) into free slots",
        len(sessions),
        daily_focus_goal - remaining,
        daily_focus_goal,
    )
    return sessions


# ══════════════════════════════════════════════════════════════════════════════
# AI SUBJECT ASSIGNMENT (Gemini — for naming only)
# ══════════════════════════════════════════════════════════════════════════════

def _assign_subjects_via_ai(
    session_slots: list[tuple[datetime, datetime]],
    day: date,
    *,
    daily_focus_goal: int,
    preferred_schedule: str,
    preferences: dict[str, Any] | None,
    class_subjects: list[str],
) -> list[dict[str, Any]] | None:
    """Ask Gemini to assign subjects/priorities to pre-computed session slots.

    Returns a list of dicts with slot_index, subject, priority — or None if AI fails.
    This is purely for naming/personalization; time slots are already fixed.
    """
    if not session_slots:
        return []

    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel("gemini-2.5-flash")

    # Build slot descriptions
    slots_desc = "\n".join(
        f"  Créneau {i}: {start.strftime('%H:%M')} → {end.strftime('%H:%M')} "
        f"({int((end - start).total_seconds() / 60)} min)"
        for i, (start, end) in enumerate(session_slots)
    )

    # Build class context
    if class_subjects:
        class_context = "\n".join(f"- {subj}" for subj in class_subjects)
    else:
        class_context = "Aucun cours programmé pour aujourd'hui."

    pref_str = (
        json.dumps(preferences, ensure_ascii=False)
        if preferences
        else "Aucune préférence spécifique."
    )

    prompt = _PLANNING_PROMPT.format(
        num_slots=len(session_slots),
        date_str=day.isoformat(),
        daily_focus_goal=daily_focus_goal,
        preferred_schedule=preferred_schedule,
        preferences=pref_str,
        class_context=class_context,
        slots_description=slots_desc,
    )

    try:
        response = llm.generate_content(prompt)
        raw_text = response.text.strip()

        # Strip markdown fences
        raw_text = re.sub(r"^```(?:json)?\s*", "", raw_text)
        raw_text = re.sub(r"\s*```$", "", raw_text)
        raw_text = raw_text.strip()

        # Extract JSON array
        match = re.search(r"\[\s*\{.*\}\s*\]", raw_text, re.DOTALL)
        if match:
            raw_text = match.group(0)

        assignments = json.loads(raw_text)
        if isinstance(assignments, list):
            logger.info(
                "Gemini assigned subjects for %d/%d slots",
                len(assignments),
                len(session_slots),
            )
            return assignments

    except json.JSONDecodeError as e:
        logger.warning("Gemini returned invalid JSON for subject assignment: %s", e)
    except Exception as e:
        logger.warning("Gemini subject assignment failed: %s", e)

    return None


# ══════════════════════════════════════════════════════════════════════════════
# DETERMINISTIC FALLBACK (when AI fails or is unavailable)
# ══════════════════════════════════════════════════════════════════════════════

def _deterministic_subject_assignment(
    session_slots: list[tuple[datetime, datetime]],
    class_subjects: list[str],
    preferences: dict[str, Any] | None,
) -> list[dict[str, Any]]:
    """Generate sensible subject assignments without AI.

    Uses class subjects as revision targets (round-robin), or falls back to
    generic "Focus Session" labels. Preferences can override subjects if
    they contain a ``subjects`` key.
    """
    # Determine subject pool
    subject_pool: list[str] = []

    # 1. Explicit subjects from preferences
    if preferences and isinstance(preferences.get("subjects"), list):
        subject_pool = [str(s).strip() for s in preferences["subjects"] if s]

    # 2. Revision of today's classes
    if not subject_pool and class_subjects:
        subject_pool = [f"Revision: {subj}" for subj in class_subjects]

    # 3. Generic fallback
    if not subject_pool:
        subject_pool = ["Focus Session"]

    assignments: list[dict[str, Any]] = []
    for i in range(len(session_slots)):
        subject = subject_pool[i % len(subject_pool)]
        assignments.append({
            "slot_index": i,
            "subject": subject,
            "priority": "medium",
        })

    return assignments


# ══════════════════════════════════════════════════════════════════════════════
# POST-PROCESSING: merge AI assignments with computed slots
# ══════════════════════════════════════════════════════════════════════════════

def _merge_assignments_with_slots(
    session_slots: list[tuple[datetime, datetime]],
    assignments: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Combine AI/deterministic subject assignments with pre-computed time slots.

    The resulting sessions have guaranteed valid times (no overlaps, correct date,
    proper durations) because the slots were computed deterministically. Only the
    subject names and priorities come from the AI.
    """
    # Index assignments by slot_index for fast lookup
    assignment_map: dict[int, dict[str, Any]] = {}
    for a in assignments:
        idx = a.get("slot_index")
        if isinstance(idx, int) and 0 <= idx < len(session_slots):
            assignment_map[idx] = a

    result: list[dict[str, Any]] = []
    for i, (start, end) in enumerate(session_slots):
        a = assignment_map.get(i, {})
        subject = str(a.get("subject", "Focus Session")).strip() or "Focus Session"
        priority = str(a.get("priority", "medium")).lower()
        if priority not in ("low", "medium", "high"):
            priority = "medium"

        result.append({
            "subject": subject,
            "start": start,
            "end": end,
            "priority": priority,
        })

    return result


# ══════════════════════════════════════════════════════════════════════════════
# TIMETABLE EXTRACTION (AI-powered — appropriate use of LLM)
# ══════════════════════════════════════════════════════════════════════════════

def _extract_timetable_from_collection(
    collection_name: str,
    day: date,
) -> list[tuple[str, datetime, datetime]]:
    """
    Retrieve ALL chunks from a ChromaDB collection, then use a dedicated
    Gemini prompt to extract classes for the target day-of-week.

    Returns list of (title, start_dt, end_dt) tuples.
    """
    day_name = _FRENCH_DAYS[day.weekday()]
    date_str = day.isoformat()

    logger.info(
        "Extracting timetable for %s (%s) from collection '%s'",
        date_str, day_name, collection_name,
    )

    # ── Step 1: Retrieve ALL chunks from the collection ───────────────────
    embeddings = _get_embeddings()
    vectorstore = Chroma(
        collection_name=collection_name,
        embedding_function=embeddings,
        persist_directory=_chroma_path(),
    )

    # Use a broad query to retrieve as many relevant chunks as possible.
    # We use multiple search terms to maximize coverage of the timetable.
    search_queries = [
        f"emploi du temps {day_name} horaires cours",
        f"schedule {day_name} classes",
        f"{day_name} cours heures",
        "emploi du temps planning horaires",
    ]

    all_chunks = []
    seen_contents = set()
    for q in search_queries:
        try:
            results = vectorstore.similarity_search(q, k=15)
            for doc in results:
                content_hash = hash(doc.page_content)
                if content_hash not in seen_contents:
                    seen_contents.add(content_hash)
                    all_chunks.append(doc)
        except Exception as e:
            logger.warning("Search query '%s' failed: %s", q, e)

    if not all_chunks:
        logger.warning("No chunks retrieved from collection '%s'", collection_name)
        return []

    # ── Step 2: Build full document text from retrieved chunks ─────────────
    # Sort by page number for coherent ordering
    all_chunks.sort(key=lambda c: c.metadata.get("page", 0))
    document_text = "\n\n---\n\n".join(c.page_content for c in all_chunks)
    logger.info(
        "Retrieved %d unique chunks (%d chars) from collection '%s'",
        len(all_chunks), len(document_text), collection_name,
    )

    # ── Step 3: Dedicated Gemini call for timetable extraction ────────────
    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel("gemini-2.5-flash")

    prompt = _TIMETABLE_EXTRACTION_PROMPT.format(
        day_name=day_name,
        date_str=date_str,
        document_text=document_text,
    )

    response = llm.generate_content(prompt)
    raw = response.text.strip()
    logger.info("Gemini timetable extraction raw response:\n%s", raw)

    # ── Step 4: Parse JSON ────────────────────────────────────────────────
    # Strip markdown code fences if present
    raw = re.sub(r"^```(?:json)?\s*", "", raw)
    raw = re.sub(r"\s*```$", "", raw)
    raw = raw.strip()

    match = re.search(r"\[\s*\{.*\}\s*\]", raw, re.DOTALL)
    if match:
        raw = match.group(0)

    # Handle empty array
    if raw.strip() == "[]":
        logger.info("Gemini returned empty timetable for %s (%s)", date_str, day_name)
        return []

    try:
        items = json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error("Failed to parse timetable JSON: %s\nRaw: %s", e, raw)
        return []

    if not isinstance(items, list):
        logger.error("Expected list, got %s", type(items).__name__)
        return []

    # ── Step 5: Convert to typed tuples ───────────────────────────────────
    timetable_blocks: list[tuple[str, datetime, datetime]] = []
    for it in items:
        if not isinstance(it, dict):
            continue
        title = str(it.get("title") or it.get("subject") or "Cours").strip() or "Cours"
        start_s = it.get("start")
        end_s = it.get("end")
        if not start_s or not end_s:
            logger.warning("Skipping item without start/end: %s", it)
            continue
        try:
            start_dt = datetime.fromisoformat(str(start_s))
            end_dt = datetime.fromisoformat(str(end_s))
        except Exception as e:
            logger.warning("Skipping item with bad datetime: %s (%s)", it, e)
            continue

        # Force date to match target day (avoid hallucinated dates)
        if start_dt.date() != day:
            start_dt = datetime.combine(day, start_dt.time())
        if end_dt.date() != day:
            end_dt = datetime.combine(day, end_dt.time())

        if end_dt <= start_dt:
            logger.warning("Skipping item with end <= start: %s", it)
            continue

        timetable_blocks.append((title, start_dt, end_dt))
        logger.info("  Extracted: '%s' %s → %s", title, start_dt, end_dt)

    logger.info(
        "Total timetable blocks extracted for %s (%s): %d",
        date_str, day_name, len(timetable_blocks),
    )
    return timetable_blocks


# ══════════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

def generate_daily_schedule(
    day: date,
    existing_sessions: list[StudySession],
    profile: UserProfile | None,
    preferences: dict[str, Any] | None = None,
    collection_name: str | None = None,
) -> list[dict[str, Any]]:
    """Generate a daily study schedule using deterministic slot computation + AI naming.

    Pipeline:
      1. Collect all existing blocks (manual sessions + timetable from PDF)
      2. Compute free slots deterministically (guaranteed no overlaps)
      3. Fit session windows into free slots (respecting focus goal + durations)
      4. Ask Gemini to assign subjects/priorities to the pre-computed slots
      5. Fall back to deterministic naming if Gemini fails

    Returns:
        List of session dicts ready to be persisted.
    """
    # ── Step 1: Collect all existing blocks ────────────────────────────────
    manual_blocks: list[tuple[str, datetime, datetime]] = []
    for s in existing_sessions or []:
        manual_blocks.append((s.subject, s.start, s.end))

    # ── Timetable extraction from PDF via ChromaDB + Gemini ───────────────
    timetable_blocks: list[tuple[str, datetime, datetime]] = []
    generated_from_timetable: list[dict[str, Any]] = []

    if collection_name:
        timetable_blocks = _extract_timetable_from_collection(collection_name, day)

        if timetable_blocks:
            for title, start_dt, end_dt in sorted(timetable_blocks, key=lambda x: x[1]):
                generated_from_timetable.append({
                    "subject": title,
                    "start": start_dt,
                    "end": end_dt,
                    "priority": "high",
                })

            logger.info(
                "Extracted %d class sessions from timetable to use as constraints.",
                len(generated_from_timetable),
            )
        else:
            raise ValueError(
                f"Aucun cours n'a pu être extrait du document pour le jour "
                f"{_FRENCH_DAYS[day.weekday()]} ({day.isoformat()}). "
                f"Vérifiez que le PDF contient bien un emploi du temps avec ce jour."
            )

    # ── Step 2: Compute free slots deterministically ──────────────────────
    all_blocks = manual_blocks + timetable_blocks

    daily_focus_goal = profile.daily_focus_goal if profile else 120
    preferred_schedule = profile.preferred_schedule if profile else "morning"

    free_slots = _compute_free_slots(day, all_blocks)
    free_slots = _filter_slots_by_preference(free_slots, preferred_schedule)

    logger.info(
        "Computed %d free slots for %s (blocks: %d manual + %d timetable)",
        len(free_slots),
        day.isoformat(),
        len(manual_blocks),
        len(timetable_blocks),
    )
    for slot_start, slot_end in free_slots:
        logger.info(
            "  Free: %s → %s (%d min)",
            slot_start.strftime("%H:%M"),
            slot_end.strftime("%H:%M"),
            int((slot_end - slot_start).total_seconds() / 60),
        )

    # ── Step 3: Fit session windows into free slots ───────────────────────
    # Determine session size constraints
    max_session_min = min(_MAX_SESSION_MINUTES, max(_MIN_SESSION_MINUTES, daily_focus_goal // 2))

    session_slots = _fit_sessions_into_slots(
        free_slots,
        daily_focus_goal,
        max_session_min=max_session_min,
        min_session_min=_MIN_SESSION_MINUTES,
        break_min=_BUFFER_MINUTES,
    )

    if not session_slots and not generated_from_timetable:
        logger.warning("No session slots could be fitted for %s", day.isoformat())
        return []

    # ── Step 4: Ask Gemini for subject assignments ────────────────────────
    class_subjects = [title for title, _, _ in timetable_blocks]

    ai_assignments = _assign_subjects_via_ai(
        session_slots,
        day,
        daily_focus_goal=daily_focus_goal,
        preferred_schedule=preferred_schedule,
        preferences=preferences,
        class_subjects=class_subjects,
    )

    # ── Step 5: Fallback if AI fails ──────────────────────────────────────
    if ai_assignments is None:
        logger.info("Using deterministic fallback for subject assignment on %s", day.isoformat())
        ai_assignments = _deterministic_subject_assignment(
            session_slots,
            class_subjects,
            preferences,
        )

    # ── Step 6: Merge assignments with pre-computed slots ─────────────────
    study_sessions = _merge_assignments_with_slots(session_slots, ai_assignments)

    logger.info(
        "Generated %d study sessions for %s "
        "(%d from timetable + %d revision, focus goal: %d min)",
        len(generated_from_timetable) + len(study_sessions),
        day.isoformat(),
        len(generated_from_timetable),
        len(study_sessions),
        daily_focus_goal,
    )

    return generated_from_timetable + study_sessions
