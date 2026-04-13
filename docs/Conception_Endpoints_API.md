# 🌐 Endpoints API – Smart Focus & Life Assistant

**Version** : 2.0  
**Date** : 9 Avril 2026  
**Base URL** : `http://localhost:8000`  
**Framework** : FastAPI + OpenAPI (Swagger : `/docs`, ReDoc : `/redoc`)

> ⚠️ Les endpoints `/chatbot/*` n'ont pas de préfixe `/api/v1/`. Tous les autres utilisent `/api/v1/`.

---

## 1. Vue Globale des Endpoints Actifs

```mermaid
graph LR
    CLIENT["🖥 Client\n(Flutter App)"]

    subgraph AUTH_GRP["🔐 /api/v1/auth"]
        A1["POST /register"]
        A2["POST /login"]
        A3["GET  /me"]
        A4["PUT  /me/profile"]
    end

    subgraph PLANNING_GRP["📅 /api/v1/planning"]
        PL1["GET  /today"]
        PL2["GET  /{date}"]
        PL3["POST /generate"]
        PL4["POST /generate/week"]
        PL5["GET  /insights"]
        PL6["POST /sessions"]
        PL7["PATCH /sessions/{id}"]
        PL8["PATCH /sessions/{id}/complete"]
        PL9["DELETE /sessions/{id}"]
        PL10["POST /reschedule/{id}"]
        PL11["GET  /exams"]
        PL12["POST /exams"]
        PL13["DELETE /exams/{id}"]
    end

    subgraph CHATBOT_GRP["💬 /chatbot"]
        C1["POST /upload"]
        C2["GET  /documents"]
        C3["DELETE /documents/{id}"]
        C4["POST /chat"]
        C5["GET  /history"]
    end

    subgraph QUIZ_GRP["🧠 /api/v1/quiz"]
        Q1["POST /generate"]
        Q2["POST /{id}/submit"]
        Q3["GET  /"]
    end

    subgraph FLASH_GRP["🃏 /api/v1/flashcards"]
        F1["POST /generate"]
        F2["GET  /due"]
        F3["POST /{id}/review"]
    end

    subgraph SLEEP_GRP["🌙 /api/v1/sleep"]
        S1["POST /log"]
        S2["GET  /stats"]
        S3["GET  /history"]
        S4["PUT  /alarm"]
        S5["GET  /alarm"]
    end

    CLIENT --> AUTH_GRP
    CLIENT --> PLANNING_GRP
    CLIENT --> CHATBOT_GRP
    CLIENT --> QUIZ_GRP
    CLIENT --> FLASH_GRP
    CLIENT --> SLEEP_GRP
```

---

## 2. Détail par Module

### 🔐 Authentification (`/api/v1/auth`)

| Méthode | Endpoint | Auth? | Description | Body | Réponse |
|---------|----------|-------|-------------|------|---------|
| `POST` | `/register` | ❌ | Créer un compte | `{email, password, full_name}` | `{access_token, user}` |
| `POST` | `/login` | ❌ | Se connecter (form) | `{email, password}` | `{access_token, token_type}` |
| `GET` | `/me` | ✅ | Profil courant + préférences | — | `{user, profile}` |
| `PUT` | `/me/profile` | ✅ | Mettre à jour préférences | `{daily_focus_goal, preferred_schedule, notif_enabled}` | `{profile}` |

```mermaid
sequenceDiagram
    participant APP as Flutter App
    participant API as /auth

    APP->>API: POST /register {email, password, full_name}
    API-->>APP: 201 {access_token, user}

    APP->>API: POST /login {email, password}
    API-->>APP: 200 {access_token, token_type: "bearer"}

    note over APP: Token stocké localement (Hive)
    APP->>API: GET /me (Authorization: Bearer <token>)
    API-->>APP: 200 {user, profile}
```

---

### 💬 Chatbot RAG (`/chatbot`)

> Note: Ce routeur n'a pas de préfixe `/api/v1/`.

| Méthode | Endpoint | Auth? | Description | Body | Réponse |
|---------|----------|-------|-------------|------|---------|
| `POST` | `/upload` | ✅ | Upload PDF ou CSV emploi du temps | `multipart/form-data` (file) | `{message, document}` |
| `GET` | `/documents` | ✅ | Lister les documents de l'utilisateur | — | `[DocumentInfo]` |
| `DELETE` | `/documents/{id}` | ✅ | Supprimer document (DB + disque + ChromaDB) | — | `{message, document_id}` |
| `POST` | `/chat` | ✅ | Poser une question (RAG ou général) | `{question, document_ids?: [int]}` | `{answer, sources[], message_id}` |
| `GET` | `/history` | ✅ | Historique des échanges du user | `?limit=20` | `[ChatMessageInfo]` |

