"""
Schedule Parser — Deterministic CSV timetable parser.

Parses a structured CSV template with columns: week, day, start, end, subject
Supports Week A / Week B alternating schedules.
"""

from __future__ import annotations

import csv
import io
import logging
from datetime import date, datetime, time
from typing import Any

logger = logging.getLogger(__name__)

# French day names → Python weekday() index
_DAY_TO_WEEKDAY = {
    "lundi": 0,
    "mardi": 1,
    "mercredi": 2,
    "jeudi": 3,
    "vendredi": 4,
    "samedi": 5,
    "dimanche": 6,
}

# Alias used by the router for error messages
_FRENCH_DAYS = _DAY_TO_WEEKDAY

# Required CSV columns
_REQUIRED_COLUMNS = {"week", "day", "start", "end", "subject"}


def _normalize_week(raw: str) -> str:
    """Normalise a week value to 'A' or 'B'.

    Accepts:
      - 'A' / 'B'  (letter format)
      - '1' / '2'  (numeric format used by Emploi_A_fixed.csv)
      - anything else is returned as-is (will be filtered later)
    """
    mapping = {"1": "A", "2": "B", "A": "A", "B": "B"}
    return mapping.get(raw.upper().strip(), raw.upper().strip())


def is_csv_schedule(file_path: str) -> bool:
    """Check if a file is a CSV schedule template by inspecting its header."""
    try:
        with open(file_path, "r", encoding="utf-8-sig") as f:
            header = f.readline().strip().lower()
            columns = {c.strip() for c in header.split(",")}
            return _REQUIRED_COLUMNS.issubset(columns)
    except Exception:
        return False


def parse_csv_schedule(
    file_path: str,
    target_date: date,
    week_type: str | None = None,
) -> list[dict[str, Any]]:
    """
    Parse a CSV schedule template and return sessions for the target date.

    Args:
        file_path:   Path to the CSV file on disk.
        target_date: The date to generate sessions for.
        week_type:   'A' or 'B' (or None to auto-detect based on ISO week number).

    Returns:
        List of dicts with keys: subject, start (datetime), end (datetime), priority.
    """
    # Auto-detect week type from ISO week number if not specified
    if not week_type:
        iso_week = target_date.isocalendar()[1]
        week_type = "A" if iso_week % 2 == 1 else "B"
        logger.info(
            "Auto-detected week type: %s (ISO week %d for %s)",
            week_type, iso_week, target_date.isoformat(),
        )

    week_type = week_type.upper().strip()
    target_weekday = target_date.weekday()  # 0=Monday, 6=Sunday

    logger.info(
        "Parsing CSV schedule: file=%s, date=%s, weekday=%d, week_type=%s",
        file_path, target_date.isoformat(), target_weekday, week_type,
    )

    sessions: list[dict[str, Any]] = []

    try:
        with open(file_path, "r", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            # Normalize column names
            if reader.fieldnames:
                reader.fieldnames = [col.strip().lower() for col in reader.fieldnames]

            for row_num, row in enumerate(reader, start=2):  # start=2 because row 1 is header
                # Normalize values
                row_week = _normalize_week(row.get("week") or "")
                row_day = (row.get("day") or "").strip().lower()
                row_start = (row.get("start") or "").strip()
                row_end = (row.get("end") or "").strip()
                row_subject = (row.get("subject") or "").strip()

                # Skip empty rows
                if not row_day or not row_start or not row_end or not row_subject:
                    logger.debug("Skipping incomplete row %d: %s", row_num, row)
                    continue

                # Filter by week type (empty week cell = applies to all weeks)
                if row_week and row_week != week_type:
                    continue

                # Filter by day of week
                row_weekday = _DAY_TO_WEEKDAY.get(row_day)
                if row_weekday is None:
                    logger.warning("Unknown day name '%s' in row %d", row_day, row_num)
                    continue
                if row_weekday != target_weekday:
                    continue

                # Parse times
                try:
                    start_time = _parse_time(row_start)
                    end_time = _parse_time(row_end)
                except ValueError as e:
                    logger.warning("Bad time format in row %d: %s", row_num, e)
                    continue

                start_dt = datetime.combine(target_date, start_time)
                end_dt = datetime.combine(target_date, end_time)

                if end_dt <= start_dt:
                    logger.warning("end <= start in row %d, skipping", row_num)
                    continue

                sessions.append({
                    "subject": row_subject,
                    "start": start_dt,
                    "end": end_dt,
                    "priority": "high",
                })
                logger.info(
                    "  Parsed: '%s' %s → %s",
                    row_subject,
                    start_dt.strftime("%H:%M"),
                    end_dt.strftime("%H:%M"),
                )

    except Exception as e:
        logger.error("Failed to parse CSV schedule '%s': %s", file_path, e)
        raise ValueError(f"Failed to parse CSV schedule: {e}")

    # Sort by start time
    sessions.sort(key=lambda s: s["start"])
    logger.info("Total sessions parsed for %s: %d", target_date.isoformat(), len(sessions))

    return sessions


def _parse_time(time_str: str) -> time:
    """Parse a time string like '08:00', '8:00', '08:00:00'."""
    time_str = time_str.strip()
    for fmt in ("%H:%M", "%H:%M:%S", "%Hh%M"):
        try:
            return datetime.strptime(time_str, fmt).time()
        except ValueError:
            continue
    raise ValueError(f"Cannot parse time: '{time_str}'")
