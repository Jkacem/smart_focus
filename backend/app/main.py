"""
Smart Focus & Life Assistant - Backend API
Point d'entrée principal de l'application FastAPI.
"""

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine, ensure_schema_compatibility
from app.models import Base
from app.routers import auth, users, chatbot, quiz, flashcard, sleep, planning, vision

# ── Créer les tables au démarrage (pour le dev sans migrations pour le moment) ──
Base.metadata.create_all(bind=engine)
ensure_schema_compatibility()

# ── Créer l'application FastAPI ──
app = FastAPI(
    title="Smart Focus & Life Assistant API",
    description="API Backend pour l'assistant intelligent de concentration et bien-être",
    version="1.0.0",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# ── Middleware CORS ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Créer les répertoires de stockage au démarrage ──
os.makedirs(settings.UPLOADS_DIR, exist_ok=True)
os.makedirs(settings.CHROMA_DB_PATH, exist_ok=True)

# ── Routeurs ──
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(chatbot.router)
app.include_router(quiz.router)
app.include_router(flashcard.router)
app.include_router(sleep.router)
app.include_router(planning.router)
app.include_router(vision.router)


@app.get("/", tags=["Health"])
def root():
    """Vérifier que l'API fonctionne."""
    return {"message": "Smart Focus API is running!", "version": "1.0.0"}


@app.get("/health", tags=["Health"])
def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
