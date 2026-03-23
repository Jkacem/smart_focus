"""
Flashcard Router — FastAPI endpoints for flashcard generation and SM-2 review.

Endpoints:
    POST   /flashcards/generate              Generate flashcards from a document
    GET    /flashcards/deck/{document_id}     Get all flashcards for a document
    GET    /flashcards/due                    Get all cards due for review today
    POST   /flashcards/{card_id}/review       Submit review rating (SM-2 update)
    DELETE /flashcards/{card_id}              Delete a specific flashcard
"""

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.deps import get_db, get_current_user
from app.models.models import User, ChatDocument, Flashcard
from app.schemas.flashcard import (
    FlashcardGenerateRequest,
    FlashcardReviewRequest,
    FlashcardOut,
    FlashcardDeckOut,
)
from app.services import rag_service
from app.services.sm2_service import sm2_update

router = APIRouter(prefix="/flashcards", tags=["Flashcards"])


# ══════════════════════════════════════════════════════════════════════════════
# GENERATE
# ══════════════════════════════════════════════════════════════════════════════

@router.post(
    "/generate",
    response_model=FlashcardDeckOut,
    status_code=status.HTTP_201_CREATED,
    summary="Generate flashcards from a document",
)
def generate_flashcards(
    request: FlashcardGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate recto/verso flashcards from a document's content using AI."""

    # 1. Validate document ownership
    doc = (
        db.query(ChatDocument)
        .filter(
            ChatDocument.id == request.document_id,
            ChatDocument.user_id == current_user.id,
        )
        .first()
    )
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found.",
        )

    # 2. Generate flashcards via RAG service
    try:
        raw_cards = rag_service.generate_flashcards(
            collection_name=doc.chroma_collection,
            num_cards=request.num_cards,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Flashcard generation failed: {str(e)}",
        )

    # 3. Save flashcards to DB with SM-2 defaults
    created_cards = []
    for card_data in raw_cards:
        card = Flashcard(
            user_id=current_user.id,
            document_id=doc.id,
            front=card_data["front"],
            back=card_data["back"],
            # SM-2 defaults
            ease_factor=2.5,
            interval=1,
            repetitions=0,
            next_review=datetime.utcnow(),
        )
        db.add(card)
        created_cards.append(card)

    db.commit()
    for card in created_cards:
        db.refresh(card)

    cards_out = [FlashcardOut.model_validate(c) for c in created_cards]

    return FlashcardDeckOut(
        document_id=doc.id,
        document_name=doc.filename,
        total_cards=len(cards_out),
        due_cards=len(cards_out),  # all new cards are due immediately
        cards=cards_out,
    )


# ══════════════════════════════════════════════════════════════════════════════
# GET DECK
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/deck/{document_id}",
    response_model=FlashcardDeckOut,
    summary="Get all flashcards for a document",
)
def get_deck(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all flashcards for a specific document."""
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

    cards = (
        db.query(Flashcard)
        .filter(
            Flashcard.document_id == document_id,
            Flashcard.user_id == current_user.id,
        )
        .order_by(Flashcard.next_review.asc())
        .all()
    )

    now = datetime.utcnow()
    due_count = sum(1 for c in cards if c.next_review <= now)
    cards_out = [FlashcardOut.model_validate(c) for c in cards]

    return FlashcardDeckOut(
        document_id=doc.id,
        document_name=doc.filename,
        total_cards=len(cards_out),
        due_cards=due_count,
        cards=cards_out,
    )


# ══════════════════════════════════════════════════════════════════════════════
# DUE CARDS
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/due",
    response_model=List[FlashcardOut],
    summary="Get all flashcards due for review",
)
def get_due_cards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all flashcards where next_review <= now (across all documents)."""
    now = datetime.utcnow()
    cards = (
        db.query(Flashcard)
        .filter(
            Flashcard.user_id == current_user.id,
            Flashcard.next_review <= now,
        )
        .order_by(Flashcard.next_review.asc())
        .all()
    )
    return [FlashcardOut.model_validate(c) for c in cards]


# ══════════════════════════════════════════════════════════════════════════════
# REVIEW (SM-2)
# ══════════════════════════════════════════════════════════════════════════════

@router.post(
    "/{card_id}/review",
    response_model=FlashcardOut,
    summary="Submit a review rating for a flashcard",
)
def review_card(
    card_id: int,
    request: FlashcardReviewRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Apply SM-2 algorithm to update card scheduling based on quality rating (0–5)."""
    card = (
        db.query(Flashcard)
        .filter(
            Flashcard.id == card_id,
            Flashcard.user_id == current_user.id,
        )
        .first()
    )
    if not card:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flashcard not found.")

    # Apply SM-2 algorithm
    new_reps, new_ef, new_interval, next_review = sm2_update(
        quality=request.quality,
        repetitions=card.repetitions,
        ease_factor=card.ease_factor,
        interval=card.interval,
    )

    card.repetitions = new_reps
    card.ease_factor = new_ef
    card.interval = new_interval
    card.next_review = next_review

    db.commit()
    db.refresh(card)

    return FlashcardOut.model_validate(card)


# ══════════════════════════════════════════════════════════════════════════════
# DELETE
# ══════════════════════════════════════════════════════════════════════════════

@router.delete(
    "/{card_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a flashcard",
)
def delete_flashcard(
    card_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a specific flashcard."""
    card = (
        db.query(Flashcard)
        .filter(
            Flashcard.id == card_id,
            Flashcard.user_id == current_user.id,
        )
        .first()
    )
    if not card:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flashcard not found.")

    db.delete(card)
    db.commit()

    return {"message": "Flashcard deleted successfully.", "card_id": card_id}
