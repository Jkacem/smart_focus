# backend/crud.py
"""
CRUD helpers for SQLAlchemy models.
"""

from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session

from . import models, schemas
from .utils.security import hash_password


# ══════════════════════════════════════════════
# USER
# ══════════════════════════════════════════════

def get_user(db: Session, user_id: int) -> Optional[models.User]:
    """Return a single User by its primary key or None."""
    return db.query(models.User).filter(models.User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """Lookup a user by email."""
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, user_in: schemas.UserCreate) -> models.User:
    """Create a new User with a hashed password and a default profile."""
    db_user = models.User(
        email=user_in.email,
        full_name=user_in.full_name,
        hashed_password=hash_password(user_in.password),
        role=user_in.role,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Auto-create a default profile
    db_profile = models.UserProfile(user_id=db_user.id)
    db.add(db_profile)
    db.commit()

    return db_user


def update_last_login(db: Session, user: models.User) -> None:
    """Set last_login to now."""
    user.last_login = datetime.utcnow()
    db.commit()


# ══════════════════════════════════════════════
# USER PROFILE
# ══════════════════════════════════════════════

def get_user_profile(db: Session, user_id: int) -> Optional[models.UserProfile]:
    """Return a user's profile."""
    return db.query(models.UserProfile).filter(
        models.UserProfile.user_id == user_id
    ).first()


def update_user_profile(
    db: Session,
    profile: models.UserProfile,
    updates: schemas.UserProfileUpdate,
) -> models.UserProfile:
    """Apply partial updates to a UserProfile."""
    for field, value in updates.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    db.commit()
    db.refresh(profile)
    return profile
