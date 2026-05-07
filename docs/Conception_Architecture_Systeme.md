# 🏗️ Diagramme d'Architecture Système – Smart Focus & Life Assistant

**Version** : 2.0  
**Date** : 02 Mai 2026  
**Phase** : Conception (mise à jour post-implémentation)  

---

## 1. Architecture Globale (Vue d'ensemble)

```mermaid
graph TB
    subgraph HW["🔧 Couche Vision — pi_client (Python)"]
        PI["pi_client\n(Raspberry Pi / PC)\nMediaPipe + OpenCV"]
        CAM["Caméra USB\n(capture vidéo)"]
        CAM --> PI
    end

    subgraph MOBILE["📱 Couche Client — Application Flutter"]
        DASH["Dashboard\nTemps réel (polling)"]
        PLAN["Planning\nIntelli­gent"]
        CHAT["Chatbot\nRAG"]
        STATS["Statistiques\n& Rapports"]
        AUTH_UI["Authentification\n(Login / Register)"]
    end

    subgraph BACKEND["⚙️ Couche Backend — FastAPI (Python)"]
        API["API REST\nFastAPI"]
        AUTH["Auth Module\nJWT + OAuth2"]
        VISION_SVC["Vision Ingestion\nSnapshots + Events"]
        PLAN_SVC["Planning AI Service\nGroq + déterministe"]
        RAG_SVC["RAG Service\n(Chroma + Groq)"]
        SLEEP_SVC["Sleep Service"]
    end

    subgraph DATA["🗄️ Couche Données"]
        PG[("PostgreSQL\nBase principale")]
        CHROMA[("ChromaDB\nVecteurs embeddings")]
        FILES["Fichiers\n(PDFs uploadés)"]
    end

    subgraph AI["🤖 Couche IA Externe"]
        GROQ["Groq API\nllama-3.3-70b-versatile"]
    end

    %% pi_client → Backend
    PI -->|"HTTP POST\n(snapshots JSON + events)"| API

    %% Mobile → Backend
    AUTH_UI -->|"HTTPS"| AUTH
    DASH -->|"HTTP Polling\n(GET /sessions/{id}/latest)"| VISION_SVC
    PLAN -->|"REST"| PLAN_SVC
    CHAT -->|"REST"| RAG_SVC
    STATS -->|"REST"| API

    %% Backend → Data
    API --> PG
    RAG_SVC --> CHROMA
    RAG_SVC --> FILES

    %% Backend → AI
    RAG_SVC -->|"LLM (RAG)"| GROQ
    PLAN_SVC -->|"LLM (personnalisation sujets)"| GROQ
    PI -->|"MediaPipe / OpenCV local"| PI

    %% Internal Backend
    API --> AUTH
    API --> VISION_SVC
    API --> PLAN_SVC
    API --> RAG_SVC
    API --> SLEEP_SVC

    style HW fill:#1a1a2e,stroke:#e94560,color:#fff
    style MOBILE fill:#16213e,stroke:#0f3460,color:#fff
    style BACKEND fill:#0f3460,stroke:#533483,color:#fff
    style DATA fill:#533483,stroke:#e94560,color:#fff
    style AI fill:#e94560,stroke:#fff,color:#fff
```

---

## 2. Architecture par Couche (Détail)

### 2.1 🔧 Couche Vision (pi_client)

```mermaid
graph LR
    subgraph PI_DETAIL["pi_client (Python)"]
        CAM["🎥 Caméra USB\n(webcam / Raspberry Pi Camera)"]
        CV["🧠 Pipeline CV\nMediaPipe Pose + Face\nOpenCV"]
        SCORE["📊 Calcul Scores\nAttention · Posture\nVigilance · Stress\nFocus Global"]
        FMT["📝 JSON Formatter\nSnapshot structuré"]
        CLIENT["🌐 API Client\nHTTP POST vers Backend"]
    end

    CAM --> CV --> SCORE --> FMT --> CLIENT
    CLIENT -->|"POST /vision/snapshots\n(chaque ~0.5s)"| SERVER["Backend API"]
    CLIENT -->|"POST /vision/events\n(alertes, résumés)"| SERVER
    CLIENT -->|"POST /sessions\n(début/fin session)"| SERVER
```

### 2.2 ⚙️ Couche Backend (FastAPI)

```mermaid
graph TB
    subgraph FASTAPI["FastAPI Application"]
        ROUTER["Routers\n/auth /planning /chatbot\n/quiz /flashcards /sleep\n/vision /sessions"]
        MIDDLE["Middleware\nCORS · Auth JWT"]
        DI["Dependency Injection\nDB Session · Current User"]

        ROUTER --> MIDDLE
        MIDDLE --> DI
    end

    subgraph SERVICES["Services Métier"]
        S1["AuthService\nJWT · bcrypt"]
        S4["RAGService\nChromaDB · Groq"]
        S5["PlanningAIService\nPipeline hybride\n(déterministe + Groq)"]
        S6["SleepService\nLog · Score · Alarme"]
        S8["SM2Service\nRépétition espacée"]
        S9["LLMClient (GeminiClient)\nInterface LLM unifiée\n(Groq / Gemini)"]
        S10["ScheduleParser\nParsing CSV emploi du temps"]
    end

    DI --> S1
    DI --> S4
    DI --> S5
    DI --> S6
    DI --> S8
    S5 --> S9
    S4 --> S9
    S5 --> S10
```

### 2.3 📱 Couche Application Flutter

