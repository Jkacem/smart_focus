"""
Pydantic schemas for flashcard generation and review.
"""

from datetime import datetime
from typing import List

from pydantic import BaseModel, Field


class FlashcardGenerateRequest(BaseModel):
    """Request body for POST /flashcards/generate."""

    document_id: int
    num_cards: int = Field(
        default=15,
        ge=5,
        le=50,
        description="Number of flashcards to generate (5-50)",
    )


class SessionFlashcardGenerateRequest(BaseModel):
    """Request body for POST /flashcards/generate-from-session/{session_id}."""

    num_cards: int = Field(
        default=15,
        ge=5,
        le=50,
        description="Number of flashcards to generate (5-50)",
    )


class FlashcardReviewRequest(BaseModel):
    """Request body for POST /flashcards/{card_id}/review."""

    quality: int = Field(
        ...,
        ge=0,
        le=5,
        description="SM-2 quality rating where 0 is blackout and 5 is perfect recall",
    )


class FlashcardOut(BaseModel):
    """A single flashcard returned to the client."""

    id: int
    front: str
    back: str
    ease_factor: float
    interval: int
    repetitions: int
    next_review: datetime
    created_at: datetime
    source_session_id: int | None = None

    class Config:
        from_attributes = True


class FlashcardDeckOut(BaseModel):
    """A deck of flashcards for one document."""

    document_id: int
    document_name: str
    session_id: int | None = None
    session_subject: str | None = None
    total_cards: int
    due_cards: int
    reviewed_cards: int = 0
    cards: List[FlashcardOut]
