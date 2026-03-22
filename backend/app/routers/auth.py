# backend/routers/auth.py
"""
Authentication endpoints – register, login, refresh, me.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud, schemas
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


# ── Me / Profile (update) ──

@router.put("/me/profile", response_model=schemas.UserProfileRead)
def update_my_profile(
    updates: schemas.UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the current user's profile preferences."""
    profile = crud.get_user_profile(db, current_user.id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return crud.update_user_profile(db, profile, updates)


# ── helper ──

def _build_tokens(email: str) -> dict:
    data = {"sub": email}
    return {
        "access_token": create_access_token(data),
        "refresh_token": create_refresh_token(data),
        "token_type": "bearer",
    }
