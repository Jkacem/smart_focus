# backend/app/routers/sleep.py
"""
Router for sleep tracking and alarm configuration.
All endpoints require authentication.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app import crud, schemas
from app.deps import get_current_user, get_db
from app.models.models import User

router = APIRouter(
    prefix="/api/v1/sleep",
    tags=["Sommeil"],
)


# ─────────────────────────────────────────────
# POST /log  – Enregistrer une nuit de sommeil
# ─────────────────────────────────────────────
@router.post("/log", response_model=schemas.SleepLogResponse, status_code=201)
def log_sleep(
    body: schemas.SleepLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Log a night's sleep for the authenticated user.
    Returns the created record with a computed `sleep_score`.
    """
    if body.sleep_end and body.sleep_end <= body.sleep_start:
        raise HTTPException(status_code=422, detail="sleep_end must be after sleep_start")

    record = crud.create_sleep_record(db, current_user.id, body)
    return record


# ─────────────────────────────────────────────
# GET /stats  – Statistiques de sommeil
# ─────────────────────────────────────────────
@router.get("/stats", response_model=schemas.SleepStatsResponse)
def sleep_stats(
    period: str = Query("week", pattern="^(week|month)$", description="week or month"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Return aggregated sleep stats (avg_hours, score_avg, trend) for the specified period.
    """
    stats = crud.get_sleep_stats(db, current_user.id, period)
    return stats


# ─────────────────────────────────────────────
# GET /history  – Historique des nuits
# ─────────────────────────────────────────────
@router.get("/history", response_model=List[schemas.SleepLogResponse])
def sleep_history(
    limit: int = Query(30, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Return the user's sleep history (most recent first).
    """
    return crud.get_sleep_history(db, current_user.id, limit)


# ─────────────────────────────────────────────
# PUT /alarm  – Configurer le réveil
# ─────────────────────────────────────────────
@router.put("/alarm", response_model=schemas.AlarmConfigResponse)
def update_alarm(
    body: schemas.AlarmConfigUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Create or replace the smart alarm configuration for the authenticated user.
    """
    alarm = crud.upsert_alarm_config(db, current_user.id, body)
    return alarm


# ─────────────────────────────────────────────
# GET /alarm  – Configuration actuelle
# ─────────────────────────────────────────────
@router.get("/alarm", response_model=schemas.AlarmConfigResponse)
def get_alarm(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Return the current smart alarm configuration of the authenticated user.
    """
    alarm = crud.get_alarm_config(db, current_user.id)
    if alarm is None:
        raise HTTPException(status_code=404, detail="No alarm configured yet")
    return alarm
