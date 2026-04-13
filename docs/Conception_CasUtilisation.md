# 📐 Diagrammes de Cas d'Utilisation – Smart Focus & Life Assistant

**Version** : 2.0  
**Date** : 9 Avril 2026  
**Phase** : Conception  

---

## 1. Identification des Acteurs

```mermaid
graph LR
    subgraph Acteurs Principaux
        U["👤 Utilisateur<br/>(Étudiant / Professionnel / Enseignant)"]
    end

    subgraph Acteurs Secondaires
        ESP["📟 Boîtier ESP32<br/>(Hardware IoT)"]
        IA["🤖 Système IA<br/>(LLM + RAG)"]
        ML["🧠 Service ML<br/>(Vision / Posture)"]
    end

    subgraph Acteurs Externes
        API_EXT["☁️ Google Gemini API"]
    end
```

| Acteur | Type | Description |
|--------|------|-------------|
| **Utilisateur** | Principal | Étudiant, professionnel ou enseignant qui interagit avec l'application mobile |
| **Boîtier ESP32** | Secondaire | Dispositif IoT qui capture les données physiques (caméra, capteurs) |
| **Service ML** | Secondaire | Module serveur d'analyse d'images (posture, fatigue, visage) |
| **Système IA** | Secondaire | Module RAG/LLM pour le chatbot, le planning intelligent, la génération de quiz et flashcards |
| **Google Gemini API** | Externe | Service cloud pour la génération de texte (Gemini 2.5 Flash) et les embeddings (text-embedding-004) |

---

## 2. Diagramme de Cas d'Utilisation Général

```mermaid
graph TB
    %% Acteurs
    User(("👤 Utilisateur"))
    ESP32(("📟 ESP32"))
    IA(("🤖 IA / LLM"))
    ML(("🧠 ML Vision"))

    %% CU Authentification
    subgraph AUTH ["🔐 Authentification"]
        UC1["S'inscrire"]
        UC2["Se connecter"]
        UC3["Gérer le profil"]
        UC3r["Rafraîchir le token"]
    end

    %% CU Focus
    subgraph FOCUS ["🎯 Focus & Concentration"]
        UC4["Démarrer une session de travail"]
        UC5["Consulter le score de focus en temps réel"]
        UC6["Recevoir des alertes de concentration"]
        UC7["Consulter l'historique des sessions"]
    end

    %% CU Planning
    subgraph PLANNING ["📅 Planning Intelligent"]
        UC8["Consulter le planning du jour"]
        UC9["Générer un planning IA (jour)"]
        UC9w["Générer un planning IA (semaine)"]
        UC10["Modifier une session planifiée"]
        UC11["Supprimer une session planifiée"]
        UC10c["Marquer une session terminée"]
        UC10r["Replanifier une session manquée"]
        UC30["Consulter les insights planning"]
        UC31["Créer un examen"]
        UC32["Supprimer un examen"]
    end

    %% CU Chatbot
    subgraph CHATBOT ["💬 Chatbot RAG"]
        UC12["Uploader un document (PDF ou CSV)"]
        UC13["Poser une question sur les cours"]
        UC13g["Poser une question générale"]
        UC12l["Lister mes documents"]
        UC12d["Supprimer un document"]
    end

    %% CU Quiz
    subgraph QUIZ ["🧠 Quiz"]
        UC14["Générer un quiz depuis un document"]
        UC14s["Générer un quiz depuis une session"]
        UC14sub["Soumettre les réponses d'un quiz"]
        UC14l["Lister mes quiz"]
    end

    %% CU Flashcards
    subgraph FLASHCARDS ["🃏 Flashcards SM-2"]
        UC15["Générer des flashcards"]
        UC15s["Générer des flashcards depuis une session"]
        UC15r["Réviser une flashcard (SM-2)"]
        UC15d["Consulter les cartes dues"]
        UC15del["Supprimer une flashcard"]
    end

    %% CU Posture
    subgraph POSTURE ["🧍 Posture & Ergonomie"]
        UC17["Détecter la posture en temps réel"]
        UC18["Recevoir des alertes posture"]
        UC19["Consulter les statistiques posture"]
        UC20["Recevoir des conseils ergonomiques"]
    end

    %% CU Sommeil
    subgraph SOMMEIL ["🌙 Sommeil & Réveil"]
        UC21["Enregistrer les données de sommeil"]
        UC22["Consulter le score de sommeil"]
        UC22h["Consulter l'historique sommeil"]
        UC23["Configurer le réveil intelligent"]
        UC24["Adapter le planning selon le sommeil"]
    end

    %% CU Statistiques
    subgraph STATS ["📊 Statistiques & Conseils"]
        UC27["Consulter le dashboard global"]
        UC28["Voir les statistiques hebdomadaires"]
        UC29["Recevoir des conseils personnalisés"]
    end

    %% Relations Utilisateur
    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC3r
    User --> UC4
    User --> UC5
    User --> UC7
    User --> UC8
    User --> UC9
    User --> UC9w
    User --> UC10
    User --> UC11
    User --> UC10c
    User --> UC10r
    User --> UC30
    User --> UC31
    User --> UC32
    User --> UC12
    User --> UC13
    User --> UC13g
    User --> UC12l
    User --> UC12d
    User --> UC14
    User --> UC14s
    User --> UC14sub
    User --> UC14l
    User --> UC15
    User --> UC15s
    User --> UC15r
    User --> UC15d
    User --> UC15del
    User --> UC17
    User --> UC19
    User --> UC21
    User --> UC22
    User --> UC22h
    User --> UC23
    User --> UC27
    User --> UC28

    %% Relations ESP32
    ESP32 --> UC6
    ESP32 --> UC17
    ESP32 --> UC18
    ESP32 --> UC21

    %% Relations IA
    IA --> UC9
    IA --> UC9w
    IA --> UC13
    IA --> UC13g
    IA --> UC14
    IA --> UC14s
    IA --> UC15
    IA --> UC15s
    IA --> UC20
    IA --> UC24
    IA --> UC29
    IA --> UC30

    %% Relations ML
    ML --> UC5
    ML --> UC6
    ML --> UC17
    ML --> UC18
```

