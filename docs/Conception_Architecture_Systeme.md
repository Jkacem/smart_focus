# 🏗️ Diagramme d'Architecture Système – Smart Focus & Life Assistant

**Version** : 1.0  
**Date** : 01 Mars 2026  
**Phase** : Conception  

---

## 1. Architecture Globale (Vue d'ensemble)

```mermaid
graph TB
    subgraph HW["🔧 Couche Hardware — Boîtier ESP32"]
        ESP32["ESP32-CAM\n(WiFi + Caméra)"]
        SENS["Capteurs\nMAX30102 · Micro INMP441\nPression · Température"]
        TFT["Écran TFT ILI9341\n+ LEDs WS2812B\n+ Haut-parleur MAX98357A"]
        ESP32 --> SENS
        ESP32 --> TFT
    end

    subgraph MOBILE["📱 Couche Client — Application Flutter"]
        DASH["Dashboard\nTemps réel"]
        PLAN["Planning\nIntelli­gent"]
        CHAT["Chatbot\nRAG"]
        STATS["Statistiques\n& Rapports"]
        AUTH_UI["Authentification\n(Login / Register)"]
    end

    subgraph BACKEND["⚙️ Couche Backend — FastAPI (Python)"]
        API["API REST\nFastAPI"]
        WS["WebSocket\n/ws/realtime"]
        AUTH["Auth Module\nJWT + OAuth2"]
        FOCUS_SVC["Focus Service"]
        PLAN_SVC["Planning AI Service"]
        RAG_SVC["RAG Service\n(LangChain)"]
        SLEEP_SVC["Sleep Service"]
        ML_SVC["ML Service\n(MediaPipe / TF)"]
    end

    subgraph DATA["🗄️ Couche Données"]
        PG[("PostgreSQL\nBase principale")]
        REDIS[("Redis\nCache & Sessions")]
        CHROMA[("ChromaDB\nVecteurs embeddings")]
        FILES["Fichiers\n(PDFs uploadés)"]
    end

    subgraph AI["🤖 Couche IA Externe"]
        OPENAI["OpenAI API\nGPT-3.5 / GPT-4\ntext-embedding-3"]
    end

    %% Hardware → Backend
    ESP32 -->|"HTTP POST\n(images + capteurs)"| API
    ESP32 <-->|"MQTT / WebSocket\n(commandes)"| WS

    %% Mobile → Backend
    AUTH_UI -->|"HTTPS"| AUTH
    DASH <-->|"WebSocket"| WS
    PLAN -->|"REST"| PLAN_SVC
    CHAT -->|"REST"| RAG_SVC
    STATS -->|"REST"| API
    FOCUS_SVC -->|"WebSocket push"| DASH

    %% Backend → Data
    API --> PG
    API --> REDIS
    RAG_SVC --> CHROMA
    RAG_SVC --> FILES

    %% Backend → AI
    RAG_SVC -->|"Embeddings + LLM"| OPENAI
    PLAN_SVC -->|"LLM Planning"| OPENAI
    ML_SVC -->|"MediaPipe / TF local"| FOCUS_SVC

    %% Internal Backend
    API --> AUTH
    API --> FOCUS_SVC
    API --> PLAN_SVC
    API --> RAG_SVC
    API --> SLEEP_SVC
    API --> ML_SVC

    style HW fill:#1a1a2e,stroke:#e94560,color:#fff
    style MOBILE fill:#16213e,stroke:#0f3460,color:#fff
    style BACKEND fill:#0f3460,stroke:#533483,color:#fff
    style DATA fill:#533483,stroke:#e94560,color:#fff
    style AI fill:#e94560,stroke:#fff,color:#fff
```

---

## 2. Architecture par Couche (Détail)

### 2.1 🔧 Couche Hardware (ESP32)

```mermaid
graph LR
    subgraph ESP32_DETAIL["ESP32-CAM Module"]
        CAM["🎥 Caméra OV2640\n(640×480, 30fps)"]
        WIFI["📡 WiFi 802.11 b/g/n"]
        MCU["🧠 MCU ESP32\n(FreeRTOS)"]
    end

    subgraph PERIPH["Périphériques"]
        HR["❤️ MAX30102\nHR + SpO2"]
        MIC["🎙 INMP441\nMicrophone I2S"]
        PRESS["⚖️ Capteur Pression\n(Présence bureau)"]
        SCREEN["🖥 TFT ILI9341\n2.4\" 240×320"]
        LEDS["💡 NeoPixel WS2812B\nAnneau RGB"]
        SPK["🔊 MAX98357A\nHaut-parleur I2S"]
    end

    CAM --> MCU
    HR --> MCU
    MIC --> MCU
    PRESS --> MCU
    MCU --> SCREEN
    MCU --> LEDS
    MCU --> SPK
    MCU <--> WIFI
    WIFI -->|"HTTP POST\n(JPEG frame)"| SERVER["Backend API"]
    WIFI <-->|"WebSocket\ncommandes"| SERVER
```

### 2.2 ⚙️ Couche Backend (FastAPI)

