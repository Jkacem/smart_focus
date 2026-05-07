"""
Configuration de l'application Smart Focus & Life Assistant.
Charge les variables d'environnement depuis le fichier .env
"""

from pydantic_settings import BaseSettings
from typing import List, Optional


class Settings(BaseSettings):
    # ── Base de données ──
    DATABASE_URL: str  # required — set in .env

    # ── JWT ──
    SECRET_KEY: str    # required — set in .env (generate with: openssl rand -hex 32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ── Serveur ──
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = False

    # ── CORS ──
    # Comma-separated list of allowed origins.
    # Example: "http://localhost:3000,https://smartfocus.app"
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080,http://localhost:8000"

    @property
    def cors_origins_list(self) -> List[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    # ── Google Gemini (RAG Chatbot) ──
    AI_PROVIDER: str = "gemini"
    GOOGLE_API_KEY: Optional[str] = None
    GROQ_API_KEY: Optional[str] = None
    GROQ_MODEL: str = "llama-3.3-70b-versatile"
    GEMINI_MODEL: str = "gemini-2.5-flash"
    LLM_MAX_RPM: int = 25
    # Comma-separated OAuth client IDs allowed to exchange Google id_token.
    # Example: "xxx.apps.googleusercontent.com,yyy.apps.googleusercontent.com"
    GOOGLE_OAUTH_CLIENT_IDS: Optional[str] = None

    # ── Pi Client ──
    # Shared secret sent by the Raspberry Pi in: Authorization: Bearer <PI_API_KEY>
    # Generate with: openssl rand -hex 32
    PI_API_KEY: Optional[str] = None

    # ── RAG Storage ──
    CHROMA_DB_PATH: str = "chroma_db"
    UPLOADS_DIR: str = "uploads"
    MAX_UPLOAD_MB: int = 20  # maximum file upload size in megabytes

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
