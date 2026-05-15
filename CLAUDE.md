# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SmartFocus is a full-stack IoT + AI productivity platform. It combines a **FastAPI Python backend**, a **Flutter mobile app**, and integrations with external AI providers (Groq, Google Gemini) and a separate Raspberry Pi vision client (not in this repo).

---

## Backend (FastAPI + Python)

**Location**: `backend/`

### Setup & Run

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Swagger docs: `http://localhost:8000/docs`

### Environment

Copy `.env` and fill in secrets. Required variables:

```
DATABASE_URL=postgresql://postgres:<password>@localhost:5432/smartFocus_db
SECRET_KEY=<generate with: openssl rand -hex 32>
GROQ_API_KEY=...
GOOGLE_API_KEY=...
AI_PROVIDER=groq   # or "gemini"
GROQ_MODEL=llama-3.3-70b-versatile
CHROMA_DB_PATH=chroma_db
UPLOADS_DIR=uploads
```

PostgreSQL database must exist before first run. Tables are created automatically at startup via SQLAlchemy `create_all`. Schema diffs are patched at runtime in `database.py` (no Alembic migrations in use).

---

## Mobile App (Flutter + Dart)

**Location**: `mobile/`

### Setup & Run

```bash
cd mobile
flutter pub get
flutter run                   # default connected device
flutter run -d windows        # Windows desktop
flutter run -d android        # Android device/emulator
```

### Build

```bash
flutter build apk             # Android APK
flutter build appbundle       # Android App Bundle
flutter build ios             # iOS (macOS only)
flutter build windows         # Windows desktop
```

### Test & Lint

```bash
flutter test                  # run all tests
flutter test test/widget_test.dart   # single test file
flutter analyze               # Dart static analysis
```

---

## Architecture

### Three-tier structure

```
Flutter App  ──HTTP/REST──►  FastAPI Backend  ──SQL──►  PostgreSQL
                                    │
                                    ├──vector──►  ChromaDB (local, ./chroma_db/)
                                    ├──LLM──────►  Groq API / Google Gemini
                                    └──embed────►  HuggingFace sentence-transformers (local)
```

The Raspberry Pi vision client (separate repo) POSTs to `/api/v1/vision/snapshots` and `/api/v1/vision/events` at ~0.5s intervals. The mobile app polls `/api/v1/vision/sessions/{id}/latest` to display real-time monitoring data.

### Backend module map

| Path | Purpose |
|---|---|
| `app/main.py` | App bootstrap, CORS, router registration |
| `app/config.py` | Pydantic settings (loads `.env`) |
| `app/database.py` | SQLAlchemy engine, session, runtime schema patches |
| `app/models/models.py` | All ORM models (~300 lines) |
| `app/deps.py` | `get_db()`, `get_current_user()` — inject into routes |
| `app/crud.py` | Database operations (create/read/update) |
| `app/routers/` | One file per feature: `auth`, `chatbot`, `vision`, `planning`, `quiz`, `flashcard`, `sleep` |
| `app/services/rag_service.py` | Full RAG pipeline: PDF → chunks → embeddings → ChromaDB → LLM |
| `app/services/planning_service.py` | AI-powered daily schedule generation via Groq |
| `app/services/sm2_service.py` | SM-2 spaced-repetition algorithm for flashcards |
| `app/schemas/` | Pydantic request/response models (one file per router) |

### Flutter feature structure

Every feature under `mobile/lib/features/<feature>/` follows this layout:

```
screens/      # UI pages
providers/    # Riverpod state (StateNotifier / AsyncNotifier)
services/     # API calls (Dio)
data/         # Repository layer (abstracts service)
models/       # JSON-serializable data classes
widgets/      # Feature-specific components
```

Shared UI lives in `mobile/lib/shared/widgets/`. Navigation is handled by GoRouter (`core/router/app_router.dart`); auth-gated redirects are in `router_notifier.dart`. HTTP is configured in `core/network/app_dio.dart` (JWT interceptor attached here). Tokens are persisted with `flutter_secure_storage` via `core/storage/token_storage.dart`.

### RAG pipeline flow

1. User uploads PDF → `POST /chatbot/upload`
2. `rag_service.py` extracts text (PyMuPDF), splits chunks (LangChain), embeds (HuggingFace local), stores in ChromaDB collection keyed by document ID
3. User asks question → `POST /chatbot/chat`
4. Top-k chunks retrieved from ChromaDB → sent as context to Groq/Gemini → response streamed back

### Key data models

`VisionSnapshot` — high-frequency CV data (posture score, attention, fatigue) ingested from the Pi client.  
`WorkSession` — groups snapshots; mobile polls latest session state to drive the dashboard.  
`PlanningSession` — AI-generated study/work block with subject, duration, priority; linked to optional `Exam`.  
`Flashcard` — stores SM-2 fields (`easiness_factor`, `interval`, `next_review`) updated on each review.

---

## API Route Prefixes

| Router | Prefix |
|---|---|
| auth | `/auth` |
| chatbot | `/chatbot` |
| vision | `/api/v1/vision` |
| planning | `/api/v1/planning` |
| quiz | `/api/v1/quiz` |
| flashcard | `/api/v1/flashcards` |
| sleep | `/api/v1/sleep` |

---

## Runtime notes

- `chroma_db/` and `uploads/` are runtime directories (gitignored content); they must exist or be created before the backend handles chatbot requests.
- The backend performs runtime schema compatibility checks in `database.py` — do not rely on Alembic for migrations; instead add column-level patches there for schema changes.
- `AI_PROVIDER=groq` uses `GROQ_API_KEY`; `AI_PROVIDER=gemini` uses `GOOGLE_API_KEY`. Both are wired in `gemini_client.py` despite its name.
- HuggingFace embeddings (`sentence-transformers`) run locally — no API key required, but first run downloads the model.
