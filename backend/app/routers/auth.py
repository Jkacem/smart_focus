# backend/routers/auth.py
"""
Authentication endpoints – register, login, refresh, me.
"""

import secrets

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from app import crud, schemas
from app.config import settings
from app.deps import get_db, get_current_user
from app.models import User
from app.utils.security import verify_password, create_access_token, create_refresh_token, decode_token
from jose import JWTError

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Register ──

@router.post(
    "/register",
    response_model=schemas.TokenResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(user_in: schemas.UserCreate, db: Session = Depends(get_db)):
    """Create a new user account and return JWT tokens."""
    # Check duplicate email
    if crud.get_user_by_email(db, user_in.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Validate role
    if user_in.role not in ("student", "teacher", "professional"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Role must be 'student', 'teacher', or 'professional'",
        )

    user = crud.create_user(db, user_in)
    crud.update_last_login(db, user)

    tokens = _build_tokens(user.email)
    return tokens


# ── Login ──

from fastapi.security import OAuth2PasswordRequestForm


@router.post("/login", response_model=schemas.TokenResponse)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """Authenticate with email + password and receive JWT tokens.

    This endpoint is compatible with the OAuth2 `password` grant used by
    `OAuth2PasswordBearer` (Swagger UI, etc.).
    """
    # OAuth2PasswordRequestForm provides `username` and `password` fields
    user = crud.get_user_by_email(db, form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )

    crud.update_last_login(db, user)
    return _build_tokens(user.email)


@router.post("/google", response_model=schemas.TokenResponse)
def google_auth(
    payload: schemas.GoogleAuthRequest,
    db: Session = Depends(get_db),
):
    """Authenticate or auto-register a user from a Google id_token."""
    google_payload = _verify_google_id_token(payload.id_token)

    email = (google_payload.get("email") or "").strip().lower()
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google token does not contain an email",
        )

    email_verified = google_payload.get("email_verified")
    if email_verified not in (True, "true", "True", 1, "1"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google account email is not verified",
        )

    user = crud.get_user_by_email(db, email)
    if not user:
        role = payload.role if payload.role in ("student", "teacher", "professional") else "student"
        full_name = (google_payload.get("name") or email.split("@")[0]).strip()
        if not full_name:
            full_name = "Google User"

        user = crud.create_user(
            db,
            schemas.UserCreate(
                email=email,
                full_name=full_name,
                password=secrets.token_urlsafe(32),
                role=role,
            ),
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )

    crud.update_last_login(db, user)
    return _build_tokens(user.email)


# ── Refresh ──

@router.post("/refresh", response_model=schemas.TokenResponse)
def refresh(body: schemas.RefreshRequest):
    """Exchange a valid refresh token for a new token pair."""
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
            )
        email: str = payload.get("sub")
        if not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    return _build_tokens(email)


# ── Me (read) ──

@router.get("/me", response_model=schemas.UserRead)
def read_me(current_user: User = Depends(get_current_user)):
    """Return the currently authenticated user."""
    return current_user


# ── Me / Profile (read/update) ──

@router.get("/me/profile", response_model=schemas.CurrentUserProfileRead)
def read_my_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return the current user and editable profile preferences in one payload."""
    profile = crud.get_user_profile(db, current_user.id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return _build_current_user_profile(current_user, profile)

@router.put("/me/profile", response_model=schemas.CurrentUserProfileRead)
def update_my_profile(
    updates: schemas.CurrentUserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the current user's account details and profile preferences."""
    profile = crud.get_user_profile(db, current_user.id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    if updates.role is not None and updates.role not in ("student", "teacher", "professional"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Role must be 'student', 'teacher', or 'professional'",
        )
    if updates.full_name is not None and not updates.full_name.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="full_name must not be empty",
        )
    user, updated_profile = crud.update_current_user_profile(
        db,
        current_user,
        profile,
        updates,
    )
    return _build_current_user_profile(user, updated_profile)


# ── helper ──

def _build_tokens(email: str) -> dict:
    data = {"sub": email}
    return {
        "access_token": create_access_token(data),
        "refresh_token": create_refresh_token(data),
        "token_type": "bearer",
    }


def _verify_google_id_token(id_token_value: str) -> dict:
    request = google_requests.Request()
    client_ids_raw = settings.GOOGLE_OAUTH_CLIENT_IDS or ""
    client_ids = [item.strip() for item in client_ids_raw.split(",") if item.strip()]

    if not client_ids:
        if not settings.DEBUG:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="GOOGLE_OAUTH_CLIENT_IDS is not configured on the backend",
            )
        try:
            payload = google_id_token.verify_oauth2_token(id_token_value, request)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Google token",
            )
        return payload

    for client_id in client_ids:
        try:
            return google_id_token.verify_oauth2_token(
                id_token_value,
                request,
                client_id,
            )
        except ValueError:
            continue

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid Google token for configured client IDs",
    )


def _build_current_user_profile(
    user: User,
    profile,
) -> schemas.CurrentUserProfileRead:
    return schemas.CurrentUserProfileRead(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        daily_focus_goal=profile.daily_focus_goal,
        preferred_schedule=profile.preferred_schedule,
        avatar_data_url=profile.avatar_data_url,
        notif_enabled=profile.notif_enabled,
        notif_preferences=profile.notif_preferences,
        updated_at=profile.updated_at,
    )
