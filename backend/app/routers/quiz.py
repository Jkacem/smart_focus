"""
Quiz router: quiz generation and submission endpoints.
"""

from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.deps import get_current_user, get_db
from app.models.models import ChatDocument, Quiz, QuizQuestion, StudySession, User
from app.schemas.quiz import (
    QuizAnswerRequest,
    QuizGenerateRequest,
    QuizOut,
    QuizQuestionOut,
    QuizResultOut,
    SessionQuizGenerateRequest,
)
from app.services import rag_service

router = APIRouter(prefix="/quiz", tags=["Quiz"])


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
            detail="Complete the session before generating a quiz from it.",
        )
    if session_obj.document_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This session has no linked document.",
        )

    return session_obj, _get_owned_document(db, current_user, session_obj.document_id)


def _create_quiz_from_document(
    *,
    db: Session,
    current_user: User,
    doc: ChatDocument,
    num_questions: int,
    title_prefix: str = "Quiz",
    session_obj: StudySession | None = None,
) -> QuizOut:
    try:
        raw_questions = rag_service.generate_quiz(
            collection_name=doc.chroma_collection,
            num_questions=num_questions,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Quiz generation failed: {exc}",
        ) from exc

    quiz = Quiz(
        user_id=current_user.id,
        document_id=doc.id,
        session_id=session_obj.id if session_obj is not None else None,
        title=f"{title_prefix} - {doc.filename}",
        num_questions=len(raw_questions),
    )
    db.add(quiz)
    db.flush()

    for q in raw_questions:
        db.add(
            QuizQuestion(
                quiz_id=quiz.id,
                question_text=q["question"],
                options=q["options"],
                correct_index=q["correct_index"],
                explanation=q.get("explanation"),
            )
        )

    db.commit()
    db.refresh(quiz)

    return _serialize_quiz(quiz)


def _serialize_quiz(quiz: Quiz) -> QuizOut:
    if quiz.completed_at is None:
        questions_out = [
            QuizQuestionOut(
                id=q.id,
                question_text=q.question_text,
                options=q.options,
                correct_index=None,
                explanation=None,
                user_answer_index=None,
            )
            for q in quiz.questions
        ]
    else:
        questions_out = [QuizQuestionOut.model_validate(q) for q in quiz.questions]

    return QuizOut(
        id=quiz.id,
        document_id=quiz.document_id,
        session_id=quiz.session_id,
        title=quiz.title,
        num_questions=quiz.num_questions,
        score=quiz.score,
        completed_at=quiz.completed_at,
        created_at=quiz.created_at,
        questions=questions_out,
    )


@router.post(
    "/generate",
    response_model=QuizOut,
    status_code=status.HTTP_201_CREATED,
    summary="Generate a quiz from a document",
)
def generate_quiz(
    request: QuizGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate quiz questions from one document."""
    doc = _get_owned_document(db, current_user, request.document_id)
    return _create_quiz_from_document(
        db=db,
        current_user=current_user,
        doc=doc,
        num_questions=request.num_questions,
        title_prefix="Quiz",
    )


@router.post(
    "/generate-from-session/{session_id}",
    response_model=QuizOut,
    status_code=status.HTTP_201_CREATED,
    summary="Generate a quiz from a completed study session",
)
def generate_quiz_from_session(
    session_id: int,
    request: SessionQuizGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate quiz questions from the document linked to a completed session."""
    session_obj, doc = _get_completed_session_with_document(db, current_user, session_id)
    existing_quiz = (
        db.query(Quiz)
        .filter(
            Quiz.user_id == current_user.id,
            Quiz.session_id == session_obj.id,
        )
        .order_by(Quiz.created_at.desc())
        .first()
    )
    if existing_quiz is not None:
        return _serialize_quiz(existing_quiz)

    return _create_quiz_from_document(
        db=db,
        current_user=current_user,
        doc=doc,
        num_questions=request.num_questions,
        title_prefix=f"Session Quiz - {session_obj.subject}",
        session_obj=session_obj,
    )


@router.get(
    "/list",
    response_model=List[QuizOut],
    summary="List all quizzes for current user",
)
def list_quizzes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all quizzes for the authenticated user."""
    quizzes = (
        db.query(Quiz)
        .filter(Quiz.user_id == current_user.id)
        .order_by(Quiz.created_at.desc())
        .all()
    )
    return [QuizOut.model_validate(q) for q in quizzes]


@router.get(
    "/{quiz_id}",
    response_model=QuizOut,
    summary="Get a specific quiz",
)
def get_quiz(
    quiz_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a quiz with its questions, hiding answers until submitted."""
    quiz = (
        db.query(Quiz)
        .filter(Quiz.id == quiz_id, Quiz.user_id == current_user.id)
        .first()
    )
    if not quiz:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz not found.")

    return _serialize_quiz(quiz)


@router.post(
    "/{quiz_id}/submit",
    response_model=QuizResultOut,
    summary="Submit quiz answers and get scored results",
)
def submit_quiz(
    quiz_id: int,
    request: QuizAnswerRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Submit answers for a quiz and return the graded result."""
    quiz = (
        db.query(Quiz)
        .filter(Quiz.id == quiz_id, Quiz.user_id == current_user.id)
        .first()
    )
    if not quiz:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz not found.")

    if quiz.completed_at is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Quiz has already been submitted.",
        )

    questions = sorted(quiz.questions, key=lambda q: q.id)
    if len(request.answers) != len(questions):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Expected {len(questions)} answers, got {len(request.answers)}.",
        )

    score = 0
    for question, user_answer in zip(questions, request.answers):
        question.user_answer_index = user_answer
        if user_answer == question.correct_index:
            score += 1

    quiz.score = score
    quiz.completed_at = datetime.utcnow()
    db.commit()
    db.refresh(quiz)

    questions_out = [QuizQuestionOut.model_validate(q) for q in questions]
    percentage = round((score / len(questions)) * 100, 1) if questions else 0

    return QuizResultOut(
        quiz_id=quiz.id,
        score=score,
        total=len(questions),
        percentage=percentage,
        questions=questions_out,
    )