---

## 3. Cas d'Utilisation Détaillés par Module

### 3.1 🔐 Module Authentification

```mermaid
graph LR
    User(("👤 Utilisateur"))

    UC1["S'inscrire"]
    UC2["Se connecter"]
    UC3["Gérer le profil"]
    UC3r["Rafraîchir le token"]
    UC3a["Modifier les informations"]
    UC3b["Définir les objectifs de focus"]
    UC3c["Configurer les notifications"]
    UC3d["Choisir l'emploi du temps préféré"]

    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC3r

    UC3 -.->|include| UC3a
    UC3 -.->|include| UC3b
    UC3 -.->|extend| UC3c
    UC3 -.->|extend| UC3d

    UC2 -.->|extend| UC1
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC1 | S'inscrire | Utilisateur | Aucun compte existant | 1. Saisir email, mot de passe, nom, rôle<br/>2. Valider<br/>3. Compte + profil créés | Compte actif, JWT access + refresh |
| UC2 | Se connecter | Utilisateur | Compte existant et actif | 1. Saisir email/mot de passe (OAuth2 form)<br/>2. Authentification<br/>3. Token JWT retourné | Session active |
| UC3 | Gérer le profil | Utilisateur | Connecté | 1. Accéder à `/auth/me`<br/>2. Modifier `daily_focus_goal`, `preferred_schedule`, `notif_enabled`<br/>3. Sauvegarder via `PUT /auth/me/profile` | Profil mis à jour |
| UC3r | Rafraîchir le token | Utilisateur | Refresh token valide | 1. Envoyer `POST /auth/refresh` avec refresh_token<br/>2. Nouveau couple access + refresh retourné | Nouvelle session |

**Endpoints réels :**
- `POST /auth/register` — Inscription
- `POST /auth/login` — Connexion (OAuth2PasswordRequestForm)
- `POST /auth/refresh` — Rafraîchissement du token
- `GET /auth/me` — Profil courant
- `PUT /auth/me/profile` — Mise à jour préférences

---

### 3.2 🎯 Module Focus & Concentration

```mermaid
graph LR
    User(("👤 Utilisateur"))
    ESP32(("📟 ESP32"))
    ML(("🧠 ML Vision"))

    UC4["Démarrer une session"]
    UC5["Voir le score en temps réel"]
    UC6["Recevoir une alerte focus"]
    UC7["Consulter l'historique"]

    UC4a["Capturer images via caméra"]
    UC4b["Analyser posture & fatigue"]
    UC4c["Calculer le score de focus"]

    User --> UC4
    User --> UC5
    User --> UC7

    ESP32 --> UC4a
    ML --> UC4b

    UC4 -.->|include| UC4a
    UC4 -.->|include| UC4b
    UC4 -.->|include| UC4c

    UC4c -.->|extend| UC6

    ESP32 --> UC6
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC4 | Démarrer une session | Utilisateur, ESP32, ML | Connecté, boîtier allumé | 1. Cliquer "Démarrer"<br/>2. ESP32 commence capture<br/>3. ML analyse en continu<br/>4. Score affiché temps réel | Session en cours |
| UC5 | Voir score temps réel | Utilisateur | Session active | 1. Dashboard affiche score<br/>2. WebSocket met à jour<br/>3. Graphique en direct | Score visible |
| UC6 | Recevoir alerte focus | ESP32, ML | Score < seuil | 1. Score bas détecté<br/>2. LED rouge sur boîtier<br/>3. Notification mobile | Utilisateur alerté |
| UC7 | Consulter historique | Utilisateur | Sessions passées | 1. Aller dans Statistiques<br/>2. Filtrer par période<br/>3. Voir graphiques | Historique affiché |

