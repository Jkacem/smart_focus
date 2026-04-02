"""
SQLAlchemy database configuration and lightweight compatibility patches.
"""

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def ensure_schema_compatibility() -> None:
    """Apply tiny runtime schema patches for existing developer databases."""
    inspector = inspect(engine)
    if not inspector.has_table("study_sessions"):
        return

    study_session_columns = {
        column["name"] for column in inspector.get_columns("study_sessions")
    }
    document_fk_exists = any(
        fk.get("constrained_columns") == ["document_id"]
        for fk in inspector.get_foreign_keys("study_sessions")
    )

    with engine.begin() as connection:
        if "document_id" not in study_session_columns:
            connection.execute(text("ALTER TABLE study_sessions ADD COLUMN document_id INTEGER"))

        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_study_sessions_document_id "
                "ON study_sessions (document_id)"
            )
        )

        if engine.dialect.name == "postgresql" and not document_fk_exists:
            connection.execute(
                text(
                    "ALTER TABLE study_sessions "
                    "ADD CONSTRAINT fk_study_sessions_document_id "
                    "FOREIGN KEY (document_id) REFERENCES chat_documents (id) "
                    "ON DELETE SET NULL"
                )
            )
