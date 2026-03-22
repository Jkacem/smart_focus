# backend/crud.py
"""Utility functions for creating, reading, updating and deleting
SQLAlchemy models used by the FastAPI routers.
These functions are deliberately simple – they can be expanded
with pagination, filtering, error handling, etc. as the project grows.
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from . import models, schemas

# ---------- USER ----------

def get_user(db: Session, user_id: int) -> Optional[models.User]:
    """Return a single User by its primary key or ``None`` if not found."""
    return db.query(models.User).filter(models.User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """Lookup a user by e‑mail – useful for login/registration flows."""
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, user_in: schemas.UserCreate) -> models.User:
    """Create a new ``User`` record.
    The password is expected to be plain‑text in ``user_in.password`` –
    we hash it before persisting.
    """
    # Simple hashing example – replace with a proper password‑hashing lib
    import hashlib
    hashed = hashlib.sha256(user_in.password.encode()).hexdigest()
    db_user = models.User(
        email=user_in.email,
        full_name=user_in.full_name,
        hashed_password=hashed,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# ---------- TASK ----------

def get_task(db: Session, task_id: int) -> Optional[models.Task]:
    """Retrieve a single Task by its ID."""
    return db.query(models.Task).filter(models.Task.id == task_id).first()


def get_tasks_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[models.Task]:
    """Return a list of tasks belonging to a user, with optional pagination."""
    return (
        db.query(models.Task)
        .filter(models.Task.owner_id == user_id)
        .offset(skip)
        .limit(limit)
        .all()
    )


def create_task(db: Session, task_in: schemas.TaskCreate) -> models.Task:
    """Create a new Task linked to its owner.
    ``task_in.owner_id`` must reference an existing ``User``.
    """
    db_task = models.Task(
        title=task_in.title,
        description=task_in.description,
        status=task_in.status,
        due_date=task_in.due_date,
        owner_id=task_in.owner_id,
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


def update_task(db: Session, task: models.Task, updates: schemas.TaskBase) -> models.Task:
    """Apply mutable fields from ``updates`` onto an existing ``Task`` instance.
    Only non‑``None`` values are written.
    """
    for field, value in updates.dict(exclude_unset=True).items():
        setattr(task, field, value)
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


def delete_task(db: Session, task: models.Task) -> None:
    """Remove a task from the database."""
    db.delete(task)
    db.commit()

# ---------- SESSION (optional example) ----------

def create_session(db: Session, user_id: int) -> models.Session:
    """Create a new login/session record for a user."""
    from datetime import datetime
    db_session = models.Session(user_id=user_id, started_at=datetime.utcnow())
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session

# Add more CRUD helpers as needed (e.g., for Tag, etc.)
