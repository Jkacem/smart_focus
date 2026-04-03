import unittest
from datetime import date, datetime, timedelta
from unittest.mock import patch

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app import crud, schemas
from app.models.models import Base, ChatDocument, Flashcard, Quiz, SleepRecord, StudySession, User
from app.routers.flashcard import generate_flashcards_from_session
from app.routers.planning import (
    _build_planning_insights,
    _build_revision_sessions,
    _create_ai_sessions_for_day,
    _reschedule_study_session,
)
from app.routers.quiz import generate_quiz_from_session
from app.schemas.flashcard import SessionFlashcardGenerateRequest
from app.schemas.quiz import SessionQuizGenerateRequest


def make_db_session():
    engine = create_engine("sqlite:///:memory:")
    testing_session_local = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    return testing_session_local()


def create_user(db):
    user = User(
        email="student@example.com",
        full_name="Student",
        hashed_password="secret",
        role="student",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def create_document(db, user_id: int, suffix: str) -> ChatDocument:
    document = ChatDocument(
        user_id=user_id,
        filename=f"{suffix}.pdf",
        file_path=f"/tmp/{suffix}.pdf",
        chroma_collection=f"collection-{suffix}",
    )
    db.add(document)
    db.commit()
    db.refresh(document)
    return document


def create_completed_session(db, user_id: int, document_id: int, subject: str) -> StudySession:
    session = StudySession(
        user_id=user_id,
        date=date(2026, 4, 2),
        subject=subject,
        start=datetime(2026, 4, 2, 9, 0, 0),
        end=datetime(2026, 4, 2, 10, 0, 0),
        priority="medium",
        status="completed",
        completed_at=datetime(2026, 4, 2, 10, 0, 0),
        is_ai_generated=False,
        document_id=document_id,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


class PlanningUpgradeTests(unittest.TestCase):
    def test_get_due_flashcard_subjects_groups_and_sorts_by_urgency(self):
        db = make_db_session()
        user = create_user(db)
        easy_doc = create_document(db, user.id, "easy")
        urgent_doc = create_document(db, user.id, "urgent")
        target_day = date(2026, 4, 2)

        db.add(
            Flashcard(
                user_id=user.id,
                document_id=easy_doc.id,
                front="Q1",
                back="A1",
                ease_factor=2.7,
                interval=3,
                repetitions=1,
                next_review=datetime(2026, 4, 2, 8, 0, 0),
            )
        )
        db.add_all(
            [
                Flashcard(
                    user_id=user.id,
                    document_id=urgent_doc.id,
                    front="Q2",
                    back="A2",
                    ease_factor=1.9,
                    interval=1,
                    repetitions=2,
                    next_review=datetime(2026, 3, 29, 8, 0, 0),
                ),
                Flashcard(
                    user_id=user.id,
                    document_id=urgent_doc.id,
                    front="Q3",
                    back="A3",
                    ease_factor=2.0,
                    interval=1,
                    repetitions=2,
                    next_review=datetime(2026, 3, 31, 8, 0, 0),
                ),
            ]
        )
        db.commit()

        subjects = crud.get_due_flashcard_subjects(db, user.id, target_day)

        self.assertEqual([item["document_id"] for item in subjects], [urgent_doc.id, easy_doc.id])
        self.assertEqual(subjects[0]["due_count"], 2)
        self.assertGreater(subjects[0]["priority_score"], subjects[1]["priority_score"])

    def test_get_recent_quiz_performance_computes_document_weakness(self):
        db = make_db_session()
        user = create_user(db)
        weak_doc = create_document(db, user.id, "weak")
        strong_doc = create_document(db, user.id, "strong")
        now = datetime(2026, 4, 2, 18, 0, 0)

        db.add_all(
            [
                Quiz(
                    user_id=user.id,
                    document_id=weak_doc.id,
                    title="Weak quiz 1",
                    num_questions=10,
                    score=3,
                    completed_at=now - timedelta(days=1),
                ),
                Quiz(
                    user_id=user.id,
                    document_id=weak_doc.id,
                    title="Weak quiz 2",
                    num_questions=10,
                    score=4,
                    completed_at=now - timedelta(days=2),
                ),
                Quiz(
                    user_id=user.id,
                    document_id=strong_doc.id,
                    title="Strong quiz",
                    num_questions=10,
                    score=9,
                    completed_at=now - timedelta(days=1),
                ),
            ]
        )
        db.commit()

        performance = crud.get_recent_quiz_performance(
            db,
            user.id,
            target_date=now.date(),
        )

        self.assertEqual([item["document_id"] for item in performance], [weak_doc.id, strong_doc.id])
        self.assertEqual(performance[0]["attempt_count"], 2)
        self.assertGreater(performance[0]["weakness_score"], performance[1]["weakness_score"])

    def test_revision_builder_injects_flashcards_and_keeps_document_links(self):
        db = make_db_session()
        user = create_user(db)
        weak_doc = create_document(db, user.id, "physics")
        strong_doc = create_document(db, user.id, "math")
        target_day = date(2026, 4, 2)
        sleep_profile = {
            "max_session_min": 35,
            "break_min": 15,
            "max_sessions": 4,
            "priority": "medium",
            "label": "Sommeil moyen",
        }
        class_sessions = [
            {
                "subject": "Algorithms",
                "start": datetime(2026, 4, 2, 10, 0, 0),
                "end": datetime(2026, 4, 2, 12, 0, 0),
                "priority": "high",
            }
        ]

        generated = _build_revision_sessions(
            target_day,
            class_sessions,
            sleep_profile,
            due_flashcard_subjects=[
                {
                    "document_id": weak_doc.id,
                    "document_name": weak_doc.filename,
                    "due_count": 5,
                    "avg_ease_factor": 2.0,
                    "priority_score": 6.0,
                }
            ],
            quiz_performance=[
                {
                    "document_id": weak_doc.id,
                    "document_name": weak_doc.filename,
                    "attempt_count": 2,
                    "weakness_score": 0.8,
                },
                {
                    "document_id": strong_doc.id,
                    "document_name": strong_doc.filename,
                    "attempt_count": 1,
                    "weakness_score": 0.2,
                },
            ],
        )

        subjects = [item["subject"] for item in generated]
        self.assertEqual(subjects[0], f"Revision flashcards: {weak_doc.filename}")
        self.assertGreaterEqual(
            subjects.count(f"Revision quiz: {weak_doc.filename}"),
            subjects.count(f"Revision quiz: {strong_doc.filename}"),
        )

        response = _create_ai_sessions_for_day(
            target_day,
            generated,
            db=db,
            current_user=user,
        )

        linked_sessions = [session for session in response.sessions if session.document_id == weak_doc.id]
        self.assertTrue(linked_sessions)

    def test_get_completion_rate_by_hour_tracks_recent_success_patterns(self):
        db = make_db_session()
        user = create_user(db)
        db.add_all(
            [
                StudySession(
                    user_id=user.id,
                    date=date(2026, 3, 25),
                    subject="Morning focus",
                    start=datetime(2026, 3, 25, 9, 0, 0),
                    end=datetime(2026, 3, 25, 10, 0, 0),
                    priority="medium",
                    status="completed",
                    completed_at=datetime(2026, 3, 25, 10, 0, 0),
                    is_ai_generated=False,
                ),
                StudySession(
                    user_id=user.id,
                    date=date(2026, 3, 26),
                    subject="Morning focus 2",
                    start=datetime(2026, 3, 26, 9, 15, 0),
                    end=datetime(2026, 3, 26, 10, 15, 0),
                    priority="medium",
                    status="pending",
                    is_ai_generated=False,
                ),
                StudySession(
                    user_id=user.id,
                    date=date(2026, 3, 27),
                    subject="Morning focus 3",
                    start=datetime(2026, 3, 27, 9, 30, 0),
                    end=datetime(2026, 3, 27, 10, 30, 0),
                    priority="medium",
                    status="completed",
                    completed_at=datetime(2026, 3, 27, 10, 30, 0),
                    is_ai_generated=False,
                ),
                StudySession(
                    user_id=user.id,
                    date=date(2026, 3, 28),
                    subject="Late focus",
                    start=datetime(2026, 3, 28, 20, 0, 0),
                    end=datetime(2026, 3, 28, 21, 0, 0),
                    priority="medium",
                    status="cancelled",
                    is_ai_generated=False,
                ),
                StudySession(
                    user_id=user.id,
                    date=date(2026, 3, 29),
                    subject="Late focus 2",
                    start=datetime(2026, 3, 29, 20, 0, 0),
                    end=datetime(2026, 3, 29, 21, 0, 0),
                    priority="medium",
                    status="pending",
                    is_ai_generated=False,
                ),
            ]
        )
        db.commit()

        stats = crud.get_completion_rate_by_hour(
            db,
            user.id,
            target_date=date(2026, 4, 3),
        )

        self.assertEqual(stats[9]["total"], 3)
        self.assertEqual(stats[9]["completed"], 2)
        self.assertEqual(stats[9]["completion_rate"], 0.667)
        self.assertEqual(stats[20]["completion_rate"], 0.0)

    def test_revision_builder_prefers_golden_hours_from_completion_history(self):
        target_day = date(2026, 4, 3)
        sleep_profile = {
            "max_session_min": 35,
            "break_min": 15,
            "max_sessions": 2,
            "priority": "medium",
            "label": "Sommeil moyen",
        }

        generated = _build_revision_sessions(
            target_day,
            class_sessions=[],
            sleep_profile=sleep_profile,
            due_flashcard_subjects=[
                {
                    "document_id": 1,
                    "document_name": "physics.pdf",
                    "due_count": 3,
                    "avg_ease_factor": 2.1,
                    "priority_score": 4.0,
                }
            ],
            quiz_performance=[],
            completion_rate_by_hour={
                9: {"completed": 2, "total": 2, "completion_rate": 1.0},
                10: {"completed": 2, "total": 3, "completion_rate": 0.667},
                20: {"completed": 0, "total": 2, "completion_rate": 0.0},
            },
            preferred_schedule="night",
        )

        self.assertTrue(generated)
        self.assertTrue(all(session["start"].hour in {9, 10} for session in generated))
        self.assertTrue(all(session["start"].hour != 20 for session in generated))

    def test_revision_builder_falls_back_to_preferred_schedule_without_history(self):
        target_day = date(2026, 4, 3)
        sleep_profile = {
            "max_session_min": 35,
            "break_min": 15,
            "max_sessions": 2,
            "priority": "medium",
            "label": "Sommeil moyen",
        }

        generated = _build_revision_sessions(
            target_day,
            class_sessions=[],
            sleep_profile=sleep_profile,
            due_flashcard_subjects=[
                {
                    "document_id": 2,
                    "document_name": "math.pdf",
                    "due_count": 2,
                    "avg_ease_factor": 2.2,
                    "priority_score": 3.0,
                }
            ],
            quiz_performance=[],
            completion_rate_by_hour={},
            preferred_schedule="afternoon",
        )

        self.assertTrue(generated)
        self.assertTrue(all(12 <= session["start"].hour < 18 for session in generated))

    @patch("app.routers.quiz.rag_service.generate_quiz")
    def test_session_quiz_generation_reuses_existing_quiz(self, mock_generate_quiz):
        db = make_db_session()
        user = create_user(db)
        doc = create_document(db, user.id, "history")
        session = create_completed_session(db, user.id, doc.id, "History revision")
        mock_generate_quiz.return_value = [
            {
                "question": "When was the treaty signed?",
                "options": ["1918", "1945", "1991", "2001"],
                "correct_index": 1,
                "explanation": "It followed the end of World War II.",
            }
        ]

        first = generate_quiz_from_session(
            session.id,
            SessionQuizGenerateRequest(num_questions=5),
            db=db,
            current_user=user,
        )
        second = generate_quiz_from_session(
            session.id,
            SessionQuizGenerateRequest(num_questions=8),
            db=db,
            current_user=user,
        )

        self.assertEqual(first.id, second.id)
        self.assertEqual(first.session_id, session.id)
        self.assertEqual(
            db.query(Quiz).filter(Quiz.session_id == session.id).count(),
            1,
        )
        self.assertEqual(mock_generate_quiz.call_count, 1)

    @patch("app.routers.flashcard.rag_service.generate_flashcards")
    def test_session_flashcard_generation_reuses_existing_deck(self, mock_generate_flashcards):
        db = make_db_session()
        user = create_user(db)
        doc = create_document(db, user.id, "biology")
        session = create_completed_session(db, user.id, doc.id, "Biology review")
        mock_generate_flashcards.return_value = [
            {"front": "Cell", "back": "Basic unit of life"},
            {"front": "DNA", "back": "Genetic material"},
        ]

        first = generate_flashcards_from_session(
            session.id,
            SessionFlashcardGenerateRequest(num_cards=10),
            db=db,
            current_user=user,
        )
        second = generate_flashcards_from_session(
            session.id,
            SessionFlashcardGenerateRequest(num_cards=15),
            db=db,
            current_user=user,
        )

        self.assertEqual(first.session_id, session.id)
        self.assertEqual(second.session_id, session.id)
        self.assertEqual(first.total_cards, second.total_cards)
        self.assertEqual(
            db.query(Flashcard).filter(Flashcard.source_session_id == session.id).count(),
            2,
        )
        self.assertEqual(mock_generate_flashcards.call_count, 1)

    def test_study_session_out_exposes_saved_quiz_and_flashcard_state(self):
        db = make_db_session()
        user = create_user(db)
        doc = create_document(db, user.id, "chemistry")
        session = create_completed_session(db, user.id, doc.id, "Chemistry review")

        quiz = Quiz(
            user_id=user.id,
            document_id=doc.id,
            session_id=session.id,
            title="Session Quiz - Chemistry review",
            num_questions=5,
            score=4,
            completed_at=datetime.utcnow(),
        )
        flashcards = [
            Flashcard(
                user_id=user.id,
                document_id=doc.id,
                source_session_id=session.id,
                front="Atom",
                back="Smallest unit",
                ease_factor=2.5,
                interval=2,
                repetitions=1,
                next_review=datetime.utcnow() + timedelta(days=2),
            ),
            Flashcard(
                user_id=user.id,
                document_id=doc.id,
                source_session_id=session.id,
                front="Ion",
                back="Charged particle",
                ease_factor=2.3,
                interval=1,
                repetitions=1,
                next_review=datetime.utcnow() + timedelta(days=1),
            ),
        ]
        db.add(quiz)
        db.add_all(flashcards)
        db.commit()
        db.refresh(session)

        session_out = schemas.StudySessionOut.model_validate(session)

        self.assertEqual(session_out.session_quiz_id, quiz.id)
        self.assertEqual(session_out.session_quiz_status, "completed")
        self.assertEqual(session_out.session_flashcards_total, 2)
        self.assertEqual(session_out.session_flashcards_reviewed, 2)
        self.assertEqual(session_out.session_flashcards_status, "completed")

    def test_build_planning_insights_aggregates_sessions_sleep_and_quizzes(self):
        db = make_db_session()
        user = create_user(db)
        weak_doc = create_document(db, user.id, "physics")
        strong_doc = create_document(db, user.id, "math")

        sessions = [
            StudySession(
                user_id=user.id,
                date=date(2026, 4, 1),
                subject="Physics revision",
                start=datetime(2026, 4, 1, 20, 0, 0),
                end=datetime(2026, 4, 1, 21, 0, 0),
                priority="medium",
                status="cancelled",
                is_ai_generated=False,
                document_id=weak_doc.id,
            ),
            StudySession(
                user_id=user.id,
                date=date(2026, 4, 2),
                subject="Math review",
                start=datetime(2026, 4, 2, 9, 0, 0),
                end=datetime(2026, 4, 2, 10, 30, 0),
                priority="high",
                status="completed",
                completed_at=datetime(2026, 4, 2, 10, 30, 0),
                is_ai_generated=False,
                document_id=strong_doc.id,
            ),
            StudySession(
                user_id=user.id,
                date=date(2026, 4, 2),
                subject="Physics quiz drill",
                start=datetime(2026, 4, 2, 19, 30, 0),
                end=datetime(2026, 4, 2, 20, 30, 0),
                priority="medium",
                status="completed",
                completed_at=datetime(2026, 4, 2, 20, 30, 0),
                is_ai_generated=False,
                document_id=weak_doc.id,
            ),
        ]
        db.add_all(sessions)
        db.add_all(
            [
                SleepRecord(
                    user_id=user.id,
                    sleep_start=datetime(2026, 4, 1, 0, 30, 0),
                    sleep_end=datetime(2026, 4, 1, 7, 30, 0),
                    total_hours=7.0,
                    deep_sleep_hours=1.8,
                    sleep_score=76,
                ),
                SleepRecord(
                    user_id=user.id,
                    sleep_start=datetime(2026, 4, 2, 0, 15, 0),
                    sleep_end=datetime(2026, 4, 2, 6, 15, 0),
                    total_hours=6.0,
                    deep_sleep_hours=1.2,
                    sleep_score=62,
                ),
                Quiz(
                    user_id=user.id,
                    document_id=weak_doc.id,
                    title="Physics weak",
                    num_questions=10,
                    score=3,
                    completed_at=datetime(2026, 4, 2, 18, 0, 0),
                ),
                Quiz(
                    user_id=user.id,
                    document_id=strong_doc.id,
                    title="Math strong",
                    num_questions=10,
                    score=9,
                    completed_at=datetime(2026, 4, 1, 17, 0, 0),
                ),
            ]
        )
        db.commit()

        insights = _build_planning_insights(
            db,
            user,
            period="week",
            anchor_day=date(2026, 4, 2),
        )

        self.assertEqual(insights.period, "week")
        self.assertEqual(insights.total_study_minutes, 150)
        self.assertEqual(insights.completed_sessions, 2)
        self.assertEqual(insights.skipped_sessions, 1)
        self.assertEqual(insights.completion_rate, 0.67)
        self.assertEqual(insights.avg_sleep_score, 69.0)
        self.assertEqual(insights.weakest_subject, weak_doc.filename)
        self.assertEqual(insights.strongest_subject, strong_doc.filename)
        self.assertEqual(insights.sleep_study_correlation, "insufficient_data")
        self.assertTrue(insights.recommendation)

    def test_build_planning_insights_handles_sparse_data(self):
        db = make_db_session()
        user = create_user(db)
        doc = create_document(db, user.id, "philosophy")
        db.add(
            StudySession(
                user_id=user.id,
                date=date(2026, 4, 2),
                subject="Lecture",
                start=datetime(2026, 4, 2, 11, 0, 0),
                end=datetime(2026, 4, 2, 12, 0, 0),
                priority="medium",
                status="completed",
                completed_at=datetime(2026, 4, 2, 12, 0, 0),
                is_ai_generated=False,
                document_id=doc.id,
            )
        )
        db.commit()

        insights = _build_planning_insights(
            db,
            user,
            period="week",
            anchor_day=date(2026, 4, 2),
        )

        self.assertEqual(insights.total_study_minutes, 60)
        self.assertEqual(insights.completed_sessions, 1)
        self.assertEqual(insights.skipped_sessions, 0)
        self.assertEqual(insights.completion_rate, 1.0)
        self.assertIsNone(insights.avg_sleep_score)
        self.assertEqual(insights.sleep_study_correlation, "insufficient_data")
        self.assertIsNone(insights.weakest_subject)
        self.assertEqual(insights.strongest_subject, doc.filename)
        self.assertTrue(insights.recommendation)

    def test_reschedule_session_uses_next_available_slot_today(self):
        db = make_db_session()
        user = create_user(db)
        doc = create_document(db, user.id, "literature")

        original = StudySession(
            user_id=user.id,
            date=date(2026, 4, 2),
            subject="Literature revision",
            start=datetime(2026, 4, 2, 9, 0, 0),
            end=datetime(2026, 4, 2, 10, 0, 0),
            priority="medium",
            status="pending",
            is_ai_generated=False,
            document_id=doc.id,
        )
        blocker_one = StudySession(
            user_id=user.id,
            date=date(2026, 4, 2),
            subject="Math",
            start=datetime(2026, 4, 2, 12, 30, 0),
            end=datetime(2026, 4, 2, 13, 30, 0),
            priority="medium",
            status="pending",
            is_ai_generated=False,
        )
        blocker_two = StudySession(
            user_id=user.id,
            date=date(2026, 4, 2),
            subject="Science",
            start=datetime(2026, 4, 2, 15, 0, 0),
            end=datetime(2026, 4, 2, 16, 0, 0),
            priority="medium",
            status="pending",
            is_ai_generated=False,
        )
        db.add_all([original, blocker_one, blocker_two])
        db.commit()
        db.refresh(original)

        rescheduled = _reschedule_study_session(
            db,
            user,
            original,
            reference_time=datetime(2026, 4, 2, 12, 10, 0),
        )

        self.assertEqual(rescheduled.start, datetime(2026, 4, 2, 13, 45, 0))
        self.assertEqual(rescheduled.end, datetime(2026, 4, 2, 14, 45, 0))
        self.assertEqual(rescheduled.document_id, doc.id)
        self.assertEqual(rescheduled.subject, original.subject)
        self.assertEqual(rescheduled.status, "pending")
        self.assertNotEqual(rescheduled.id, original.id)
        db.refresh(original)
        self.assertEqual(original.status, "cancelled")

    def test_reschedule_session_moves_to_tomorrow_when_today_is_full(self):
        db = make_db_session()
        user = create_user(db)

        original = StudySession(
            user_id=user.id,
            date=date(2026, 4, 2),
            subject="Physics recap",
            start=datetime(2026, 4, 2, 9, 0, 0),
            end=datetime(2026, 4, 2, 10, 0, 0),
            priority="high",
            status="pending",
            is_ai_generated=True,
        )
        today_blocker = StudySession(
            user_id=user.id,
            date=date(2026, 4, 2),
            subject="Late block",
            start=datetime(2026, 4, 2, 18, 15, 0),
            end=datetime(2026, 4, 2, 22, 0, 0),
            priority="medium",
            status="pending",
            is_ai_generated=False,
        )
        tomorrow_blocker = StudySession(
            user_id=user.id,
            date=date(2026, 4, 3),
            subject="Morning class",
            start=datetime(2026, 4, 3, 9, 0, 0),
            end=datetime(2026, 4, 3, 10, 0, 0),
            priority="medium",
            status="pending",
            is_ai_generated=False,
        )
        db.add_all([original, today_blocker, tomorrow_blocker])
        db.commit()
        db.refresh(original)

        rescheduled = _reschedule_study_session(
            db,
            user,
            original,
            reference_time=datetime(2026, 4, 2, 18, 0, 0),
        )

        self.assertEqual(rescheduled.start, datetime(2026, 4, 3, 10, 15, 0))
        self.assertEqual(rescheduled.end, datetime(2026, 4, 3, 11, 15, 0))
        self.assertTrue(rescheduled.is_ai_generated)
        db.refresh(original)
        self.assertEqual(original.status, "cancelled")


if __name__ == "__main__":
    unittest.main()
