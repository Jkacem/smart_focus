"""
Chatbot Router — FastAPI endpoints for the RAG chatbot.

Endpoints:
    POST   /chatbot/upload            Upload a PDF and ingest it into ChromaDB
    POST   /chatbot/chat              Ask a question about selected documents
    GET    /chatbot/documents         List documents uploaded by current user
    DELETE /chatbot/documents/{id}    Remove a document (disk + DB + Chroma)
    GET    /chatbot/history           Chat history for current user
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session
from typing import List

from app.deps import get_db, get_current_user
from app.models.models import User, ChatDocument, ChatMessage
from app.schemas.chatbot import (
    DocumentInfo,
    DocumentUploadResponse,
    DocumentDeleteResponse,
    ChatRequest,
    ChatResponse,
    ChatMessageInfo,
    SourceCitation,
)
from app.services import document_service, rag_service

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])


# ══════════════════════════════════════════════════════════════════════════════
# DOCUMENT MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

@router.post(
    "/upload",
    response_model=DocumentUploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a PDF document for RAG",
)
async def upload_document(
    file: UploadFile = File(..., description="PDF file to upload"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Upload a PDF document. It will be chunked, embedded, and stored in ChromaDB."""

    # Validate file type
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF files are accepted.",
        )

    # 1. Save file to disk
    file_path, collection_name = document_service.save_upload(file, current_user.id)

    # 2. Ingest into ChromaDB (chunking + embedding)
    try:
        page_count = rag_service.ingest_pdf(file_path, collection_name)
    except ValueError as e:
        document_service.delete_file(file_path)
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except Exception as e:
        document_service.delete_file(file_path)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process PDF: {str(e)}",
        )

    # 3. Persist metadata in PostgreSQL
    doc = ChatDocument(
        user_id=current_user.id,
        filename=file.filename,
        file_path=file_path,
        chroma_collection=collection_name,
        page_count=page_count,
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)

    return DocumentUploadResponse(
        message=f"✅ '{file.filename}' ingested successfully ({page_count} pages).",
        document=DocumentInfo.model_validate(doc),
    )


@router.get(
    "/documents",
    response_model=List[DocumentInfo],
    summary="List all documents uploaded by current user",
)
def list_documents(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all PDF documents belonging to the authenticated user."""
    docs = (
        db.query(ChatDocument)
        .filter(ChatDocument.user_id == current_user.id)
        .order_by(ChatDocument.created_at.desc())
        .all()
    )
    return [DocumentInfo.model_validate(d) for d in docs]


@router.delete(
    "/documents/{document_id}",
    response_model=DocumentDeleteResponse,
    summary="Delete a document and its vectors",
)
def delete_document(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Remove document from disk, PostgreSQL, and ChromaDB."""
    doc = (
        db.query(ChatDocument)
        .filter(
            ChatDocument.id == document_id,
            ChatDocument.user_id == current_user.id,
        )
        .first()
    )
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found.")

    # 1. Delete vectors from ChromaDB
    rag_service.delete_collection(doc.chroma_collection)

    # 2. Delete file from disk
    document_service.delete_file(doc.file_path)

    # 3. Delete DB record (cascade deletes linked chat_messages)
    db.delete(doc)
    db.commit()

    return DocumentDeleteResponse(message="Document deleted successfully.", document_id=document_id)


# ══════════════════════════════════════════════════════════════════════════════
# CHAT
# ══════════════════════════════════════════════════════════════════════════════

@router.post(
    "/chat",
    response_model=ChatResponse,
    summary="Ask a question about your documents",
)
def chat(
    request: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    RAG chat endpoint.
    Retrieves relevant chunks from selected documents and generates a grounded answer, or answers generally if no documents selected.
    """
    if not request.document_ids:
        # General non-RAG chat mode
        try:
            result = rag_service.query_general(question=request.question)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"General AI query failed: {str(e)}",
            )
        db_document_id = None
    else:
        # RAG mode
        docs = (
            db.query(ChatDocument)
            .filter(
                ChatDocument.id.in_(request.document_ids),
                ChatDocument.user_id == current_user.id,
            )
            .all()
        )
        if not docs:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No valid documents found for the provided IDs. Please upload a PDF first.",
            )

        collection_names = [d.chroma_collection for d in docs]
        db_document_id = docs[0].id

        # Call the RAG service
        try:
            result = rag_service.query_rag(
                question=request.question,
                collection_names=collection_names,
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"RAG query failed: {str(e)}",
            )

    answer   = result["answer"]
    raw_src  = result.get("sources", [])

    # Persist the exchange in the DB
    message = ChatMessage(
        user_id=current_user.id,
        document_id=db_document_id,
        question=request.question,
        answer=answer,
        sources=raw_src,
    )
    db.add(message)
    db.commit()
    db.refresh(message)

    sources = [
        SourceCitation(
            filename=s["filename"],
            page=s.get("page"),
            excerpt=s.get("excerpt"),
        )
        for s in raw_src
    ]

    return ChatResponse(answer=answer, sources=sources, message_id=message.id)


# ══════════════════════════════════════════════════════════════════════════════
# HISTORY
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/history",
    response_model=List[ChatMessageInfo],
    summary="Chat history for the current user",
)
def get_history(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return the last N chat exchanges for the authenticated user."""
    messages = (
        db.query(ChatMessage)
        .filter(ChatMessage.user_id == current_user.id)
        .order_by(ChatMessage.created_at.desc())
        .limit(limit)
        .all()
    )
    return [ChatMessageInfo.model_validate(m) for m in messages]
