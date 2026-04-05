"""
Pydantic schemas for quiz generation and submission.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class QuizGenerateRequest(BaseModel):
    """Request body for POST /quiz/generate."""

    document_id: Optional[int] = None
    document_ids: List[int] = Field(default_factory=list)
    num_questions: int = Field(
        default=10,
        ge=3,
        le=30,
        description="Number of MCQ questions to generate (3-30)",
    )

    @property
    def resolved_document_ids(self) -> List[int]:
        ids: List[int] = []
        if self.document_id is not None:
            ids.append(self.document_id)
        ids.extend(self.document_ids)

        unique_ids: List[int] = []
        seen: set[int] = set()
        for document_id in ids:
            if document_id in seen:
                continue
            seen.add(document_id)
            unique_ids.append(document_id)
        return unique_ids


class SessionQuizGenerateRequest(BaseModel):
    """Request body for POST /quiz/generate-from-session/{session_id}."""

    num_questions: int = Field(
        default=10,
        ge=3,
        le=30,
        description="Number of MCQ questions to generate (3-30)",
    )


class QuizAnswerRequest(BaseModel):
    """Request body for POST /quiz/{quiz_id}/submit."""

    answers: List[int] = Field(
        ...,
        description="User-selected option indices in the same order as the quiz questions",
    )


class QuizQuestionOut(BaseModel):
    """A single quiz question returned to the client."""

    id: int
    question_text: str
    options: List[str]
    correct_index: Optional[int] = None
    explanation: Optional[str] = None
    user_answer_index: Optional[int] = None

    class Config:
        from_attributes = True


class QuizOut(BaseModel):
    """A quiz with its questions."""

    id: int
    document_id: Optional[int] = None
    document_ids: List[int] = []
    document_names: List[str] = []
    session_id: Optional[int] = None
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
