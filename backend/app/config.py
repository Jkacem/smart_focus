"""
Configuration de l'application Smart Focus & Life Assistant.
Charge les variables d'environnement depuis le fichier .env
"""

from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    # ── Base de données ──
    DATABASE_URL: str = "postgresql://postgres:kacem123@localhost:5432/smartFocus_db"

    # ── JWT ──
    SECRET_KEY: str = "your-super-secret-key-change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ── Serveur ──
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True

    # ── Google Gemini (RAG Chatbot) ──
    GOOGLE_API_KEY: Optional[str] = None
    # Comma-separated OAuth client IDs allowed to exchange Google id_token.
    # Example: "xxx.apps.googleusercontent.com,yyy.apps.googleusercontent.com"
    GOOGLE_OAUTH_CLIENT_IDS: Optional[str] = None

    # ── RAG Storage ──
    CHROMA_DB_PATH: str = "chroma_db"
    UPLOADS_DIR: str = "uploads"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
