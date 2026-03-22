# backend/models/models.py
from datetime import datetime
from enum import Enum
from sqlalchemy import (
    Column, Integer, String, DateTime, Boolean,
    ForeignKey, JSON,
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
    user     = relationship("User", back_populates="chat_documents")
    messages = relationship("ChatMessage", back_populates="document",
                            cascade="all, delete-orphan")


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