```mermaid
graph TB
    subgraph FASTAPI["FastAPI Application"]
        ROUTER["Routers\n/auth /focus /planning\n/chatbot /sleep /posture"]
        MIDDLE["Middleware\nCORS · Auth JWT · Rate Limit"]
        DI["Dependency Injection\nDB Session · Current User"]

        ROUTER --> MIDDLE
        MIDDLE --> DI
    end

    subgraph SERVICES["Services Métier"]
        S1["AuthService\nJWT · bcrypt"]
        S2["FocusService\nScore temps réel"]
        S3["MLService\nMediaPipe · OpenCV · TF"]
        S4["RAGService\nLangChain · ChromaDB"]
        S5["PlanningAI\nGeneration · Optimisation"]
        S6["SleepService\nAnalyse & Score"]
        S7["WebSocketManager\nBroadcast temps réel"]
    end

    DI --> S1
    DI --> S2
    DI --> S3
    DI --> S4
    DI --> S5
    DI --> S6
    DI --> S7

    S2 --> S3
    S4 --> S5
```

### 2.3 📱 Couche Application Flutter

```mermaid
graph TB
    subgraph FLUTTER["Flutter App (Dart 3.2+)"]
        subgraph SCREENS["Screens"]
            SC1["🔐 AuthScreen"]
            SC2["📊 DashboardScreen"]
            SC3["📅 PlanningScreen"]
            SC4["💬 ChatbotScreen"]
            SC5["📈 StatsScreen"]
            SC6["⚙️ SettingsScreen"]
        end

        subgraph STATE["State Management (Riverpod)"]
            P1["authProvider"]
            P2["focusProvider"]
            P3["planningProvider"]
            P4["chatProvider"]
            P5["sleepProvider"]
            P6["statsProvider"]
        end

        subgraph SERVICES_FL["Services"]
            API_SVC["ApiService (Dio)"]
            WS_SVC["WebSocketService"]
            LOCAL["LocalStorage (Hive)"]
            NOTIF["NotificationService"]
        end
    end

    SC1 --> P1
    SC2 --> P2
    SC3 --> P3
    SC4 --> P4
    SC5 --> P6

    P1 --> API_SVC
    P2 --> WS_SVC
    P3 --> API_SVC
    P4 --> API_SVC
    P5 --> API_SVC
    P6 --> API_SVC

    API_SVC --> BACKEND_API["Backend API\n(HTTPS)"]
    WS_SVC <--> BACKEND_WS["WebSocket\n/ws/realtime"]
    LOCAL --> P2
```

---

## 3. Flux de Communication Principal

```mermaid
sequenceDiagram
    participant ESP as ESP32-CAM
    participant API as Backend API
    participant ML as ML Service
    participant WS as WebSocket Manager
    participant APP as Flutter App

    loop Chaque 500ms (session active)
        ESP->>API: POST /focus/frame {image: base64}
        API->>ML: analyzeFrame(image)
        ML-->>API: {posture, fatigue, attention, score}
        API->>WS: broadcast({focus_score, alerts})
        WS-->>APP: WebSocket push {score: 87, posture: "good"}
        APP->>APP: Mise à jour Dashboard temps réel
    end

    alt Score < 50 (distraction)
        API->>ESP: POST /device/command {led: "orange", vibrate: true}
        API->>WS: broadcast({alert: "baisse_concentration"})
        WS-->>APP: Notification push
    end
```

---

## 4. Déploiement

```mermaid
graph LR
    subgraph LOCAL["Développement Local"]
        DEV_BACK["Backend FastAPI\nlocalhost:8000"]
        DEV_DB["PostgreSQL\nlocalhost:5432"]
        DEV_REDIS["Redis\nlocalhost:6379"]
        DEV_FRONT["Flutter\nAndroid Emulator / Device"]
    end

    subgraph PROD["Production (Optionnel)"]
        CLOUD["Cloud Server\n(VPS / Railway)"]
        CLOUD_DB[("PostgreSQL\nManaged DB")]
        CLOUD_REDIS[("Redis Cloud\nUpstash)"]
    end

    DEV_FRONT <-->|"HTTP/WS"| DEV_BACK
    DEV_BACK --> DEV_DB
    DEV_BACK --> DEV_REDIS
```

---

## 5. Récapitulatif Technologique

| Couche | Technologie | Rôle |
|--------|-------------|------|
| **Hardware** | ESP32-CAM + MicroPython/C++ | Capture images & capteurs |
| **Backend** | FastAPI (Python 3.11) | API REST + WebSocket |
| **Base de données** | PostgreSQL 15 | Données persistantes |
| **Cache** | Redis 7 | Sessions, cache temps réel |
| **Vecteurs** | ChromaDB | Embeddings RAG |
| **IA NLP** | LangChain + OpenAI | Chatbot RAG & Planning |
| **ML Vision** | MediaPipe + TensorFlow | Posture + Fatigue |
| **Mobile** | Flutter 3.16 (Dart 3.2) | Interface utilisateur |
| **État** | Riverpod 2.4 | State management Flutter |
