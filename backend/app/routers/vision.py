"""Vision/monitoring ingestion endpoints for the pi_client."""

from datetime import timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud, schemas
from app.deps import get_db

router = APIRouter(prefix="/api/v1", tags=["Vision"])


@router.post("/vision/snapshots", status_code=status.HTTP_201_CREATED)
def create_snapshot(
    payload: schemas.SnapshotCreate,
    db: Session = Depends(get_db),
):
    """Ingest a real-time CV snapshot payload."""
    snapshot = crud.create_snapshot(db, payload)
    return {"status": "ok", "id": snapshot.id}


@router.post("/vision/events", status_code=status.HTTP_201_CREATED)
def create_event(
    payload: schemas.EventCreate,
    db: Session = Depends(get_db),
):
    """Ingest a real-time CV discrete event payload."""
    focus_event = crud.create_focus_event(db, payload)
    return {"status": "ok", "id": focus_event.id}


@router.post("/sessions", response_model=schemas.WorkSessionOut)
def create_session(
    payload: schemas.WorkSessionCreate,
    db: Session = Depends(get_db),
):
    """Create or ensure the CV work session exists."""
    session_obj = crud.get_work_session(db, payload.id)
    if session_obj:
        return session_obj

    session_obj = crud.create_work_session(
        db,
        session_id=payload.id,
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


@router.get("/sessions", response_model=list[schemas.WorkSessionOut])
def list_sessions(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """List CV work sessions."""
    return crud.list_work_sessions(db, skip=skip, limit=limit)


@router.get("/sessions/{session_id}/latest", response_model=schemas.SnapshotOut)
def get_latest_snapshot(
    session_id: str,
    db: Session = Depends(get_db),
):
    """Fetch the most recent snapshot for a session."""
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
):
    """Finalize a session and persist final summary metrics."""
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
