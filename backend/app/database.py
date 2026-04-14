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
    with engine.begin() as connection:
        if inspector.has_table("study_sessions"):
            study_session_columns = {
                column["name"] for column in inspector.get_columns("study_sessions")
            }
            document_fk_exists = any(
                fk.get("constrained_columns") == ["document_id"]
                for fk in inspector.get_foreign_keys("study_sessions")
            )

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

        if inspector.has_table("quizzes"):
            quiz_columns = {column["name"] for column in inspector.get_columns("quizzes")}
            quiz_session_fk_exists = any(
                fk.get("constrained_columns") == ["session_id"]
                for fk in inspector.get_foreign_keys("quizzes")
            )

            if "session_id" not in quiz_columns:
                connection.execute(text("ALTER TABLE quizzes ADD COLUMN session_id INTEGER"))

            connection.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_quizzes_session_id "
                    "ON quizzes (session_id)"
                )
            )

            if engine.dialect.name == "postgresql" and not quiz_session_fk_exists:
                connection.execute(
                    text(
                        "ALTER TABLE quizzes "
                        "ADD CONSTRAINT fk_quizzes_session_id "
                        "FOREIGN KEY (session_id) REFERENCES study_sessions (id) "
                        "ON DELETE SET NULL"
                    )
                )

        if inspector.has_table("flashcards"):
            flashcard_columns = {
                column["name"] for column in inspector.get_columns("flashcards")
            }
            flashcard_session_fk_exists = any(
                fk.get("constrained_columns") == ["source_session_id"]
                for fk in inspector.get_foreign_keys("flashcards")
            )

            if "source_session_id" not in flashcard_columns:
                connection.execute(text("ALTER TABLE flashcards ADD COLUMN source_session_id INTEGER"))

            connection.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_flashcards_source_session_id "
                    "ON flashcards (source_session_id)"
                )
            )

            if engine.dialect.name == "postgresql" and not flashcard_session_fk_exists:
                connection.execute(
                    text(
                        "ALTER TABLE flashcards "
                        "ADD CONSTRAINT fk_flashcards_source_session_id "
                        "FOREIGN KEY (source_session_id) REFERENCES study_sessions (id) "
                        "ON DELETE SET NULL"
                    )
                )

        if inspector.has_table("user_profiles"):
            profile_columns = {
                column["name"] for column in inspector.get_columns("user_profiles")
            }

            if "avatar_data_url" not in profile_columns:
                connection.execute(text("ALTER TABLE user_profiles ADD COLUMN avatar_data_url VARCHAR"))