**Modes de chat :**
- `document_ids` vide → mode général (IA directe, sans RAG)
- `document_ids` rempli → mode RAG (recherche dans ChromaDB + génération de réponse ancrée)

**Formats de fichier acceptés pour `/upload` :**
- `.pdf` → ingestion ChromaDB (chunking + embedding Gemini)
- `.csv` → validation schema (`week, day, start, end, subject`) pour emploi du temps

```mermaid
sequenceDiagram
    participant APP as Flutter App
    participant API as /chatbot
    participant RAG as RAGService
    participant DB as ChromaDB
    participant LLM as Gemini API

    APP->>API: POST /upload {file: cours.pdf}
    API->>RAG: ingest_pdf(file_path, collection)
    RAG->>LLM: embed(chunks)
    RAG->>DB: store(vectors)
    API-->>APP: 201 {document, "12 pages ingested"}

    APP->>API: POST /chat {question, document_ids: [1]}
    API->>RAG: query_rag(question, collections)
    RAG->>DB: similarity_search(embedding)
    DB-->>RAG: [chunk1, chunk2, chunk3]
    RAG->>LLM: generate(question + chunks)
    LLM-->>RAG: "La mitose est..."
    RAG-->>API: {answer, sources}
    API-->>APP: 200 {answer, sources: [{filename, page, excerpt}]}
```

---

### 🧠 Quiz (`/api/v1/quiz`)

| Méthode | Endpoint | Auth? | Description | Body | Réponse |
|---------|----------|-------|-------------|------|---------|
| `POST` | `/generate` | ✅ | Générer un quiz depuis document(s) | `{document_id, num_questions?: int}` | `{quiz, questions[]}` |
| `POST` | `/{id}/submit` | ✅ | Soumettre les réponses | `{answers: [0, 2, 1, ...]}` | `{score, corrections[]}` |
| `GET` | `/` | ✅ | Lister mes quiz | — | `[Quiz]` |

**Structure d'une question QCM :**
```json
{
  "question_text": "Qu'est-ce que la mitose ?",
  "options": ["Division cellulaire", "Photosynthèse", "Respiration", "Fermentation"],
  "correct_index": 0,
  "explanation": "La mitose est le processus de division cellulaire..."
}
```

---

### 🃏 Flashcards SM-2 (`/api/v1/flashcards`)

| Méthode | Endpoint | Auth? | Description | Body | Réponse |
|---------|----------|-------|-------------|------|---------|
| `POST` | `/generate` | ✅ | Générer des flashcards depuis doc | `{document_id, count?: int}` | `[Flashcard]` |
| `GET` | `/due` | ✅ | Cartes dues aujourd'hui (SM-2) | — | `[Flashcard]` |
| `POST` | `/{id}/review` | ✅ | Soumettre une révision | `{ease: 0-5}` | `{next_review, interval, repetitions}` |

**Algorithme SM-2 :**
- `ease 0-1` → répétition immédiate (difficile)
- `ease 2` → lendemain
- `ease 3-5` → intervalle multiplié par `ease_factor` (2.5 par défaut)

---

### 📅 Planning Intelligent (`/api/v1/planning`)

| Méthode | Endpoint | Auth? | Description | Body |
|---------|----------|-------|-------------|------|
| `GET` | `/today` | ✅ | Planning du jour courant | — |
| `GET` | `/{date}` | ✅ | Planning d'une date (`YYYY-MM-DD`) | — |
| `POST` | `/generate` | ✅ | Générer planning IA pour 1 jour | voir ci-dessous |
| `POST` | `/generate/week` | ✅ | Générer planning IA pour 7 jours | voir ci-dessous |
| `GET` | `/insights` | ✅ | Stats et recommandations | `?period=week\|month` |
| `POST` | `/sessions` | ✅ | Créer session manuelle | `{subject, start, end, priority, document_id?}` |
| `PATCH` | `/sessions/{id}` | ✅ | Modifier une session | `{status?, notes?, subject?}` |
| `PATCH` | `/sessions/{id}/complete` | ✅ | Marquer comme terminée | — |
| `DELETE` | `/sessions/{id}` | ✅ | Supprimer une session | — |
| `POST` | `/reschedule/{id}` | ✅ | Replanifier session manquée/annulée | — |
| `GET` | `/exams` | ✅ | Lister les examens à venir | — |
| `POST` | `/exams` | ✅ | Créer un examen | `{title, exam_date, document_id?}` |
| `DELETE` | `/exams/{id}` | ✅ | Supprimer un examen | — |

