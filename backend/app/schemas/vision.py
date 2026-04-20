"""
Pydantic schemas for the CV vision / monitoring endpoints.

These match the JSON payloads sent by the pi_client's
output/api_client.py and output/json_formatter.py.
"""

from datetime import datetime
from typing import Any, List, Optional

from pydantic import BaseModel, Field


# ── Inbound (from pi_client) ──────────────────────────────


class SnapshotCreate(BaseModel):
    """Full rich snapshot payload sent by pi_client every ~0.5 s."""
    session_id: str
    timestamp: str                        # ISO format
    work_mode: str
    scores: dict
    presence: dict
    instant_observations: dict
    short_window_inference: dict
    consolidated_states: dict
    reliability: dict
    temporal_context: dict
    alert: dict
    events: List[Any] = Field(default_factory=list)


class EventCreate(BaseModel):
    """Discrete event payload (alert, mode_change, session_summary)."""
    session_id: str
    timestamp: str
    event_type: str
    level: str
    description: str
    metadata: Optional[dict] = Field(default_factory=dict)


class WorkSessionCreate(BaseModel):
    """Called once at CV session startup to register the session."""
    id: str
    start_time: Optional[datetime] = None
    metadata_json: Optional[dict] = None


class SessionFinalizePayload(BaseModel):
    """Final summary sent by the pi_client when a CV session ends."""
    session_duration: Optional[float] = None
    focus_time_ratio: Optional[float] = None
    distraction_time_ratio: Optional[float] = None
    reading_time: Optional[float] = None
    posture_quality_score: Optional[float] = None
    fatigue_level: Optional[str] = None
    final_score: Optional[float] = None
    breakdown: Optional[dict] = None


# ── Outbound (API responses) ─────────────────────────────


class WorkSessionOut(BaseModel):
    id: str
    user_id: Optional[int] = None
    start_time: datetime
    end_time: Optional[datetime] = None
    is_active: bool
    metadata_json: Optional[dict] = None

    class Config:
        from_attributes = True


class SnapshotOut(BaseModel):
    id: int
    session_id: str
    timestamp: datetime
    work_mode: Optional[str] = None
    attention_score: Optional[float] = None
    posture_score: Optional[float] = None
    vigilance_score: Optional[float] = None
    stress_risk_score: Optional[float] = None
    global_focus_score: Optional[float] = None

    class Config:
        from_attributes = True


class FocusEventOut(BaseModel):
    id: int
    session_id: str
    timestamp: datetime
    event_type: Optional[str] = None
    level: Optional[str] = None
    description: Optional[str] = None

    class Config:
        from_attributes = True
