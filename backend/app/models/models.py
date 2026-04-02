# backend/models/models.py
from datetime import datetime, date
from enum import Enum
from sqlalchemy import (
    Column, Integer, String, DateTime, Date, Boolean,
    ForeignKey, JSON, Float,
)
from sqlalchemy.orm import relationship, declarative_base

Base = declarative_base()


# ══════════════════════════════════════════════
# AUTH / USER
# ══════════════════════════════════════════════

class UserRole(str, Enum):
    STUDENT = "student"
    TEACHER = "teacher"
    PROFESSIONAL = "professional"


class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name       = Column(String(100), nullable=False)
    role            = Column(String(20), nullable=False, default="student")
    is_active       = Column(Boolean, nullable=False, default=True)
    created_at      = Column(DateTime, nullable=False, default=datetime.utcnow)
    last_login      = Column(DateTime, nullable=True)

    # relationships
    profile = relationship("UserProfile", back_populates="user", uselist=False,
                           cascade="all, delete-orphan")
    chat_documents = relationship("ChatDocument", back_populates="user",
                                  cascade="all, delete-orphan")
    chat_messages   = relationship("ChatMessage",  back_populates="user",
                                   cascade="all, delete-orphan")
    quizzes         = relationship("Quiz",         back_populates="user",
                                   cascade="all, delete-orphan")
    flashcards      = relationship("Flashcard",    back_populates="user",
                                   cascade="all, delete-orphan")
    sleep_records   = relationship("SleepRecord",   back_populates="user",
                                   cascade="all, delete-orphan")
    smart_alarm     = relationship("SmartAlarm",    back_populates="user",
                                   uselist=False, cascade="all, delete-orphan")
    study_sessions = relationship("StudySession", back_populates="user",
                                   cascade="all, delete-orphan")


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id                 = Column(Integer, primary_key=True, index=True)
    user_id            = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"),
                                nullable=False, unique=True)
    daily_focus_goal   = Column(Integer, nullable=False, default=120)
    preferred_schedule = Column(String(50), nullable=False, default="morning")
    notif_enabled      = Column(Boolean, nullable=False, default=True)
    notif_preferences  = Column(JSON, nullable=True)
    updated_at         = Column(DateTime, nullable=False, default=datetime.utcnow,
                                onupdate=datetime.utcnow)

    # relationships
    user = relationship("User", back_populates="profile")


# ══════════════════════════════════════════════
# RAG CHATBOT
# ══════════════════════════════════════════════

class ChatDocument(Base):
    """Represents a PDF document uploaded by a user for RAG querying."""
    __tablename__ = "chat_documents"

    id                = Column(Integer, primary_key=True, index=True)
    user_id           = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"),
                               nullable=False, index=True)
    filename          = Column(String(255), nullable=False)           # original file name
    file_path         = Column(String(512), nullable=False)           # path on disk
    chroma_collection = Column(String(255), nullable=False, unique=True)  # ChromaDB collection id
    page_count        = Column(Integer, nullable=True)                # number of PDF pages
    created_at        = Column(DateTime, nullable=False, default=datetime.utcnow)

    # relationships
    user       = relationship("User", back_populates="chat_documents")
    messages   = relationship("ChatMessage", back_populates="document",
                              cascade="all, delete-orphan")
    quizzes    = relationship("Quiz",        back_populates="document",
                              cascade="all, delete-orphan")
    flashcards = relationship("Flashcard",   back_populates="document",
                              cascade="all, delete-orphan")
    study_sessions = relationship("StudySession", back_populates="document")


class ChatMessage(Base):
    """Stores each Q&A exchange in the chatbot, linked to a document."""
    __tablename__ = "chat_messages"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id",          ondelete="CASCADE"), nullable=False, index=True)
    document_id = Column(Integer, ForeignKey("chat_documents.id", ondelete="CASCADE"), nullable=True,  index=True)
    question    = Column(String(2000), nullable=False)
    answer      = Column(String(8000), nullable=False)
    sources     = Column(JSON, nullable=True)   # [{"filename": ..., "page": ..., "chunk": ...}]
    created_at  = Column(DateTime, nullable=False, default=datetime.utcnow)

    # relationships
    user     = relationship("User",         back_populates="chat_messages")
    document = relationship("ChatDocument", back_populates="messages")


# ══════════════════════════════════════════════
# QUIZ
# ══════════════════════════════════════════════

class Quiz(Base):
    """A generated quiz (QCM) linked to a user and a document."""
    __tablename__ = "quizzes"

    id            = Column(Integer, primary_key=True, index=True)
    user_id       = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"),
                           nullable=False, index=True)
    document_id   = Column(Integer, ForeignKey("chat_documents.id", ondelete="CASCADE"),
                           nullable=False, index=True)
    title         = Column(String(255), nullable=False)
    num_questions = Column(Integer, nullable=False, default=10)
    score         = Column(Integer, nullable=True)          # filled after submission
    completed_at  = Column(DateTime, nullable=True)
    created_at    = Column(DateTime, nullable=False, default=datetime.utcnow)

    # relationships
    user      = relationship("User",         back_populates="quizzes")
    document  = relationship("ChatDocument", back_populates="quizzes")
    questions = relationship("QuizQuestion", back_populates="quiz",
                             cascade="all, delete-orphan")