**Body `/generate` et `/generate/week` :**
```json
{
  "date": "2026-04-09",
  "document_id": 3,
  "week_type": "A",
  "exam_ids": [1, 2],
  "preferences": {
    "subjects": ["Mathématiques", "Physique"]
  }
}
```

**Logique de génération (mode CSV) :**
```mermaid
flowchart TD
    A[POST /generate] --> B{document_id fourni ?}
    B -- Non --> C[Génération Gemini générique]
    B -- Oui --> D{Fichier CSV ?}
    D -- Oui --> E[parse_csv_schedule]
    D -- Non --> F[Extraction PDF via ChromaDB + Gemini]
    E --> G[class_sessions pour le jour]
    F --> G
    G --> H[_get_sleep_profile]
    H --> I{Score sommeil}
    I -- ≥80 --> J[50min/session, 6 max]
    I -- <50 --> K[25min/session, 2 max]
    I -- Autre --> L[35min/session, 4 max]
    J & K & L --> M[_compute_free_slots]
    M --> N[_build_revision_sessions]
    N --> O[Révisions cours + examens + flashcards + quiz faibles]
    O --> P[Sauvegarder en DB]
    P --> Q[PlanningDayOut]
```

**Body `/insights` — exemple de réponse :**
```json
{
  "period": "week",
  "total_study_minutes": 420,
  "completed_sessions": 8,
  "skipped_sessions": 2,
  "completion_rate": 0.8,
  "avg_sleep_score": 72.5,
  "sleep_study_correlation": "positive",
  "weakest_subject": "Chimie_Organique.pdf",
  "strongest_subject": "Mathématiques.pdf",
  "recommendation": "Votre taux de complétion est plus fort le matin. Essayez de réduire les sessions le soir."
}
```

---

### 🌙 Sommeil (`/api/v1/sleep`)

| Méthode | Endpoint | Auth? | Description | Body | Réponse |
|---------|----------|-------|-------------|------|---------|
| `POST` | `/log` | ✅ | Enregistrer une nuit | `{sleep_start, sleep_end, raw_data?}` | `{record, sleep_score}` |
| `GET` | `/stats` | ✅ | Statistiques de sommeil | `?period=week\|month` | `{avg_hours, score_avg, trend}` |
| `GET` | `/history` | ✅ | Historique des nuits | `?limit=30` | `[SleepRecord]` |
| `PUT` | `/alarm` | ✅ | Créer/maj config alarme | `{alarm_time, wake_mode, light_intensity, sound_enabled}` | `{alarm}` |
| `GET` | `/alarm` | ✅ | Lire la config alarme | — | `{alarm}` |

**Paramètres alarme :**
- `alarm_time` : format `"HH:MM"`
- `wake_mode` : `"gradual"` | `"normal"` | `"silent"`
- `light_intensity` : `0–100`

---

## 3. Authentification JWT

```
Authorization: Bearer <access_token>
```

- **Access token** : expire dans **30 minutes**
- Stockage Flutter : `Hive` (local storage sécurisé)
- Rôles : `student` | `teacher` | `professional`

---

## 4. Codes de Statut HTTP

| Code | Signification |
|------|---------------|
| `200` | Succès |
| `201` | Ressource créée |
| `204` | Suppression réussie (pas de contenu) |
| `400` | Requête invalide |
| `401` | Non authentifié (token manquant/expiré) |
| `403` | Accès refusé |
| `404` | Ressource introuvable |
| `409` | Conflit (ex: aucun créneau libre pour reschedule) |
| `422` | Erreur de validation (Pydantic ou logique métier) |
| `500` | Erreur interne serveur |

---

## 5. Endpoints Planifiés (Non Encore Implémentés)

| Module | Endpoint | Raison du report |
|--------|----------|-----------------|
| WebSocket | `WS /ws/realtime` | Frontend prêt, backend non finalisé |
| Device IoT | `/api/v1/device/*` | Bloqué en attente hardware Personne 1 |
| Focus Sessions | `/api/v1/focus/*` | Dépend de l'ESP32-CAM |
| Posture | `/api/v1/posture/*` | Dépend du ML Personne 1 |

---

*Mis à jour le 9 Avril 2026 — Smart Focus & Life Assistant*