> ⚠️ Ce module dépend de l'intégration hardware ESP32 (Personne 1). Le backend est architecturé pour le recevoir mais les endpoints `/focus/*` ne sont pas encore implémentés.

---

### 3.3 📅 Module Planning Intelligent

Ce module est le plus sophistiqué du système. Il gère la génération automatique de sessions d'étude adaptées au profil de l'utilisateur, à son sommeil, à ses examens et à ses résultats de quiz/flashcards.

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA / LLM"))

    UC8["Consulter le planning"]
    UC9["Générer planning IA (jour)"]
    UC9w["Générer planning IA (semaine)"]
    UC10["Modifier une session"]
    UC11["Supprimer une session"]
    UC10c["Marquer session terminée"]
    UC10r["Replanifier session manquée"]
    UC30["Consulter les insights"]
    UC31["Créer un examen"]
    UC32["Supprimer un examen"]

    UC9a["Analyser profil sommeil"]
    UC9b["Parser emploi du temps CSV"]
    UC9c["Extraire timetable PDF via RAG"]
    UC9d["Calculer créneaux libres"]
    UC9e["Adapter selon score sommeil"]
    UC9f["Rotation pondérée des matières"]
    UC9g["Intégrer révisions examens"]
    UC9h["Intégrer flashcards SM-2 dues"]
    UC9i["Intégrer sujets faibles (quiz)"]

    User --> UC8
    User --> UC9
    User --> UC9w
    User --> UC10
    User --> UC11
    User --> UC10c
    User --> UC10r
    User --> UC30
    User --> UC31
    User --> UC32

    IA --> UC9a
    IA --> UC9c
    IA --> UC9f

    UC9 -.->|include| UC9d
    UC9 -.->|include| UC9f
    UC9 -.->|extend| UC9a
    UC9 -.->|extend| UC9b
    UC9 -.->|extend| UC9c
    UC9 -.->|extend| UC9e
    UC9 -.->|extend| UC9g
    UC9 -.->|extend| UC9h
    UC9 -.->|extend| UC9i
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC8 | Consulter le planning | Utilisateur | Connecté | 1. `GET /planning/today` ou `GET /planning/{date}`<br/>2. Voir sessions du jour | Planning affiché |
| UC9 | Générer planning IA (jour) | Utilisateur, IA | Connecté, document CSV/PDF uploadé (optionnel) | 1. `POST /planning/generate` avec date, document_id, exam_ids, week_type<br/>2. Parsing CSV ou extraction PDF Gemini<br/>3. Profil sommeil évalué → durée/nb sessions adaptés<br/>4. Créneaux libres calculés (8h–22h, 15min buffer)<br/>5. Rotation pondérée : cours, examens, flashcards dues, quiz faibles<br/>6. Sessions créées en DB | Planning journée créé |
| UC9w | Générer planning IA (semaine) | Utilisateur, IA | Idem UC9 | 1. `POST /planning/generate/week`<br/>2. Génère pour 7 jours (lundi→dimanche)<br/>3. Week-end : sweep hebdomadaire des cours non vus | Planning semaine créé |
| UC10 | Modifier une session | Utilisateur | Session existante | 1. `PATCH /planning/sessions/{id}`<br/>2. Modifier statut, notes, documents liés | Session modifiée |
| UC10c | Marquer session terminée | Utilisateur | Session en cours | 1. `PATCH /planning/sessions/{id}/complete`<br/>2. `completed_at` enregistré | Session terminée |
| UC10r | Replanifier session manquée | Utilisateur | Session expirée ou annulée | 1. `POST /planning/reschedule/{id}`<br/>2. Système cherche créneau libre sur J ou J+1<br/>3. Nouvelle session créée, ancienne annulée | Session replanifiée |
| UC11 | Supprimer une session | Utilisateur | Session existante | 1. `DELETE /planning/sessions/{id}` | Session supprimée |
| UC30 | Consulter les insights | Utilisateur | Données historiques | 1. `GET /planning/insights?period=week\|month`<br/>2. Calcul : minutes étudiées, taux complétion, corrélation sommeil↔productivité, sujet le plus faible, recommandation | Insights affichés |
| UC31 | Créer un examen | Utilisateur | Connecté | 1. `POST /planning/exams`<br/>2. Titre, date, document optionnel | Examen créé |
| UC32 | Supprimer un examen | Utilisateur | Examen existant | 1. `DELETE /planning/exams/{id}` | Examen supprimé |

