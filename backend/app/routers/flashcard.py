"""
Flashcard router: flashcard generation and review endpoints.
"""

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
from app.utils.datetime_utils import utc_now_naive

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


def _get_owned_documents(
    db: Session,
    current_user: User,
    document_ids: list[int],
) -> list[ChatDocument]:
    if not document_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one document must be selected.",
        )

    docs = (
        db.query(ChatDocument)
        .filter(
            ChatDocument.id.in_(document_ids),
            ChatDocument.user_id == current_user.id,
        )
        .all()
    )
    docs_by_id = {doc.id: doc for doc in docs}
    ordered_docs = [docs_by_id[document_id] for document_id in document_ids if document_id in docs_by_id]
    if len(ordered_docs) != len(document_ids):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="One or more documents were not found.",
        )
    return ordered_docs


def _get_completed_session_with_documents(
    db: Session,
    current_user: User,
    session_id: int,
) -> tuple[StudySession, list[ChatDocument]]:
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
    if not session_obj.document_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This session has no linked documents.",
        )

    return session_obj, _get_owned_documents(db, current_user, session_obj.document_ids)


def _build_deck_out(
    *,
    docs: list[ChatDocument],
    cards: list[Flashcard],
    session_obj: StudySession | None = None,
) -> FlashcardDeckOut:
    now = utc_now_naive()
    cards_out = [FlashcardOut.model_validate(card) for card in cards]
    primary_doc = docs[0] if docs else None
    document_names = [doc.filename for doc in docs]

    if not document_names:
        document_name = "Documents"
    elif len(document_names) == 1:
        document_name = document_names[0]
    else:
        document_name = f"{document_names[0]} +{len(document_names) - 1} docs"

    return FlashcardDeckOut(
        document_id=primary_doc.id if primary_doc is not None else None,
        document_name=document_name,
        document_ids=[doc.id for doc in docs],
        document_names=document_names,
        session_id=session_obj.id if session_obj is not None else None,
        session_subject=session_obj.subject if session_obj is not None else None,
        total_cards=len(cards_out),
        due_cards=sum(1 for card in cards if card.next_review <= now),
        reviewed_cards=sum(1 for card in cards if card.repetitions > 0),
        cards=cards_out,
    )


def _create_flashcards_from_documents(
    *,
    db: Session,
    current_user: User,
    docs: list[ChatDocument],
    num_cards: int,
    session_obj: StudySession | None = None,
) -> FlashcardDeckOut:
    try:
        if len(docs) == 1:
            raw_cards = rag_service.generate_flashcards(
                collection_name=docs[0].chroma_collection,
                num_cards=num_cards,
            )
        else:
            raw_cards = rag_service.generate_flashcards_from_collections(
                collection_names=[doc.chroma_collection for doc in docs],
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

    primary_doc = docs[0]
    created_cards = []
    for card_data in raw_cards:
        card = Flashcard(
            user_id=current_user.id,
            document_id=primary_doc.id,
            source_session_id=session_obj.id if session_obj is not None else None,
            front=card_data["front"],
            back=card_data["back"],
            ease_factor=2.5,
            interval=1,
            repetitions=0,
            next_review=utc_now_naive(),
        )
        db.add(card)
        created_cards.append(card)

    db.commit()
    for card in created_cards:
        db.refresh(card)

    return _build_deck_out(
        docs=docs,
        cards=created_cards,
        session_obj=session_obj,
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
    """Generate flashcards from one or more documents."""
    docs = _get_owned_documents(db, current_user, request.resolved_document_ids)
    return _create_flashcards_from_documents(
        db=db,
        current_user=current_user,
        docs=docs,
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
    """Generate flashcards from the documents linked to a completed session."""
    session_obj, docs = _get_completed_session_with_documents(db, current_user, session_id)
    existing_cards = (
        db.query(Flashcard)
        .filter(
            Flashcard.user_id == current_user.id,
            Flashcard.source_session_id == session_obj.id,
        )
        .order_by(Flashcard.created_at.asc())
        .all()
    )
    if existing_cards:
        return _build_deck_out(docs=docs, cards=existing_cards, session_obj=session_obj)

    return _create_flashcards_from_documents(
        db=db,
        current_user=current_user,
        docs=docs,
        num_cards=request.num_cards,
        session_obj=session_obj,
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

    return _build_deck_out(docs=[doc], cards=cards)


@router.get(
    "/deck/session/{session_id}",
    response_model=FlashcardDeckOut,
    summary="Get the flashcard deck generated for one session",
)
def get_session_deck(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return the session-specific flashcard deck if it exists."""
    session_obj, docs = _get_completed_session_with_documents(db, current_user, session_id)
    cards = (
        db.query(Flashcard)
        .filter(
            Flashcard.user_id == current_user.id,
            Flashcard.source_session_id == session_obj.id,
        )
        .order_by(Flashcard.created_at.asc())
        .all()
    )
    return _build_deck_out(docs=docs, cards=cards, session_obj=session_obj)


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
    now = utc_now_naive()
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
