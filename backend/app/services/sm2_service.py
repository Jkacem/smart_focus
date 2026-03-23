"""
SM-2 Spaced Repetition Algorithm.

Based on the SuperMemo SM-2 algorithm used in the SmartFocus flashcard system.
Reference: Conception_Flux_RAG_Chatbot.md — Section 5 (Review Cycle).

Quality ratings:
    0 = Blackout (complete failure)
    1 = Incorrect, but recognized the answer
    2 = Incorrect, but seemed easy to recall
    3 = Correct, with serious difficulty
    4 = Correct, with some hesitation
    5 = Perfect response
"""

from datetime import datetime, timedelta
from typing import Tuple


def sm2_update(
    quality: int,
    repetitions: int,
    ease_factor: float,
    interval: int,
) -> Tuple[int, float, int, datetime]:
    """
    Apply SM-2 algorithm to compute next review parameters.

    Args:
        quality:     User rating 0–5
        repetitions: Number of consecutive correct reviews
        ease_factor: Current ease factor (minimum 1.3)
        interval:    Current interval in days

    Returns:
        Tuple of (new_repetitions, new_ease_factor, new_interval, next_review_date)
    """
    if quality < 3:
        # Failed — reset to beginning
        new_repetitions = 0
        new_interval = 1
    else:
        # Correct — increase interval
        new_repetitions = repetitions + 1
        if new_repetitions == 1:
            new_interval = 1
        elif new_repetitions == 2:
            new_interval = 6
        else:
            new_interval = round(interval * ease_factor)

    # Update ease factor (always, even on failure)
    new_ease_factor = ease_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    new_ease_factor = max(1.3, new_ease_factor)  # never drop below 1.3

    next_review = datetime.utcnow() + timedelta(days=new_interval)

    return new_repetitions, new_ease_factor, new_interval, next_review
