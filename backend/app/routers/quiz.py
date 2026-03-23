"""
Quiz Router — FastAPI endpoints for quiz generation and management.

Endpoints:
    POST   /quiz/generate           Generate a quiz from a document
    GET    /quiz/list               List all quizzes for current user
    GET    /quiz/{quiz_id}          Get a specific quiz with questions
    POST   /quiz/{quiz_id}/submit   Submit answers and get scored results
"""

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.deps import get_db, get_current_user
from app.models.models import User, ChatDocument, Quiz, QuizQuestion
from app.schemas.quiz import (
    QuizGenerateRequest,
    QuizAnswerRequest,
    QuizQuestionOut,
    QuizOut,
    QuizResultOut,
)
from app.services import rag_service

router = APIRouter(prefix="/quiz", tags=["Quiz"])


# ══════════════════════════════════════════════════════════════════════════════
# GENERATE
# ══════════════════════════════════════════════════════════════════════════════

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
    """Generate QCM questions from a document's content using AI."""

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

    # 2. Generate quiz questions via RAG service
    try:
        raw_questions = rag_service.generate_quiz(
            collection_name=doc.chroma_collection,
            num_questions=request.num_questions,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Quiz generation failed: {str(e)}",
        )

    # 3. Save quiz + questions to DB
    quiz = Quiz(
        user_id=current_user.id,
        document_id=doc.id,
        title=f"Quiz — {doc.filename}",
        num_questions=len(raw_questions),
    )
    db.add(quiz)
    db.flush()  # get quiz.id

    for q in raw_questions:
        question = QuizQuestion(
            quiz_id=quiz.id,
            question_text=q["question"],
            options=q["options"],
            correct_index=q["correct_index"],
            explanation=q.get("explanation"),
        )
        db.add(question)

    db.commit()
    db.refresh(quiz)

    # 4. Return quiz WITHOUT correct answers (hidden until submit)
    questions_out = [
        QuizQuestionOut(
            id=q.id,
            question_text=q.question_text,
            options=q.options,
            correct_index=None,      # hidden
            explanation=None,        # hidden
            user_answer_index=None,
        )
        for q in quiz.questions
    ]

    return QuizOut(
        id=quiz.id,
        document_id=quiz.document_id,
        title=quiz.title,
        num_questions=quiz.num_questions,
        score=None,
        completed_at=None,
        created_at=quiz.created_at,
        questions=questions_out,
    )


# ══════════════════════════════════════════════════════════════════════════════
# LIST
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/list",
    response_model=List[QuizOut],
    summary="List all quizzes for current user",
)
def list_quizzes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all quizzes belonging to the authenticated user."""
    quizzes = (
        db.query(Quiz)
        .filter(Quiz.user_id == current_user.id)
        .order_by(Quiz.created_at.desc())
        .all()
    )
    return [QuizOut.model_validate(q) for q in quizzes]


# ══════════════════════════════════════════════════════════════════════════════
# GET SINGLE QUIZ
# ══════════════════════════════════════════════════════════════════════════════

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
    """Get a quiz with its questions. Hides answers if not yet completed."""
    quiz = (
        db.query(Quiz)
        .filter(Quiz.id == quiz_id, Quiz.user_id == current_user.id)
        .first()
    )
    if not quiz:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz not found.")

    # If not completed, hide correct answers
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
        title=quiz.title,
        num_questions=quiz.num_questions,
        score=quiz.score,
        completed_at=quiz.completed_at,
        created_at=quiz.created_at,
        questions=questions_out,
    )


# ══════════════════════════════════════════════════════════════════════════════
# SUBMIT ANSWERS
# ══════════════════════════════════════════════════════════════════════════════

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
    """Submit answers for a quiz. Returns score and corrections."""
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

    # Score and save user answers
    score = 0
    for q, user_answer in zip(questions, request.answers):
        q.user_answer_index = user_answer
        if user_answer == q.correct_index:
            score += 1

    quiz.score = score
    quiz.completed_at = datetime.utcnow()
    db.commit()
    db.refresh(quiz)

    # Return full results with corrections
    questions_out = [QuizQuestionOut.model_validate(q) for q in questions]
    percentage = round((score / len(questions)) * 100, 1) if questions else 0

    return QuizResultOut(
        quiz_id=quiz.id,
        score=score,
        total=len(questions),
        percentage=percentage,
        questions=questions_out,
    )