class QuizQuestion(Base):
    """A single QCM question within a quiz."""
    __tablename__ = "quiz_questions"

    id                = Column(Integer, primary_key=True, index=True)
    quiz_id           = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"),
                               nullable=False, index=True)
    question_text     = Column(String(2000), nullable=False)
    options           = Column(JSON, nullable=False)         # ["Option A", "Option B", "Option C", "Option D"]
    correct_index     = Column(Integer, nullable=False)      # 0-based index of correct answer
    explanation       = Column(String(2000), nullable=True)  # AI-generated explanation
    user_answer_index = Column(Integer, nullable=True)       # user's selected answer

    # relationships
    quiz = relationship("Quiz", back_populates="questions")


# ══════════════════════════════════════════════
# FLASHCARDS (with SM-2 Spaced Repetition)
# ══════════════════════════════════════════════

class Flashcard(Base):
    """A flashcard with SM-2 spaced repetition fields."""
    __tablename__ = "flashcards"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"),
                         nullable=False, index=True)
    document_id = Column(Integer, ForeignKey("chat_documents.id", ondelete="CASCADE"),
                         nullable=False, index=True)
    front       = Column(String(2000), nullable=False)       # recto (question / term)
    back        = Column(String(2000), nullable=False)       # verso (answer / definition)

    # SM-2 fields
    ease_factor = Column(Float, nullable=False, default=2.5)
    interval    = Column(Integer, nullable=False, default=1)  # days until next review
    repetitions = Column(Integer, nullable=False, default=0)
    next_review = Column(DateTime, nullable=False, default=datetime.utcnow)
    created_at  = Column(DateTime, nullable=False, default=datetime.utcnow)

    # relationships
    user     = relationship("User",         back_populates="flashcards")
    document = relationship("ChatDocument", back_populates="flashcards")


# ══════════════════════════════════════════════
# SLEEP
# ══════════════════════════════════════════════

class SleepRecord(Base):
    """Stores one night of sleep data per user."""
    __tablename__ = "sleep_records"

    id                = Column(Integer, primary_key=True, index=True)
    user_id           = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"),
                               nullable=False, index=True)
    sleep_start       = Column(DateTime, nullable=False)
    sleep_end         = Column(DateTime, nullable=True)
    total_hours       = Column(Float, nullable=True)
    deep_sleep_hours  = Column(Float, nullable=True)
    light_sleep_hours = Column(Float, nullable=True)
    sleep_score       = Column(Integer, nullable=True)   # 0-100
    raw_sensor_data   = Column(JSON, nullable=True)
    created_at        = Column(DateTime, nullable=False, default=datetime.utcnow)

    user = relationship("User", back_populates="sleep_records")


class SmartAlarm(Base):
    """Per-user smart alarm configuration."""
    __tablename__ = "smart_alarms"

    id              = Column(Integer, primary_key=True, index=True)
    user_id         = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"),
                             nullable=False, unique=True)
    alarm_time      = Column(String(5), nullable=False)           # "HH:MM"
    is_active       = Column(Boolean, nullable=False, default=True)
    wake_mode       = Column(String(30), nullable=False, default="gradual")  # gradual|normal|silent
    light_intensity = Column(Integer, nullable=False, default=50)             # 0-100
    sound_enabled   = Column(Boolean, nullable=False, default=True)

    user = relationship("User", back_populates="smart_alarm")


# ══════════════════════════════════════════════
# PLANNING SESSIONS
# ══════════════════════════════════════════════

class StudySession(Base):
    """A single timeboxed study/work session inside a daily planning."""
    __tablename__ = "study_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Used for fast filtering: GET /{date}
    date = Column(Date, nullable=False, index=True)

    start = Column(DateTime, nullable=False)
    end = Column(DateTime, nullable=False)
    subject = Column(String(255), nullable=False)
    priority = Column(String(20), nullable=False, default="medium")
    status = Column(String(20), nullable=False, default="pending")
    notes = Column(String(2000), nullable=True)
    is_ai_generated = Column(Boolean, nullable=False, default=False)
    completed_at = Column(DateTime, nullable=True)

    # Optional link to an uploaded document (what was studied during this session)
    document_id = Column(
        Integer,
        ForeignKey("chat_documents.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="study_sessions")
    document = relationship("ChatDocument", back_populates="study_sessions")

    @property
    def document_name(self) -> str | None:
        return self.document.filename if self.document else None

