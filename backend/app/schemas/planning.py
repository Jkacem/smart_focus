"""
Pydantic schemas for the Planning feature.
"""

from datetime import date, datetime
from typing import Optional, Literal, Any

from pydantic import BaseModel, Field


PlanningPreferences = dict[str, Any]


class ExamCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    exam_date: date
    document_id: Optional[int] = None


class ExamOut(BaseModel):
    id: int
    user_id: int
    title: str
    exam_date: date
    document_id: Optional[int] = None
    document_name: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlanningGenerateRequest(BaseModel):
    date: date
    preferences: Optional[PlanningPreferences] = None
    document_id: Optional[int] = None
    exam_ids: Optional[list[int]] = None
    week_type: Optional[Literal["A", "B"]] = None  # For Week A/B alternation; auto-detected if omitted


StudySessionPriority = Literal["low", "medium", "high"]
StudySessionStatus = Literal["pending", "in_progress", "completed", "cancelled"]


class StudySessionCreate(BaseModel):
    subject: str = Field(..., min_length=1, max_length=255)
    start: datetime
    end: datetime
    priority: StudySessionPriority = "medium"
    document_id: Optional[int] = None
    document_ids: Optional[list[int]] = None


class StudySessionUpdate(BaseModel):
    status: Optional[StudySessionStatus] = None
    notes: Optional[str] = Field(default=None, max_length=2000)
    document_id: Optional[int] = None
    document_ids: Optional[list[int]] = None


class PlanningOut(BaseModel):
    date: date


class StudySessionOut(BaseModel):
    id: int
    user_id: int
    date: date
    subject: str
    start: datetime
    end: datetime
    priority: StudySessionPriority
    status: StudySessionStatus
    notes: Optional[str]
    is_ai_generated: bool
    completed_at: Optional[datetime]
    document_id: Optional[int] = None
    document_name: Optional[str] = None
    document_ids: list[int] = []
    document_names: list[str] = []
    session_quiz_id: Optional[int] = None
    session_quiz_status: str = "not_started"
    session_flashcards_total: int = 0
    session_flashcards_due: int = 0
    session_flashcards_reviewed: int = 0
    session_flashcards_status: str = "not_started"
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlanningDayOut(BaseModel):
    planning: PlanningOut
    sessions: list[StudySessionOut]


class PlanningWeekOut(BaseModel):
    week_start: date
    week_end: date
    days: list[PlanningDayOut]


PlanningInsightsPeriod = Literal["week", "month"]


class PlanningInsightsOut(BaseModel):
    period: PlanningInsightsPeriod
    total_study_minutes: int
    completed_sessions: int
    skipped_sessions: int
    completion_rate: float
    avg_sleep_hours: Optional[float] = None
    avg_sleep_score: Optional[float] = None
    sleep_study_correlation: str
    weakest_subject: Optional[str] = None
    strongest_subject: Optional[str] = None
    recommendation: str

