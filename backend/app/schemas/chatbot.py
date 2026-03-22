"""
Pydantic schemas for the RAG Chatbot feature.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ══════════════════════════════════════════════
# DOCUMENT SCHEMAS
# ══════════════════════════════════════════════

class DocumentInfo(BaseModel):
    """Basic document info returned to the Flutter client."""
    id: int
    filename: str
    page_count: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


class DocumentUploadResponse(BaseModel):
    """Returned after a successful PDF upload and ingestion."""
    message: str
    document: DocumentInfo


class DocumentDeleteResponse(BaseModel):
    """Returned after a successful document deletion."""
    message: str
    document_id: int


# ══════════════════════════════════════════════
# CHAT SCHEMAS
# ══════════════════════════════════════════════

class SourceCitation(BaseModel):
    """A single source chunk cited in a chatbot answer."""
    filename: str
    page: Optional[int] = None
    excerpt: Optional[str] = None   # short text snippet for context


class ChatRequest(BaseModel):
    """Request body for the /chatbot/chat endpoint."""
    question: str = Field(..., min_length=2, max_length=2000,
                          description="The question to ask the document(s)")
    document_ids: List[int] = Field(..., min_length=1,
                                    description="List of document IDs to search in")


class ChatResponse(BaseModel):
    """Response body for /chatbot/chat — answer + source citations."""
    answer: str
    sources: List[SourceCitation] = []
    message_id: Optional[int] = None   # DB id of the saved ChatMessage


# ══════════════════════════════════════════════
# HISTORY SCHEMAS
# ══════════════════════════════════════════════

class ChatMessageInfo(BaseModel):
    """A stored chat message (for history display)."""
    id: int
    question: str
    answer: str
    sources: Optional[List[SourceCitation]] = []
    created_at: datetime

    class Config:
        from_attributes = True
