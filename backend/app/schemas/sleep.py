# backend/app/schemas/sleep.py
"""
Pydantic schemas for sleep tracking and alarm configuration.
"""

from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, Field


# ══════════════════════════════════════════════
# SLEEP RECORD
# ══════════════════════════════════════════════

class SleepLogCreate(BaseModel):
    sleep_start: datetime
    sleep_end: Optional[datetime] = None
    deep_sleep_hours: Optional[float] = Field(None, ge=0)
    light_sleep_hours: Optional[float] = Field(None, ge=0)
    raw_sensor_data: Optional[dict] = None


class SleepLogResponse(BaseModel):
    id: int
    user_id: int
    sleep_start: datetime
    sleep_end: Optional[datetime]
    total_hours: Optional[float]
    deep_sleep_hours: Optional[float]
    light_sleep_hours: Optional[float]
    sleep_score: Optional[int]
    raw_sensor_data: Optional[dict]
    created_at: datetime

    class Config:
        from_attributes = True


# ══════════════════════════════════════════════
# STATS
# ══════════════════════════════════════════════

class SleepStatsResponse(BaseModel):
    period: str                     # e.g. "week"
    avg_hours: float
    score_avg: Optional[float]
    trend: str                      # "improving", "stable", "declining"
    num_records: int


# ══════════════════════════════════════════════
# ALARM CONFIG
# ══════════════════════════════════════════════

class AlarmConfigUpdate(BaseModel):
    alarm_time: str = Field(..., pattern=r"^\d{2}:\d{2}$", description="HH:MM format")
    is_active: Optional[bool] = True
    wake_mode: Literal["gradual", "normal", "silent"] = "gradual"
    light_intensity: int = Field(50, ge=0, le=100)
    sound_enabled: Optional[bool] = True


class AlarmConfigResponse(BaseModel):
    id: int
    user_id: int
    alarm_time: str
    is_active: bool
    wake_mode: str
    light_intensity: int
    sound_enabled: bool

    class Config:
        from_attributes = True
