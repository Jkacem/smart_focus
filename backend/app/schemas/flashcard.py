"""
Pydantic schemas for the Flashcard feature (with SM-2 spaced repetition).
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ══════════════════════════════════════════════
# REQUEST SCHEMAS
# ══════════════════════════════════════════════

class FlashcardGenerateRequest(BaseModel):
    """Request body for POST /flashcards/generate."""
    document_id: int
    num_cards: int = Field(default=15, ge=5, le=50,
                           description="Number of flashcards to generate (5–50)")


class FlashcardReviewRequest(BaseModel):
    """Request body for POST /flashcards/{card_id}/review."""
    quality: int = Field(..., ge=0, le=5,
                         description="SM-2 quality rating: 0=Blackout, 3=Correct, 5=Perfect")


# ══════════════════════════════════════════════
# RESPONSE SCHEMAS
# ══════════════════════════════════════════════

class FlashcardOut(BaseModel):
    """A single flashcard returned to the client."""
    id: int
    front: str
    back: str
    ease_factor: float
    interval: int
    next_review: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class FlashcardDeckOut(BaseModel):
    """A deck of flashcards for a specific document."""
    document_id: int
    document_name: str
    total_cards: int
    due_cards: int
    cards: List[FlashcardOut]