```mermaid
graph TB
    subgraph FLUTTER["Flutter App (Dart 3.2+)"]
        subgraph SCREENS["Screens"]
            SC1["🔐 Auth\n(Welcome · Login · Register)"]
            SC2["📊 Dashboard\n(HomePage · SessionActive)"]
            SC3["📅 Planning"]
            SC4["💬 Chatbot"]
            SC5["🧠 Quiz\n(Generate · Play · Result)"]
            SC6["🃏 Flashcards\n(Generate · Deck · Review)"]
            SC7["🌙 Sleep\n(Dashboard · Alarm · Ring)"]
            SC8["📈 Statistics"]
            SC9["⚙️ Settings"]
        end

        subgraph STATE["State Management (Riverpod)"]
            P1["authProvider"]
            P2["visionProvider\n(polling snapshots)"]
            P3["planningProvider"]
            P4["chatProvider"]
            P5["sleepProvider"]
        end

        subgraph SERVICES_FL["Services"]
            API_SVC["ApiService (Dio)\n+ JWT Interceptor"]
            LOCAL["LocalStorage\n(SharedPreferences)"]
        end
    end

    SC2 --> P2
    SC3 --> P3
    SC4 --> P4
    SC7 --> P5

    P1 --> API_SVC
    P2 --> API_SVC
    P3 --> API_SVC
    P4 --> API_SVC
    P5 --> API_SVC

    API_SVC --> BACKEND_API["Backend API\n(HTTPS)"]
```

---

## 3. Flux de Communication Principal

```mermaid
sequenceDiagram
    participant PI as pi_client
    participant API as Backend API
    participant DB as PostgreSQL
    participant APP as Flutter App

    Note over PI: Session CV démarrée
    PI->>API: POST /api/v1/sessions {id, start_time}
    API->>DB: INSERT INTO work_sessions
    API-->>PI: 201 {session}

    loop Chaque ~500ms (session active)
        PI->>PI: Capture frame → MediaPipe → Calcul scores
        PI->>API: POST /api/v1/vision/snapshots {session_id, scores, observations}
        API->>DB: INSERT INTO snapshots (attention, posture, vigilance, stress, focus)
        API-->>PI: 201 OK
    end

    loop Polling Flutter (chaque 3-5s)
        APP->>API: GET /api/v1/sessions/{id}/latest
        API->>DB: SELECT * FROM snapshots ORDER BY timestamp DESC LIMIT 1
        DB-->>API: Latest snapshot
        API-->>APP: {attention: 85, posture: 78, vigilance: 90, stress: 12, focus: 82}
        APP->>APP: Mise à jour Dashboard temps réel
    end

    alt Événement détecté (distraction, fatigue)
        PI->>API: POST /api/v1/vision/events {event_type, level, description}
        API->>DB: INSERT INTO focus_events
    end

    Note over PI: Fin de session
    PI->>API: POST /api/v1/sessions/{id}/finalize {final_score, breakdown}
    API->>DB: UPDATE work_sessions SET is_active=false, end_time=now()
```

---

## 4. Déploiement

```mermaid
graph LR
    subgraph LOCAL["Développement Local"]
        DEV_BACK["Backend FastAPI\nlocalhost:8000"]
        DEV_DB["PostgreSQL\nlocalhost:5432"]
        DEV_FRONT["Flutter\nAndroid Emulator / Device"]
        DEV_PI["pi_client\nPC local / Raspberry Pi"]
    end

    DEV_FRONT <-->|"HTTP"| DEV_BACK
    DEV_PI -->|"HTTP POST"| DEV_BACK
    DEV_BACK --> DEV_DB
```

---

## 5. Récapitulatif Technologique

| Couche | Technologie | Rôle |
|--------|-------------|------|
| **Vision CV** | pi_client (Python) + MediaPipe + OpenCV | Analyse comportementale en temps réel |
| **Backend** | FastAPI (Python 3.11) | API REST |
| **Base de données** | PostgreSQL 15 | Données persistantes |
| **Vecteurs** | ChromaDB | Embeddings RAG |
| **IA NLP (LLM)** | Groq llama-3.3-70b-versatile | Chatbot RAG & Planning |
| **Embeddings** | HuggingFace all-MiniLM-L6-v2 (local) | Vectorisation documents RAG |
| **Mobile** | Flutter 3.16 (Dart 3.2) | Interface utilisateur |
| **État** | Riverpod 2.4 | State management Flutter |
| **Navigation** | GoRouter | Routing déclaratif |
| **HTTP** | Dio 5.3 + JWT Interceptor | Appels API |
| **Alarmes** | Flutter alarm package | Réveil intelligent local |

---

## 6. Changements par rapport à la v1.0

| Élément | Conception v1.0 | Réalité v2.0 |
|---------|----------------|--------------|
| Hardware | ESP32-CAM → Backend ML | pi_client Python fait le ML localement |
| Communication temps réel | WebSocket `/ws/realtime` | HTTP polling (GET latest snapshot) |
| ML Backend | MLService interne (MediaPipe/TF) | ML externe (pi_client), backend = ingesteur |
| Cache | Redis pour sessions/pub-sub | Non utilisé (supprimé de l'architecture) |
| Scores CV | `posture_score`, `fatigue_score`, `attention_score` | `attention`, `posture`, `vigilance`, `stress_risk`, `global_focus` |
| Sessions focus | `focus_sessions` table | `work_sessions` + `snapshots` + `focus_events` |

---

*Mis à jour le 02 Mai 2026 — Smart Focus & Life Assistant*
