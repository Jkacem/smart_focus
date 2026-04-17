# backend/schemas/user.py
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, Any


# ── User ──

class UserBase(BaseModel):
    email: EmailStr
    full_name: str


class UserCreate(UserBase):
    password: str
    role: str = "student"


class UserRead(UserBase):
    id: int
    role: str
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── UserProfile ──

class UserProfileCreate(BaseModel):
    daily_focus_goal: int = 120
    preferred_schedule: str = "morning"
    notif_enabled: bool = True
    notif_preferences: Optional[Any] = None


class UserProfileRead(BaseModel):
    id: int
    user_id: int
    daily_focus_goal: int
    preferred_schedule: str
    avatar_data_url: Optional[str] = None
    notif_enabled: bool
    notif_preferences: Optional[Any] = None
    updated_at: datetime

    class Config:
        from_attributes = True


class UserProfileUpdate(BaseModel):
    daily_focus_goal: Optional[int] = None
    preferred_schedule: Optional[str] = None
    avatar_data_url: Optional[str] = None
    notif_enabled: Optional[bool] = None
    notif_preferences: Optional[Any] = None


class CurrentUserProfileRead(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    role: str
    daily_focus_goal: int
    preferred_schedule: str
    avatar_data_url: Optional[str] = None
    notif_enabled: bool
    notif_preferences: Optional[Any] = None
    updated_at: datetime


class CurrentUserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    role: Optional[str] = None
    daily_focus_goal: Optional[int] = None
    preferred_schedule: Optional[str] = None
    avatar_data_url: Optional[str] = None
    notif_enabled: Optional[bool] = None
    notif_preferences: Optional[Any] = None


# ── Auth request/response ──

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class GoogleAuthRequest(BaseModel):
    id_token: str
    role: Optional[str] = None
