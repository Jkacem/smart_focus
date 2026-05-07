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


_CHUNK_SIZE = 64 * 1024  # 64 KB read chunks


def save_upload(file: UploadFile, user_id: int) -> tuple[str, str]:
    """
    Persist an uploaded file to disk, enforcing the MAX_UPLOAD_MB size limit.

    Raises:
        ValueError: if the file exceeds settings.MAX_UPLOAD_MB.

    Returns:
        (file_path, collection_name)
    """
    max_bytes = settings.MAX_UPLOAD_MB * 1024 * 1024

    user_dir = _uploads_root() / str(user_id)
    user_dir.mkdir(parents=True, exist_ok=True)

    collection_name = f"user{user_id}_{uuid.uuid4().hex[:12]}"
    safe_filename = f"{collection_name}_{file.filename}"
    file_path = user_dir / safe_filename

    # Read in chunks so we never buffer more than max_bytes + one chunk in RAM.
    content = bytearray()
    while True:
        chunk = file.file.read(_CHUNK_SIZE)
        if not chunk:
            break
        content.extend(chunk)
        if len(content) > max_bytes:
            raise ValueError(
                f"File exceeds the {settings.MAX_UPLOAD_MB} MB upload limit."
            )

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
