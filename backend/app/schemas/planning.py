"""
Pydantic schemas for the Planning feature.
"""

from datetime import date, datetime
from typing import Optional, Literal, Any

from pydantic import BaseModel, Field


PlanningPreferences = dict[str, Any]


class PlanningGenerateRequest(BaseModel):
    date: date
    preferences: Optional[PlanningPreferences] = None
    document_id: Optional[int] = None
    week_type: Optional[Literal["A", "B"]] = None  # For Week A/B alternation; auto-detected if omitted


StudySessionPriority = Literal["low", "medium", "high"]
StudySessionStatus = Literal["pending", "in_progress", "completed", "cancelled"]


class StudySessionCreate(BaseModel):
    subject: str = Field(..., min_length=1, max_length=255)
    start: datetime
    end: datetime
    priority: StudySessionPriority = "medium"


class StudySessionUpdate(BaseModel):
    status: Optional[StudySessionStatus] = None
    notes: Optional[str] = Field(default=None, max_length=2000)


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
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlanningDayOut(BaseModel):
    planning: PlanningOut
    sessions: list[StudySessionOut]

