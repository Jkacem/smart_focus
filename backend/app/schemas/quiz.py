"""
Pydantic schemas for the Quiz feature.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ══════════════════════════════════════════════
# REQUEST SCHEMAS
# ══════════════════════════════════════════════

class QuizGenerateRequest(BaseModel):
    """Request body for POST /quiz/generate."""
    document_id: int
    num_questions: int = Field(default=10, ge=3, le=30,
                               description="Number of QCM questions to generate (3–30)")


class QuizAnswerRequest(BaseModel):
    """Request body for POST /quiz/{quiz_id}/submit."""
    answers: List[int] = Field(..., description="List of user-selected option indices (0–3), same order as questions")


# ══════════════════════════════════════════════
# RESPONSE SCHEMAS
# ══════════════════════════════════════════════

class QuizQuestionOut(BaseModel):
    """A single QCM question returned to the client."""
    id: int
    question_text: str
    options: List[str]
    correct_index: Optional[int] = None       # hidden during quiz, shown after submit
    explanation: Optional[str] = None
    user_answer_index: Optional[int] = None

    class Config:
        from_attributes = True


class QuizOut(BaseModel):
    """Full quiz with questions."""
    id: int
    document_id: int
    title: str
    num_questions: int
    score: Optional[int] = None
    completed_at: Optional[datetime] = None
    created_at: datetime
    questions: List[QuizQuestionOut] = []

    class Config:
        from_attributes = True


class QuizResultOut(BaseModel):
    """Returned after submitting quiz answers."""
    quiz_id: int
    score: int
    total: int
    percentage: float
    questions: List[QuizQuestionOut]
