"""
Flashcard router: flashcard generation and review endpoints.
"""

from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.deps import get_current_user, get_db
from app.models.models import ChatDocument, Flashcard, StudySession, User
from app.schemas.flashcard import (
    FlashcardDeckOut,
    FlashcardGenerateRequest,
    FlashcardOut,
    FlashcardReviewRequest,
    SessionFlashcardGenerateRequest,
)
from app.services import rag_service
from app.services.sm2_service import sm2_update

router = APIRouter(prefix="/flashcards", tags=["Flashcards"])


def _get_owned_document(db: Session, current_user: User, document_id: int) -> ChatDocument:
    doc = (
        db.query(ChatDocument)
        .filter(
            ChatDocument.id == document_id,
            ChatDocument.user_id == current_user.id,
        )
        .first()
    )
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found.",
        )
    return doc


def _get_completed_session_with_document(
    db: Session,
    current_user: User,
    session_id: int,
) -> tuple[StudySession, ChatDocument]:
    session_obj = (
        db.query(StudySession)
        .filter(
            StudySession.id == session_id,
            StudySession.user_id == current_user.id,
        )
        .first()
    )
    if not session_obj:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found.",
        )
    if session_obj.status != "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Complete the session before generating flashcards from it.",
        )
    if session_obj.document_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This session has no linked document.",
        )

    return session_obj, _get_owned_document(db, current_user, session_obj.document_id)


def _create_flashcards_from_document(
    *,
    db: Session,
    current_user: User,
    doc: ChatDocument,
    num_cards: int,
) -> FlashcardDeckOut:
    try:
        raw_cards = rag_service.generate_flashcards(
            collection_name=doc.chroma_collection,
            num_cards=num_cards,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Flashcard generation failed: {exc}",
        ) from exc

    created_cards = []
    for card_data in raw_cards:
        card = Flashcard(
            user_id=current_user.id,
            document_id=doc.id,
            front=card_data["front"],
            back=card_data["back"],
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

    cards_out = [FlashcardOut.model_validate(card) for card in created_cards]
    return FlashcardDeckOut(
        document_id=doc.id,
        document_name=doc.filename,
        total_cards=len(cards_out),
        due_cards=len(cards_out),
        cards=cards_out,
    )


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
    """Generate flashcards from one document."""
    doc = _get_owned_document(db, current_user, request.document_id)
    return _create_flashcards_from_document(
        db=db,
        current_user=current_user,
        doc=doc,
        num_cards=request.num_cards,
    )


@router.post(
    "/generate-from-session/{session_id}",
    response_model=FlashcardDeckOut,
    status_code=status.HTTP_201_CREATED,
    summary="Generate flashcards from a completed study session",
)
def generate_flashcards_from_session(
    session_id: int,
    request: SessionFlashcardGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate flashcards from the document linked to a completed session."""
    _, doc = _get_completed_session_with_document(db, current_user, session_id)
    return _create_flashcards_from_document(
        db=db,
        current_user=current_user,
        doc=doc,
        num_cards=request.num_cards,
    )


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
    """Return all flashcards for one document."""
    doc = _get_owned_document(db, current_user, document_id)
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
    due_count = sum(1 for card in cards if card.next_review <= now)
    cards_out = [FlashcardOut.model_validate(card) for card in cards]

    return FlashcardDeckOut(
        document_id=doc.id,
        document_name=doc.filename,
        total_cards=len(cards_out),
        due_cards=due_count,
        cards=cards_out,
    )


@router.get(
    "/due",
    response_model=List[FlashcardOut],
    summary="Get all flashcards due for review",
)
def get_due_cards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all flashcards that are due now."""
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
    return [FlashcardOut.model_validate(card) for card in cards]


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
    """Apply the SM-2 update to one flashcard."""
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
    """Delete one flashcard."""
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