**Endpoints réels :**
- `GET /api/v1/planning/today`
- `GET /api/v1/planning/{date}`
- `POST /api/v1/planning/generate`
- `POST /api/v1/planning/generate/week`
- `GET /api/v1/planning/insights`
- `POST /api/v1/planning/sessions`
- `PATCH /api/v1/planning/sessions/{id}`
- `PATCH /api/v1/planning/sessions/{id}/complete`
- `DELETE /api/v1/planning/sessions/{id}`
- `POST /api/v1/planning/reschedule/{id}`
- `GET /api/v1/planning/exams`
- `POST /api/v1/planning/exams`
- `DELETE /api/v1/planning/exams/{id}`

**Logique d'adaptation au sommeil :**

| Score sommeil | Durée max session | Pause entre sessions | Nb max sessions | Priorité |
|:---:|:---:|:---:|:---:|:---:|
| ≥ 80 (bien reposé) | 50 min | 10 min | 6 | high |
| 50–79 (moyen) | 35 min | 15 min | 4 | medium |
| < 50 (insuffisant) | 25 min | 20 min | 2 | low |

---

### 3.4 💬 Module Chatbot RAG

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA / LLM"))
    API(("☁️ Gemini"))

    UC12["Uploader un document"]
    UC13["Poser une question RAG"]
    UC13g["Poser une question générale"]
    UC12l["Lister mes documents"]
    UC12d["Supprimer un document"]

    UC12a["Parser le document"]
    UC12b["Découper en chunks"]
    UC12c["Générer les embeddings"]
    UC12v["Valider CSV schedule"]
    UC13a["Recherche sémantique"]
    UC13b["Génération de réponse LLM"]

    User --> UC12
    User --> UC13
    User --> UC13g
    User --> UC12l
    User --> UC12d

    UC12 -.->|include| UC12a
    UC12 -.->|include PDF| UC12b
    UC12 -.->|include PDF| UC12c
    UC12 -.->|include CSV| UC12v

    UC13 -.->|include| UC13a
    UC13 -.->|include| UC13b

    IA --> UC13a
    API --> UC13b
    API --> UC12c
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC12 | Uploader un document | Utilisateur, IA | Connecté | **PDF :** 1. Sélectionner fichier PDF<br/>2. Upload multipart<br/>3. PyMuPDF extrait le texte<br/>4. Chunking + embeddings Gemini<br/>5. Stockage dans ChromaDB<br/><br/>**CSV :** 1. Sélectionner fichier CSV<br/>2. Validation colonnes (week, day, start, end, subject)<br/>3. Sauvegarde comme template emploi du temps | Document indexé (PDF) ou template validé (CSV) |
| UC13 | Poser une question RAG | Utilisateur, IA, Gemini | Document(s) uploadé(s) | 1. `POST /chatbot/chat` avec `question` + `document_ids[]`<br/>2. Recherche sémantique ChromaDB<br/>3. Chunks pertinents récupérés<br/>4. Gemini génère réponse contextualisée<br/>5. Réponse + sources affichées<br/>6. Échange sauvé en historique | Réponse affichée avec citations |
| UC13g | Question générale (sans doc) | Utilisateur, Gemini | Connecté | 1. `POST /chatbot/chat` avec `document_ids` vide<br/>2. Gemini répond directement sans RAG | Réponse IA directe |
| UC12l | Lister mes documents | Utilisateur | Documents existants | 1. `GET /chatbot/documents`<br/>2. Liste triée par date (desc) | Documents listés |
| UC12d | Supprimer un document | Utilisateur | Document existant | 1. `DELETE /chatbot/documents/{id}`<br/>2. Suppression : fichier disque + ChromaDB + DB (cascade messages, quiz, flashcards) | Document entièrement supprimé |

