"""
Planning Service — Generate daily sessions using Gemini, respecting user blocks.
Optionally uses RAG (Chroma + Gemini) to extract timetable constraints from a PDF.
"""

from __future__ import annotations

import json
import logging
import re
from datetime import date, datetime, timedelta
from typing import Any

import google.generativeai as genai
from langchain_community.vectorstores import Chroma

from app.config import settings
from app.models.models import StudySession, UserProfile
from app.services import rag_service
from app.services.rag_service import _get_embeddings, _chroma_path

logger = logging.getLogger(__name__)

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


_PLANNING_PROMPT = """Tu es un expert en gestion du temps et en pédagogie. 
Ton objectif est de générer un planning de révision/travail optimal pour l'utilisateur pour la date du {date_str}.

CONTRAINTES UTILISATEUR:
- Objectif de concentration quotidien: {daily_focus_goal} minutes
- Préférence de moment de la journée: {preferred_schedule} (ex: morning, afternoon, night)
- Préférences de session spécifiques fournies (ex. matières) : {preferences}

BLOCS DÉJÀ EXISTANTS (À NE SURTOUT PAS CHEVAUCHER):
{existing_blocks}

INSTRUCTIONS DE GÉNÉRATION:
1. Tu dois générer des sessions de révision ou de travail (ex: "Focus Session", "Révision Math", "Lecture").
2. Les nouvelles sessions NE DOIVENT STRICTEMENT PAS chevaucher les "Blocs déjà existants" mentionnés ci-dessus. Laisse un peu de temps (ex: 10-15 min) entre les blocs.
3. Essaie d'atteindre l'objectif de concentration quotidien cumulé avec la durée totale de tes nouvelles sessions.
4. Les sessions générées doivent se situer *uniquement* à la date du {date_str}.
5. Format des dates attendu : YYYY-MM-DDTHH:MM:SS (format ISO).
6. Tu vas retourner le résultat sous la forme d'un tableau JSON avec les valeurs exactes demandées ci-dessous.

FORMAT STRICT DE SORTIE (JSON uniquement, sans markdown ni autre texte, réponds juste par des crochets [...] contenant les objets):
[
  {{
    "subject": "Nom de la session",
    "start": "2023-12-01T09:00:00",
    "end": "2023-12-01T10:30:00",
    "priority": "high"
  }}
]
"""

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


def generate_daily_schedule(
    day: date,
    existing_sessions: list[StudySession],
    profile: UserProfile | None,
    preferences: dict[str, Any] | None = None,
    collection_name: str | None = None,
) -> list[dict[str, Any]]:
    """
    Returns a list of optimal studying sessions that do not overlap with existing blocks.
    Calls Gemini API to generate the JSON.
    """
    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel('gemini-2.5-flash')

    def _blocks_to_str(blocks: list[tuple[str, datetime, datetime]]) -> str:
        if not blocks:
            return "Aucun bloc existant pour le moment."
        return "\n".join(
            f"- '{title}' : de {start_dt.strftime('%H:%M:%S')} à {end_dt.strftime('%H:%M:%S')}"
            for title, start_dt, end_dt in blocks
        )

    # Format manual existing constraints
    manual_blocks: list[tuple[str, datetime, datetime]] = []
    for s in existing_sessions or []:
        manual_blocks.append((s.subject, s.start, s.end))

    # ── Timetable extraction from PDF via ChromaDB + Gemini ───────────────
    timetable_blocks: list[tuple[str, datetime, datetime]] = []
    if collection_name:
        timetable_blocks = _extract_timetable_from_collection(collection_name, day)

        # If a timetable document is provided and parsed successfully,
        # return one session per class slot found in the timetable.
        if timetable_blocks:
            generated_from_timetable: list[dict[str, Any]] = []
            for title, start_dt, end_dt in sorted(timetable_blocks, key=lambda x: x[1]):
                generated_from_timetable.append(
                    {
                        "subject": title,
                        "start": start_dt,
                        "end": end_dt,
                        "priority": "high",
                    }
                )

            if generated_from_timetable:
                logger.info(
                    "Returning %d sessions directly from timetable extraction.",
                    len(generated_from_timetable),
                )
                return generated_from_timetable

        # Document was provided but extraction yielded nothing
        raise ValueError(
            f"Aucun cours n'a pu être extrait du document pour le jour "
            f"{_FRENCH_DAYS[day.weekday()]} ({day.isoformat()}). "
            f"Vérifiez que le PDF contient bien un emploi du temps avec ce jour."
        )

    # ── Fallback: generic Gemini planning (no document provided) ──────────
    existing_blocks_str = _blocks_to_str(manual_blocks)

    # Format profile data
    daily_focus_goal = profile.daily_focus_goal if profile else 120
    preferred_schedule = profile.preferred_schedule if profile else "morning"

    pref_str = json.dumps(preferences, ensure_ascii=False) if preferences else "Aucune préférence spécifique."

    prompt = _PLANNING_PROMPT.format(
        date_str=day.isoformat(),
        daily_focus_goal=daily_focus_goal,
        preferred_schedule=preferred_schedule,
        preferences=pref_str,
        existing_blocks=existing_blocks_str,
    )

    response = llm.generate_content(prompt)
    raw_text = response.text.strip()

    # Extract JSON Array using Regex
    match = re.search(r'\[\s*\{.*\}\s*\]', raw_text, re.DOTALL)
    if match:
        raw_text = match.group(0)

    try:
        new_sessions = json.loads(raw_text)
    except json.JSONDecodeError as e:
        raise ValueError(f"Gemini returned invalid JSON (planning): {e}\nRaw output: {raw_text}")

    # Validate schema loosely and convert to datetime objects
    validated = []
    for item in new_sessions:
        if "subject" in item and "start" in item and "end" in item:
            try:
                dt_start = datetime.fromisoformat(item["start"])
                dt_end = datetime.fromisoformat(item["end"])
                
                # Correct AI hallucinations overriding the day
                if dt_start.date() != day:
                    dt_start = datetime.combine(day, dt_start.time())
                if dt_end.date() != day:
                    dt_end = datetime.combine(day, dt_end.time())

                # Double check to prevent inverted start/end dates
                if dt_end <= dt_start:
                    continue

                validated.append({
                    "subject": item["subject"].strip() or "Focus Session",
                    "start": dt_start,
                    "end": dt_end,
                    "priority": item.get("priority", "medium").lower()
                })
            except Exception:
                continue

    return validated
