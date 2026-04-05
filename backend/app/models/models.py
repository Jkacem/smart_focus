# backend/models/models.py
from datetime import datetime, date
from enum import Enum
from sqlalchemy import (
    Column, Integer, String, DateTime, Date, Boolean,
    ForeignKey, JSON, Float, UniqueConstraint,
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
    exams = relationship("Exam", back_populates="user", cascade="all, delete-orphan")


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
    study_session_links = relationship(
        "StudySessionDocumentLink",
        back_populates="document",
        cascade="all, delete-orphan",
    )
    quiz_links = relationship(
        "QuizDocumentLink",
        back_populates="document",
        cascade="all, delete-orphan",
    )
    exams = relationship("Exam", back_populates="document")


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


class QuizDocumentLink(Base):
    """Associates a quiz with every source document used to generate it."""
    __tablename__ = "quiz_documents"
    __table_args__ = (
        UniqueConstraint("quiz_id", "document_id", name="uq_quiz_documents_quiz_document"),
    )

    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False, index=True)
    document_id = Column(
        Integer,
        ForeignKey("chat_documents.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    quiz = relationship("Quiz", back_populates="quiz_document_links")
    document = relationship("ChatDocument", back_populates="quiz_links")


class StudySessionDocumentLink(Base):
    """Associates a study session with every document studied during it."""
    __tablename__ = "study_session_documents"
    __table_args__ = (
        UniqueConstraint(
            "session_id",
            "document_id",
            name="uq_study_session_documents_session_document",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer,
        ForeignKey("study_sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    document_id = Column(
        Integer,
        ForeignKey("chat_documents.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    session = relationship("StudySession", back_populates="session_document_links")
    document = relationship("ChatDocument", back_populates="study_session_links")


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
    session_id    = Column(Integer, ForeignKey("study_sessions.id", ondelete="SET NULL"),
                           nullable=True, index=True)
    title         = Column(String(255), nullable=False)
    num_questions = Column(Integer, nullable=False, default=10)
    score         = Column(Integer, nullable=True)          # filled after submission
    completed_at  = Column(DateTime, nullable=True)
    created_at    = Column(DateTime, nullable=False, default=datetime.utcnow)

    # relationships
    user      = relationship("User",         back_populates="quizzes")
    document  = relationship("ChatDocument", back_populates="quizzes")
    quiz_document_links = relationship(
        "QuizDocumentLink",
        back_populates="quiz",
        cascade="all, delete-orphan",
    )
    session   = relationship("StudySession", back_populates="generated_quiz",
                             foreign_keys=[session_id])
    questions = relationship("QuizQuestion", back_populates="quiz",
                             cascade="all, delete-orphan")

    @property
    def document_ids(self) -> list[int]:
        ids: list[int] = []
        if self.document_id is not None:
            ids.append(self.document_id)
        ids.extend(
            link.document_id
            for link in self.quiz_document_links
            if link.document_id is not None
        )
        return list(dict.fromkeys(ids))

    @property
    def document_names(self) -> list[str]:
        names: list[str] = []
        if self.document is not None:
            names.append(self.document.filename)
        names.extend(
            link.document.filename
            for link in self.quiz_document_links
            if link.document is not None
        )
        return list(dict.fromkeys(names))


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
    source_session_id = Column(Integer, ForeignKey("study_sessions.id", ondelete="SET NULL"),
                               nullable=True, index=True)
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
    source_session = relationship("StudySession", back_populates="generated_flashcards",
                                  foreign_keys=[source_session_id])


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


class Exam(Base):
    """User-defined exam target that can intensify revision planning."""
    __tablename__ = "exams"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    document_id = Column(
        Integer,
        ForeignKey("chat_documents.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    title = Column(String(255), nullable=False)
    exam_date = Column(Date, nullable=False, index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="exams")
    document = relationship("ChatDocument", back_populates="exams")

    @property
    def document_name(self) -> str | None:
        return self.document.filename if self.document else None


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
    session_document_links = relationship(
        "StudySessionDocumentLink",
        back_populates="session",
        cascade="all, delete-orphan",
    )
    generated_quiz = relationship(
        "Quiz",
        back_populates="session",
        uselist=False,
        foreign_keys="Quiz.session_id",
    )
    generated_flashcards = relationship(
        "Flashcard",
        back_populates="source_session",
        foreign_keys="Flashcard.source_session_id",
    )

    @property
    def document_name(self) -> str | None:
        if self.document is not None:
            return self.document.filename
        names = self.document_names
        return names[0] if names else None

    @property
    def document_ids(self) -> list[int]:
        ids: list[int] = []
        if self.document_id is not None:
            ids.append(self.document_id)
        ids.extend(
            link.document_id
            for link in self.session_document_links
            if link.document_id is not None
        )
        return list(dict.fromkeys(ids))

    @property
    def document_names(self) -> list[str]:
        names: list[str] = []
        if self.document is not None:
            names.append(self.document.filename)
        names.extend(
            link.document.filename
            for link in self.session_document_links
            if link.document is not None
        )
        return list(dict.fromkeys(names))

    @property
    def session_quiz_id(self) -> int | None:
        return self.generated_quiz.id if self.generated_quiz else None

    @property
    def session_quiz_status(self) -> str:
        if self.generated_quiz is None:
            return "not_started"
        if self.generated_quiz.completed_at is not None:
            return "completed"
        return "in_progress"

    @property
    def session_flashcards_total(self) -> int:
        return len(self.generated_flashcards)

    @property
    def session_flashcards_due(self) -> int:
        now = datetime.utcnow()
        return sum(1 for card in self.generated_flashcards if card.next_review <= now)

    @property
    def session_flashcards_reviewed(self) -> int:
        return sum(1 for card in self.generated_flashcards if card.repetitions > 0)

    @property
    def session_flashcards_status(self) -> str:
        if not self.generated_flashcards:
            return "not_started"
        if self.session_flashcards_due == 0 and self.session_flashcards_reviewed > 0:
            return "completed"
        if self.session_flashcards_reviewed > 0:
            return "in_progress"
        return "generated"