**Endpoints réels :**
- `POST /chatbot/upload` — Upload PDF ou CSV (multipart/form-data)
- `POST /chatbot/chat` — Question RAG ou générale
- `GET /chatbot/documents` — Lister les documents
- `DELETE /chatbot/documents/{id}` — Supprimer un document
- `GET /chatbot/history?limit=N` — Historique des échanges

---

### 3.5 🧠 Module Quiz

Le module quiz est désormais un routeur indépendant avec support multi-documents et génération depuis une session d'étude.

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA / LLM"))

    UC14["Générer quiz depuis document(s)"]
    UC14s["Générer quiz depuis session"]
    UC14sub["Soumettre réponses"]
    UC14l["Lister mes quiz"]
    UC14g["Consulter un quiz"]

    UC14a["Recherche sémantique multi-collections"]
    UC14b["Gemini génère questions QCM"]
    UC14c["Lien QuizDocumentLink créé"]

    User --> UC14
    User --> UC14s
    User --> UC14sub
    User --> UC14l
    User --> UC14g

    UC14 -.->|include| UC14a
    UC14 -.->|include| UC14b
    UC14 -.->|include| UC14c

    IA --> UC14a
    IA --> UC14b
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC14 | Générer quiz depuis document(s) | Utilisateur, IA | Document(s) PDF uploadé(s) | 1. `POST /quiz/generate` avec `document_id` ou `document_ids[]`, `num_questions` (3–30)<br/>2. Recherche sémantique dans ChromaDB<br/>3. Gemini génère les questions QCM avec options + réponse correcte + explication<br/>4. Quiz + QuizDocumentLink sauvés en DB | Quiz créé, réponses masquées |
| UC14s | Générer quiz depuis session | Utilisateur, IA | Session terminée avec documents liés | 1. `POST /quiz/generate-from-session/{session_id}`<br/>2. Récupère les documents de la session<br/>3. Génère le quiz (ou retourne l'existant) | Quiz de session créé |
| UC14sub | Soumettre réponses | Utilisateur | Quiz non soumis | 1. `POST /quiz/{id}/submit` avec `answers[]`<br/>2. Scoring : comparaison avec `correct_index`<br/>3. Score, pourcentage et corrections retournés | Quiz complété avec score |
| UC14l | Lister mes quiz | Utilisateur | Quiz existants | 1. `GET /quiz/list` | Liste de quiz |
| UC14g | Consulter un quiz | Utilisateur | Quiz existant | 1. `GET /quiz/{id}`<br/>2. Si non soumis : réponses masquées<br/>3. Si soumis : corrections visibles | Quiz affiché |

**Endpoints réels :**
- `POST /quiz/generate`
- `POST /quiz/generate-from-session/{session_id}`
- `GET /quiz/list`
- `GET /quiz/{quiz_id}`
- `POST /quiz/{quiz_id}/submit`

---

### 3.6 🃏 Module Flashcards SM-2

Le module flashcards utilise l'algorithme de répétition espacée SM-2. Il supporte la génération depuis des documents ou depuis des sessions d'étude terminées.

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA / LLM"))

    UC15["Générer flashcards depuis document(s)"]
    UC15s["Générer flashcards depuis session"]
    UC15r["Réviser une flashcard"]
    UC15d["Consulter les cartes dues"]
    UC15dk["Consulter un deck"]
    UC15del["Supprimer une flashcard"]

    UC15a["Gemini extrait concepts clés"]
    UC15b["SM-2 calcule next_review"]

    User --> UC15
    User --> UC15s
    User --> UC15r
    User --> UC15d
    User --> UC15dk
    User --> UC15del

    UC15 -.->|include| UC15a
    UC15r -.->|include| UC15b

    IA --> UC15a
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC15 | Générer flashcards depuis document(s) | Utilisateur, IA | Document(s) PDF uploadé(s) | 1. `POST /flashcards/generate` avec `document_id`/`document_ids[]`, `num_cards` (5–50)<br/>2. Gemini extrait concepts clés<br/>3. Flashcards créées avec `ease_factor=2.5`, `interval=1`, `next_review=now` | Deck de flashcards créé |
| UC15s | Générer flashcards depuis session | Utilisateur, IA | Session terminée avec documents | 1. `POST /flashcards/generate-from-session/{session_id}`<br/>2. Récupère documents liés à la session<br/>3. Génère (ou retourne existantes) | Deck de session créé |
| UC15r | Réviser une flashcard | Utilisateur | Carte due | 1. `POST /flashcards/{id}/review` avec `quality` (0–5)<br/>2. SM-2 calcule : `repetitions`, `ease_factor`, `interval`, `next_review`<br/>3. Carte mise à jour | Prochaine révision planifiée |
| UC15d | Consulter cartes dues | Utilisateur | Flashcards existantes | 1. `GET /flashcards/due`<br/>2. Retourne cartes avec `next_review ≤ now` | Cartes dues listées |
| UC15dk | Consulter un deck | Utilisateur | Document existant | 1. `GET /flashcards/deck/{document_id}` ou `GET /flashcards/deck/session/{session_id}` | Deck affiché |
| UC15del | Supprimer une flashcard | Utilisateur | Carte existante | 1. `DELETE /flashcards/{id}` | Carte supprimée |

**Endpoints réels :**
- `POST /flashcards/generate`
- `POST /flashcards/generate-from-session/{session_id}`
- `GET /flashcards/deck/{document_id}`
- `GET /flashcards/deck/session/{session_id}`
- `GET /flashcards/due`
- `POST /flashcards/{card_id}/review`
- `DELETE /flashcards/{card_id}`

**Algorithme SM-2 :**

| Quality (0–5) | Signification | Effet |
|:---:|---|---|
| 0 | Blackout total | Reset repetitions, interval=1 |
| 1 | Incorrect, mais reconnu après | Reset repetitions, interval=1 |
| 2 | Incorrect, mais facile après | Reset repetitions, interval=1 |
| 3 | Correct, difficulté sérieuse | interval = interval × ease_factor |
| 4 | Correct, quelque hésitation | interval = interval × ease_factor |
| 5 | Rappel parfait | interval = interval × ease_factor |

---

### 3.7 🧍 Module Posture & Ergonomie

```mermaid
graph LR
    User(("👤 Utilisateur"))
    ESP32(("📟 ESP32"))
    ML(("🧠 ML Vision"))

    UC17["Détecter la posture"]
    UC18["Recevoir alerte posture"]
    UC19["Voir stats posture"]
    UC20["Recevoir conseils ergonomiques"]

    UC17a["Capturer image"]
    UC17b["Analyser via MediaPipe"]

    ESP32 --> UC17a
    ML --> UC17b

    User --> UC19
    User --> UC20

    UC17 -.->|include| UC17a
    UC17 -.->|include| UC17b
    UC17 -.->|extend| UC18

    ESP32 --> UC18
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC17 | Détecter la posture | ESP32, ML | Session active | 1. Caméra capture image<br/>2. MediaPipe analyse la posture<br/>3. Résultat envoyé à l'app | Posture évaluée |
| UC18 | Recevoir alerte posture | ESP32, Utilisateur | Mauvaise posture détectée | 1. ML détecte dos courbé<br/>2. LED orange sur boîtier<br/>3. Vibration douce<br/>4. Notification mobile | Utilisateur alerté |
| UC19 | Voir stats posture | Utilisateur | Données collectées | 1. Ouvrir Statistiques<br/>2. Voir % bonne posture<br/>3. Évolution par jour/semaine | Stats affichées |
| UC20 | Recevoir conseils | Utilisateur, IA | Historique posture | 1. Analyse patterns<br/>2. IA génère conseils<br/>3. Recommandations affichées | Conseils reçus |

> ⚠️ Ce module dépend de l'intégration hardware ESP32 (Personne 1).

---

### 3.8 🌙 Module Sommeil & Réveil

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA"))

    UC21["Enregistrer données sommeil"]
    UC22["Consulter score sommeil"]
    UC22h["Consulter l'historique sommeil"]
    UC23["Configurer réveil intelligent"]
    UC24["Adapter le planning"]

    UC23a["Choisir le mode de réveil"]
    UC23b["Régler intensité lumineuse"]
    UC23c["Activer/désactiver le son"]

    User --> UC21
    User --> UC22
    User --> UC22h
    User --> UC23

    UC23 -.->|include| UC23a
    UC23 -.->|include| UC23b
    UC23 -.->|extend| UC23c

    UC22 -.->|extend| UC24
    IA --> UC24
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC21 | Enregistrer sommeil | Utilisateur | Connecté | 1. `POST /api/v1/sleep/log` avec `sleep_start`, `sleep_end`<br/>2. Calcul automatique `total_hours` et `sleep_score` (0–100) | Nuit enregistrée |
| UC22 | Score sommeil | Utilisateur | Données de nuit | 1. `GET /api/v1/sleep/stats?period=week\|month`<br/>2. Moyenne heures, score moyen, tendance | Stats consultées |
| UC22h | Historique sommeil | Utilisateur | Nuits enregistrées | 1. `GET /api/v1/sleep/history?limit=30`<br/>2. Liste des enregistrements | Historique affiché |
| UC23 | Réveil intelligent | Utilisateur | Connecté | 1. `PUT /api/v1/sleep/alarm` avec `alarm_time` (HH:MM), `wake_mode` (gradual\|normal\|silent), `light_intensity` (0–100), `sound_enabled`<br/>2. Alarme locale Flutter (`alarm: ^5.2.1`) | Alarme configurée |
| UC24 | Adapter planning | IA | Score sommeil disponible | 1. Score < 50 détecté<br/>2. Planning réduit : 25min/session, max 2<br/>3. Pauses de 20min | Planning adapté |

**Endpoints réels :**
- `POST /api/v1/sleep/log`
- `GET /api/v1/sleep/stats`
- `GET /api/v1/sleep/history`
- `PUT /api/v1/sleep/alarm`
- `GET /api/v1/sleep/alarm`

---

### 3.9 📊 Module Dashboard & Statistiques

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA"))

    UC27["Dashboard global"]
    UC28["Stats hebdomadaires"]
    UC29["Conseils personnalisés"]

    UC27a["Score focus du jour"]
    UC27b["Score sommeil"]
    UC27c["Prochaine session"]
    UC27d["Graphiques fl_chart"]

    User --> UC27
    User --> UC28

    UC27 -.->|include| UC27a
    UC27 -.->|include| UC27b
    UC27 -.->|include| UC27c
    UC27 -.->|include| UC27d

    UC28 -.->|extend| UC29
    IA --> UC29
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC27 | Dashboard global | Utilisateur | Connecté | 1. Ouvrir l'app<br/>2. Voir scores du jour<br/>3. Alertes récentes<br/>4. Prochaine session | Vue d'ensemble |
| UC28 | Stats hebdomadaires | Utilisateur | Données collectées | 1. Ouvrir Statistiques<br/>2. Graphiques par semaine (fl_chart)<br/>3. Tendances et progrès | Progrès visualisés |
| UC29 | Conseils personnalisés | Utilisateur, IA | Historique suffisant | 1. IA analyse les patterns (via `/planning/insights`)<br/>2. Détecte heures productives<br/>3. Identifie corrélation sommeil/productivité<br/>4. Génère recommandation personnalisée | Conseils affichés |

---

## 4. Matrice Acteurs / Cas d'Utilisation

| Cas d'Utilisation | 👤 Utilisateur | 📟 ESP32 | 🧠 ML Vision | 🤖 IA/LLM | ☁️ Gemini |
|-------------------|:-:|:-:|:-:|:-:|:-:|
| S'inscrire | ✅ | | | | |
| Se connecter | ✅ | | | | |
| Gérer profil | ✅ | | | | |
| Rafraîchir token | ✅ | | | | |
| Démarrer session focus | ✅ | ✅ | ✅ | | |
| Voir score temps réel | ✅ | | ✅ | | |
| Alerte concentration | ✅ | ✅ | ✅ | | |
| Historique sessions | ✅ | | | | |
| Consulter planning | ✅ | | | | |
| Générer planning IA (jour) | ✅ | | | ✅ | ✅ |
| Générer planning IA (semaine) | ✅ | | | ✅ | ✅ |
| Modifier session | ✅ | | | | |
| Marquer session terminée | ✅ | | | | |
| Replanifier session manquée | ✅ | | | | |
| Supprimer session | ✅ | | | | |
| Consulter insights planning | ✅ | | | ✅ | |
| Créer un examen | ✅ | | | | |
| Supprimer un examen | ✅ | | | | |
| Uploader document (PDF/CSV) | ✅ | | | | ✅ |
| Question RAG (sur document) | ✅ | | | ✅ | ✅ |
| Question générale (sans doc) | ✅ | | | | ✅ |
| Lister documents | ✅ | | | | |
| Supprimer document | ✅ | | | | |
| Générer quiz (document) | ✅ | | | ✅ | ✅ |
| Générer quiz (session) | ✅ | | | ✅ | ✅ |
| Soumettre réponses quiz | ✅ | | | | |
| Lister quiz | ✅ | | | | |
| Générer flashcards (document) | ✅ | | | ✅ | ✅ |
| Générer flashcards (session) | ✅ | | | ✅ | ✅ |
| Réviser flashcard (SM-2) | ✅ | | | | |
| Consulter cartes dues | ✅ | | | | |
| Supprimer flashcard | ✅ | | | | |
| Détecter posture | | ✅ | ✅ | | |
| Alerte posture | ✅ | ✅ | ✅ | | |
| Stats posture | ✅ | | | | |
| Conseils ergonomiques | ✅ | | | ✅ | |
| Enregistrer sommeil | ✅ | | | | |
| Score sommeil / stats | ✅ | | | | |
| Historique sommeil | ✅ | | | | |
| Configurer réveil | ✅ | | | | |
| Adapter planning/sommeil | | | | ✅ | |
| Dashboard global | ✅ | | | | |
| Stats hebdomadaires | ✅ | | | | |
| Conseils personnalisés | ✅ | | | ✅ | ✅ |

---

## 5. Résumé des Cas d'Utilisation

| Module | Nombre de CU | Priorité | Statut |
|--------|:---:|:---:|:---:|
| 🔐 Authentification | 4 | Haute | ✅ Implémenté |
| 🎯 Focus & Concentration | 4 | Haute | ⚠️ En attente hardware |
| 📅 Planning Intelligent | 10 | Haute | ✅ Implémenté |
| 💬 Chatbot RAG | 5 | Haute | ✅ Implémenté |
| 🧠 Quiz | 5 | Haute | ✅ Implémenté |
| 🃏 Flashcards SM-2 | 6 | Haute | ✅ Implémenté |
| 🧍 Posture & Ergonomie | 4 | Moyenne | ⚠️ En attente hardware |
| 🌙 Sommeil & Réveil | 5 | Moyenne | ✅ Implémenté |
| 📊 Dashboard & Stats | 3 | Haute | ✅ Implémenté |
| **Total** | **46** | | |

---

## 6. Changements depuis la version 1.0

| Élément | Avant (v1.0) | Après (v2.0) |
|---------|-------------|-------------|
| LLM Provider | OpenAI API (GPT-3.5/4) | Google Gemini 2.5 Flash |
| Embeddings | text-embedding-3 (OpenAI) | text-embedding-004 (Gemini) |
| Planning | 4 CU simples | 10 CU (semaine, reschedule, exams, insights, adaptation sommeil) |
| Quiz | Sous-module chatbot (1 CU) | Module indépendant (5 CU, multi-docs, depuis session) |
| Flashcards | Sous-module chatbot (2 CU) | Module indépendant (6 CU, SM-2, depuis session, decks) |
| Chatbot upload | PDF uniquement | PDF + CSV (emploi du temps) |
| Sommeil | 4 CU | 5 CU (ajout historique) |
| Auth | 3 CU | 4 CU (ajout refresh token) |
| Total CU | 29 | 46 |

---

*Mis à jour le 9 Avril 2026 — Smart Focus & Life Assistant*
