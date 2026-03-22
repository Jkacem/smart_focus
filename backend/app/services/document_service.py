"""
Document Service — File management helpers for the RAG chatbot.

Responsibilities:
  - Save uploaded files to disk (uploads/{user_id}/)
  - Provide path helpers for the RAG service
"""

import os
import uuid
from pathlib import Path
from fastapi import UploadFile

from app.config import settings


def _uploads_root() -> Path:
    """Absolute path to the uploads root directory."""
    base = Path(settings.UPLOADS_DIR)
    if not base.is_absolute():
        base = Path(__file__).resolve().parent.parent.parent / settings.UPLOADS_DIR
    return base


def save_upload(file: UploadFile, user_id: int) -> tuple[str, str]:
    """
    Persist an uploaded PDF to disk.

    Args:
        file:    The FastAPI UploadFile object.
        user_id: The ID of the authenticated user (used as subfolder).

    Returns:
        (file_path, collection_name)
            file_path       — absolute path where the file was saved
            collection_name — unique ChromaDB collection identifier
    """
    user_dir = _uploads_root() / str(user_id)
    user_dir.mkdir(parents=True, exist_ok=True)

    # Generate a unique collection name (safe for ChromaDB)
    collection_name = f"user{user_id}_{uuid.uuid4().hex[:12]}"

    # Keep original filename but prefix with collection_name to avoid collisions
    safe_filename = f"{collection_name}_{file.filename}"
    file_path = user_dir / safe_filename

    content = file.file.read()
    with open(file_path, "wb") as f:
        f.write(content)

    return str(file_path), collection_name


def delete_file(file_path: str) -> None:
    """Remove a document file from disk if it exists."""
    try:
        path = Path(file_path)
        if path.exists():
            path.unlink()
    except Exception:
        pass  # Best-effort deletion
