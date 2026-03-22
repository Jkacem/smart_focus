"""
Smart Focus & Life Assistant - Backend API
Point d'entrée principal de l'application FastAPI.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

# ── Créer l'application FastAPI ──
app = FastAPI(
    title="Smart Focus & Life Assistant API",
    description="API Backend pour l'assistant intelligent de concentration et bien-être",
    version="1.0.0",
    docs_url="/docs",       # Swagger UI
    redoc_url="/redoc",     # ReDoc
)

# ── Créer les tables au démarrage (pour le dev sans migrations pour le moment) ──
from app.models import Base
from app.database import engine
Base.metadata.create_all(bind=engine)

# ── Middleware CORS (pour que Flutter puisse communiquer) ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En prod, mettre l'URL de l'app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Route de test ──
@app.get("/", tags=["Health"])
def root():
    """Vérifier que l'API fonctionne."""
    return {
        "message": "🚀 Smart Focus API is running!",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


# ── Inclure les routeurs ──
from app.routers import auth, users, chatbot
import os

# Create storage directories on startup
os.makedirs(os.getenv("UPLOADS_DIR", "uploads"), exist_ok=True)
os.makedirs(os.getenv("CHROMA_DB_PATH", "chroma_db"), exist_ok=True)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(chatbot.router)
