"""Vision/monitoring ingestion endpoints for the pi_client."""

from datetime import timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app import crud, schemas
from app.deps import get_current_user, get_current_user_optional, get_db
from app.models.models import User

router = APIRouter(prefix="/api/v1", tags=["Vision"])


# ── Ingestion endpoints (pi_client, no auth required) ──────────────

@router.post("/vision/snapshots", status_code=status.HTTP_201_CREATED)
def create_snapshot(
    payload: schemas.SnapshotCreate,
    db: Session = Depends(get_db),
):
    """Ingest a real-time CV snapshot payload (called by pi_client)."""
    snapshot = crud.create_snapshot(db, payload)
    return {"status": "ok", "id": snapshot.id}


@router.post("/vision/events", status_code=status.HTTP_201_CREATED)
def create_event(
    payload: schemas.EventCreate,
    db: Session = Depends(get_db),
):
    """Ingest a real-time CV discrete event payload (called by pi_client)."""
    focus_event = crud.create_focus_event(db, payload)
    return {"status": "ok", "id": focus_event.id}


@router.post("/sessions", response_model=schemas.WorkSessionOut)
def create_session(
    payload: schemas.WorkSessionCreate,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    """Create or ensure the CV work session exists (called by pi_client).

    If the session already exists, its metadata is merged with the
    incoming payload so that re-registration never silently drops
    new keys (e.g. a ``planning_session_id`` added after restart).
    """
    session_obj = crud.get_work_session(db, payload.id)
    if session_obj:
        # Claim unassigned sessions when a logged-in user starts from mobile.
        if current_user is not None and session_obj.user_id is None:
            session_obj.user_id = current_user.id
        if (
            current_user is not None
            and session_obj.user_id is not None
            and session_obj.user_id != current_user.id
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Session does not belong to the current user.",
            )
        # Merge incoming metadata into existing session (#5)
        if payload.metadata_json:
            merged = dict(session_obj.metadata_json or {})
            merged.update(payload.metadata_json)
            session_obj.metadata_json = merged
            db.commit()
            db.refresh(session_obj)
        return session_obj

    session_obj = crud.create_work_session(
        db,
        session_id=payload.id,
        user_id=current_user.id if current_user is not None else None,
        metadata_json=payload.metadata_json,
    )
    if payload.start_time is not None:
        start_time = payload.start_time
        if start_time.tzinfo is not None:
            start_time = start_time.astimezone(timezone.utc).replace(tzinfo=None)
        session_obj.start_time = start_time
        db.commit()
        db.refresh(session_obj)
    return session_obj


# ── Authenticated endpoints (mobile app) ───────────────────────────

@router.get("/sessions", response_model=list[schemas.WorkSessionOut])
def list_sessions(
    skip: int = 0,
    limit: int = Query(default=100, le=500),
    include_unassigned_active: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List CV work sessions for the authenticated user."""
    return crud.list_work_sessions(
        db,
        user_id=current_user.id,
        skip=skip,
        limit=limit,
        include_unassigned_active=include_unassigned_active,
    )


@router.get("/sessions/{session_id}/latest", response_model=schemas.SnapshotOut)
def get_latest_snapshot(
    session_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Fetch the most recent snapshot for a session."""
    session_obj = crud.get_work_session(db, session_id)
    if session_obj is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found.",
        )
    if session_obj.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Session does not belong to the current user.",
        )

    snapshot = crud.get_latest_snapshot(db, session_id)
    if snapshot is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No snapshots found for this session.",
        )
    return snapshot


@router.post("/sessions/{session_id}/finalize", response_model=schemas.WorkSessionOut)
def finalize_session(
    session_id: str,
    payload: schemas.SessionFinalizePayload,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    """Finalize a session and persist final summary metrics."""
    existing_session = crud.get_work_session(db, session_id)
    if existing_session is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found.",
        )
    if current_user is not None:
        if existing_session.user_id not in (None, current_user.id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Session does not belong to the current user.",
            )
        if existing_session.user_id is None:
            existing_session.user_id = current_user.id
            db.commit()
    else:
        metadata = existing_session.metadata_json or {}
        allow_unauth_finalize = bool(metadata.get("allow_unauth_finalize"))
        if not allow_unauth_finalize:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication required to finalize this session.",
            )

    session_obj = crud.finalize_work_session(
        db,
        session_id=session_id,
        summary_data=payload.model_dump(),
    )
    if session_obj is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found.",
        )
    return session_obj
