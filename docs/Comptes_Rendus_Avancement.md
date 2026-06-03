# Comptes Rendus d'Avancement – Smart Focus & Life Assistant

**Projet** : Smart Focus & Life Assistant  
**Responsable** : Kacem Jemni – Application Mobile, Backend & IA  
**Période couverte** : 03 Février 2026 – 30 Mai 2026  
**Nombre de comptes rendus** : 17

---

---

## Compte Rendu N°1
**Période** : Du 3 février 2026 au 10 février 2026  
**Responsable** : Kacem Jemni  
**Thème** : Formation Flutter Express – Fondations techniques

---

### Travaux réalisés

Cette première semaine a été entièrement consacrée à la formation intensive Flutter/Dart afin d'acquérir les bases nécessaires au développement de l'application mobile Smart Focus.

**Formation Flutter (Cours Udemy – Maximilian Schwarzmüller) :**
- Section 1 & 2 : Introduction au framework Flutter et fondamentaux du langage Dart (types, fonctions, classes, null-safety)
- Section 3 & 4 : Approfondissement Flutter Basics II et prise en main du débogage (Flutter DevTools, hot reload, breakpoints)
- Section 5 & 6 : Ajout d'interactivité (setState, gestion des événements) et construction d'interfaces responsives/adaptatives
- Section 7 & 8 : Fonctionnement interne de Flutter (widget tree, element tree, render tree) et navigation multi-écrans
- Section 10 : Connexion à une API REST, envoi de requêtes HTTP avec le package `http`
- Section 13 : Gestion d'état avancée avec **Riverpod** (StateNotifier, ConsumerWidget, Provider)

**Mini-projet de validation :**
- Développement d'une petite application Flutter qui consomme une API externe (JSONPlaceholder), affiche une liste d'items et gère l'état avec Riverpod

### Difficultés rencontrées

- Courbe d'apprentissage initiale sur la syntaxe Dart (null safety, async/await)
- Compréhension du cycle de vie des widgets Flutter
- Configuration initiale de l'environnement de développement (Android Studio, émulateur)

### Décisions techniques

- Adoption de **Riverpod** comme solution de gestion d'état (rejet de Provider standard et Bloc pour leur complexité)
- Choix de **GoRouter** anticipé pour la navigation centralisée
- Architecture Feature-First (Clean Architecture) définie conceptuellement

### Objectifs semaine suivante

- Maîtriser FastAPI et le développement backend Python
- Acquérir les bases des LLM, RAG et LangChain
- Être capable de construire un chatbot fonctionnel sur des documents PDF

---

---

## Compte Rendu N°2
**Période** : Du 10 février 2026 au 17 février 2026  
**Responsable** : Kacem Jemni  
**Thème** : Formation Backend & Intelligence Artificielle (FastAPI, LangChain, RAG)

---

### Travaux réalisés

Cette deuxième semaine a couvert la formation accélérée sur les technologies backend et IA qui constituent le cœur intelligent de l'application.

**Formation FastAPI :**
- First Steps : création d'une API Hello World, compréhension de l'ASGI/Uvicorn
- Path Parameters & Query Parameters : routes dynamiques, filtres
- Request Body & Response Model : validation avec Pydantic, schémas de données
- SQL Databases : intégration PostgreSQL avec SQLAlchemy (sessions, modèles, migrations)
**Formation IA & LLM (DeepLearning.AI) :**
- *ChatGPT Prompt Engineering for Developers* (1.5h) : techniques de prompt, zero-shot, few-shot, chain-of-thought
- *LangChain for LLM Application Development* (3h) : Models, Memory, Chains, Q&A, Evaluation, Agents
- *Retrieval Augmented Generation* (3h) : architecture RAG, indexation, retrieval, génération augmentée
- *LangChain: Chat with Your Data* (4h) : Document Loading, Text Splitting, Embeddings, VectorStore, Q&A, Chat avec mémoire

**Test de validation :**
- Mise en place d'un prototype RAG local : upload d'un PDF → chunking → embeddings OpenAI → stockage ChromaDB → réponses contextuelles
- Le chatbot répond correctement aux questions posées sur un document de cours

### Difficultés rencontrées

- Coût des tokens OpenAI lors des tests intensifs
- Paramétrage optimal du chunk size et overlap pour la qualité des réponses
- Configuration de l'environnement Python avec les dépendances LangChain

### Décisions techniques

- Adoption de **ChromaDB** comme base vectorielle locale (pas de dépendance cloud)
- Utilisation de **LangChain** comme framework d'orchestration RAG
- Évaluation de l'alternative Gemini vs OpenAI pour les embeddings (décision finale reportée)

### Objectifs semaine suivante

- Démarrer le développement du MVP : Dashboard, Planning, Chatbot
- Connecter Flutter au backend FastAPI avec Dio
- Construire l'interface utilisateur principale

---

---

## Compte Rendu N°3
**Période** : Du 17 février 2026 au 24 février 2026  
**Responsable** : Kacem Jemni  
**Thème** : Développement du MVP – Dashboard, Planning, Chatbot (Phase application)

---

### Travaux réalisés

Cette troisième semaine marque le début du développement effectif de l'application. L'objectif était de livrer un MVP (Minimum Viable Product) fonctionnel avec les trois écrans principaux.

**Dashboard Flutter :**
- Layout principal de l'application avec BottomNavigationBar
- Score Circle Widget animé (affichage du score de focus en pourcentage)
- Intégration de `fl_chart` pour les graphiques de progression
- Alertes visuelles et indicateurs d'état

**Écran Planning :**
- Structure de l'écran Planning avec vue calendrier
- Cards de sessions de travail avec statut (en attente / en cours / terminé)
- Formulaire de création de session manuelle

**Écran Chatbot :**
- Interface de conversation (bulles de messages, champ de saisie, scroll automatique)
- Upload de fichiers PDF depuis l'application Flutter
- Liste des documents uploadés

**Backend FastAPI :**
- Endpoints Focus : `POST /focus/session`, `PUT /focus/session/{id}/update`
- Endpoints Planning : `GET /planning/today`, `POST /planning/generate`
- Intégration RAG dans un endpoint `/chatbot/ask`

**Connexion Flutter ↔ Backend :**
- Service HTTP avec `Dio` : intercepteurs d'authentification, gestion des erreurs
- Tests de connexion complète entre l'app Flutter et le backend FastAPI

### Difficultés rencontrées

- Problèmes CORS entre Flutter (émulateur Android) et le serveur FastAPI local
- Gestion des tokens JWT dans Dio (intercepteur de refresh token)
- Formatage des données JSON entre Flutter et Python

### Objectifs semaine suivante

- Finaliser l'écran Statistiques
- Mettre en place l'écran Paramètres et les notifications locales

---

---

## Compte Rendu N°4
**Période** : Du 24 février 2026 au 3 mars 2026  
**Responsable** : Kacem Jemni  
**Thème** : Finition MVP – Statistiques, Paramètres, Intégration Hardware

---

### Travaux réalisés

Cette quatrième semaine clôture la phase de formation et de MVP initial, avec la finalisation des fonctionnalités complémentaires.

**Écran Statistiques :**
- Dashboard de statistiques avec historique focus, posture et sommeil
- Graphiques barres (performance hebdomadaire) et courbes (évolution du score)
- Calcul et affichage des moyennes et tendances

**Écran Paramètres :**
- Formulaire de profil utilisateur (objectif focus, horaires préférés)
- Configuration des notifications
- Stockage local des préférences avec **Hive**

**Notifications locales :**
- Intégration du package `flutter_local_notifications`
- Déclenchement d'alertes en cas de score focus bas ou mauvaise posture détectée

**Simulation Hardware (Mock Raspberry) :**
- Service de simulation qui génère des données Raspberry fictives toutes les 5 secondes
- Format JSON conforme au contrat API : `{ focus_score, posture_ok, heart_rate, fatigue_level, blink_rate, face_detected }`

**Polish & Documentation :**
- Corrections de bugs identifiés lors des tests
- Rédaction du README de base du projet

### Bilan de la phase formation/MVP (4 semaines)

- Formation complète acquise : Flutter, FastAPI, LangChain, RAG
- MVP opérationnel avec 4 écrans (Dashboard, Planning, Chatbot, Statistiques)
- Architecture technique validée

### Objectifs prochaine période

- Démarrer la Phase 1 officielle : refonte architecture en Feature-First Clean Architecture
- Mettre en place l'authentification JWT complète
- Migrer le projet vers une structure de code professionnelle

---

---

## Compte Rendu N°5
**Période** : Du 3 mars 2026 au 10 mars 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 1 – Setup, Architecture & Infrastructure (Semaine 1 de développement)

---

### Travaux réalisés

Début de la Phase 1 de développement officielle. Cette semaine est dédiée à la mise en place d'une architecture propre et professionnelle pour le projet complet.

**Setup projet Flutter (Architecture Feature-First) :**
- Initialisation du projet Flutter avec la structure `lib/features/`, `lib/core/`, `lib/shared/`
- Configuration des dépendances dans `pubspec.yaml` : `flutter_riverpod ^3.2.1`, `dio ^5.9.1`, `go_router ^17.1.0`, `fl_chart ^1.1.1`, `hive ^2.2.3`, `google_fonts ^8.0.2`
- Mise en place du **Design System** : thème centralisé dans `lib/core/theme/`, palette de couleurs, typographie Google Fonts (Inter)
- Navigation centralisée avec **GoRouter** dans `lib/core/router/`

**Setup Backend FastAPI :**
- Structure du backend : `app/routers/`, `app/models/`, `app/schemas/`, `app/services/`, `app/utils/`
- Configuration `main.py` avec CORS, Swagger UI (`/docs`), ReDoc (`/redoc`)
- Endpoints de santé : `GET /` et `GET /health`
- Configuration `pydantic-settings` pour la gestion du fichier `.env`

**Base de données PostgreSQL :**
- Modèles SQLAlchemy : `User`, `UserProfile`
- Configuration des migrations avec **Alembic**
- Fonction `ensure_schema_compatibility()` au démarrage pour valider la cohérence du schéma

**Base vectorielle ChromaDB :**
- Initialisation du dossier `chroma_db/`
- Configuration automatique au démarrage de l'application

### Difficultés rencontrées

- Choix de la structure d'architecture Flutter (Feature-First vs Layer-First) → décision en faveur de Feature-First pour la scalabilité
- Configuration des migrations Alembic avec PostgreSQL en environnement de développement Windows

### Objectifs semaine suivante

- Implémenter l'authentification complète (Backend JWT + Flutter screens)
- Dashboard UI avancé
- Connexion Flutter ↔ Backend Auth

---

---

## Compte Rendu N°6
**Période** : Du 10 mars 2026 au 17 mars 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 1 – Authentification Backend & Flutter (Semaine 2)

---

### Travaux réalisés

Cette semaine est centrée sur l'implémentation de l'authentification complète, composant critique pour la sécurité de l'application.

**Authentification Backend (`routers/auth.py`) :**
- `POST /api/v1/auth/register` : inscription utilisateur avec validation email et hash bcrypt (`passlib[bcrypt]`)
- `POST /api/v1/auth/login` : authentification, génération de paires access token / refresh token JWT (`python-jose`)
- `GET /api/v1/auth/me` : récupération du profil courant
- `PUT /api/v1/auth/me/profile` : mise à jour des préférences utilisateur (objectif focus, horaires, notifications)
- Middleware `get_current_user` dans `deps.py` pour la protection des routes

**Tables base de données :**
- Table `users` : email, password_hash, rôle, statut, date de création
- Table `user_profiles` : objectif focus, heures préférées (matin/après-midi/soir), préférences notifications, schedule hebdomadaire

**Application Flutter – Feature Auth :**
- Écran Welcome (`features/auth/`) avec navigation vers Login ou Register
- Formulaire de connexion `login_screen.dart`, `login_form.dart` avec validation des champs
- Formulaire d'inscription `sign_form.dart` avec confirmation de mot de passe
- Stockage sécurisé du JWT access token avec Hive
- Auto-login au démarrage si token valide

**Dashboard UI (structure) :**
- Layout principal avec `BottomNavigationBar` (5 onglets : Dashboard, Planning, Chatbot, Stats, Paramètres)
- Structure des providers Riverpod dans chaque feature
- Navigation GoRouter configurée avec redirection auth

### Difficultés rencontrées

- Gestion du refresh token dans Flutter (intercepteur Dio avec retry sur 401)
- Configuration CORS correcte pour autoriser les requêtes depuis l'émulateur Android (`10.0.2.2`)

### Objectifs semaine suivante

- Finaliser la connexion Flutter ↔ Backend
- Implémenter le service RAG (Chatbot)
- Premier push git du projet

---

---

## Compte Rendu N°7
**Période** : Du 17 mars 2026 au 24 mars 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 1 finalisée – RAG Chatbot, Premier push Git (Semaine 3)

---

### Travaux réalisés

Semaine cruciale qui marque le **premier commit git** du projet (22 mars 2026) et la livraison de la Phase 1 complète avec le service RAG opérationnel.

**Premier push git (22 mars 2026) :**
- Commit initial : structure complète du projet Flutter + Backend FastAPI + ChromaDB
- Backend avec `main.py`, CORS, `app/routers/auth.py`, `app/routers/chatbot.py`, `app/routers/users.py`
- Services : `document_service.py`, `rag_service.py` (~19 Ko)
- Documentation initiale : Cahier de charges, architecture système, cas d'utilisation, diagrammes

**Service RAG (`services/rag_service.py`) :**
- Upload et parsing de documents **PDF** (PyMuPDF) et **CSV** (emplois du temps)
- Validation des colonnes CSV : `week, day, start, end, subject`
- Découpage en chunks avec overlap, génération des embeddings avec **Gemini `text-embedding-004`** (migration depuis OpenAI pour réduire les coûts)
- Stockage vectoriel dans ChromaDB, recherche sémantique top-k
- `POST /chatbot/chat` : Q&A sur documents avec contexte RAG
- Support des requêtes générales sans document (fallback IA directe)

**Chatbot général (22 mars 2026) :**
- Mode conversationnel sans document : Gemini répond directement si `document_ids` vide
- Historique de chat par utilisateur : `GET /chatbot/history?limit=N`, isolation par `user_id`
- Liste & suppression de documents : `GET /chatbot/documents`, `DELETE /chatbot/documents/{id}`
- Suppression en cascade : base de données + fichiers disque + collection ChromaDB

**Mise à jour "First update" (22 mars 2026) :**
- Corrections et stabilisation post-premier push
- Ajout de la documentation architecture système

### Difficultés rencontrées

- Migration des embeddings d'OpenAI vers Gemini `text-embedding-004` : dimensions vectorielles différentes, nécessite réindexation
- Isolation de l'historique chat par utilisateur (bug d'affichage entre utilisateurs différents)
- Taille du fichier `rag_service.py` : complexité croissante du service

### Objectifs semaine suivante

- Développer le module Sleep Tracking complet
- Implémenter les fonctionnalités Quiz & Flashcards
- Démarrer le module Planning avec les routeurs backend

---

---

## Compte Rendu N°8
**Période** : Du 24 mars 2026 au 31 mars 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 2 – Sleep Tracking, Quiz/Flashcards, Planning Backend (Semaine 4)

---

### Travaux réalisés

Cette semaine de grande productivité voit l'implémentation de trois modules majeurs : le suivi du sommeil, les fonctionnalités d'apprentissage (Quiz/Flashcards) et les bases du Planning.

**Quiz & Flashcards (23 mars 2026) :**
- `routers/quiz.py` (~10 Ko) : génération de QCM depuis PDF via Gemini, soumission et score avec corrections expliquées
- `routers/flashcard.py` (~11 Ko) : CRUD flashcards avec algorithme de répétition espacée **SM-2** (`services/sm2_service.py`)
- Champs SM-2 : `ease_factor`, `interval`, `repetitions`, `next_review`
- `QuizDocumentLink` : liaison M2M quiz ↔ plusieurs documents sources
- Interface Flutter Quiz : `features/quiz/` (models, providers, screens, services)
- Interface Flutter Flashcards : `features/flashcards/` (models, providers, screens, services)
- Design Glassmorphism cohérent avec le système de design global

**Sleep Tracking (26 mars 2026 – addition des routeurs sommeil) :**
- `POST /api/v1/sleep/log` : enregistrement d'une nuit avec calcul automatique du `sleep_score` (0-100)
- `GET /api/v1/sleep/stats?period=week|month` : statistiques hebdomadaires et mensuelles
- `GET /api/v1/sleep/history?limit=N` : historique des nuits
- Tables : `sleep_records`, `smart_alarms`

**Alarme intelligente (27 mars 2026 – "Alarm works perfectly") :**
- `PUT /api/v1/sleep/alarm` : configuration de l'alarme (mode gradual / normal / silent)
- `GET /api/v1/sleep/alarm` : lecture de la configuration
- Intégration du package Flutter `alarm: ^5.2.1` pour les alarmes natives
- Notifications locales avec `flutter_local_notifications`

**Planning Backend – Routeurs (31 mars 2026) :**
- Routeurs du module planning fonctionnels : `routers/planning.py`
- `GET /api/v1/planning/today` : planning du jour
- `GET /api/v1/planning/{date}` : planning par date
- CRUD sessions : `POST /sessions`, `PATCH /sessions/{id}`, `DELETE /sessions/{id}`

### Difficultés rencontrées

- Implémentation fidèle de l'algorithme SM-2 (calcul du facteur ease et des intervalles)
- Calcul du `sleep_score` : pondération entre durée, qualité, régularité
- Correction du bug de highlighting de la navigation bottom bar

### Objectifs semaine suivante

- Finaliser le Planning UI Flutter
- Implémenter la génération IA du planning avec Gemini
- Ajouter quiz et flashcards aux sessions terminées

---

---

## Compte Rendu N°9
**Période** : Du 31 mars 2026 au 7 avril 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 2 – Planning IA, Génération intelligente, Stabilisation (Semaine 5)

---

### Travaux réalisés

Semaine d'intense développement sur le module Planning, qui devient le composant le plus avancé du projet.

**Planning UI Flutter (1er avril 2026) :**
- Interface complète du planning dans `features/planning/`
- Vue calendrier avec sessions du jour/semaine
- Cartes de sessions avec statut, durée, sujet
- Correction du bug RAG identifié dans la section chatbot

**Génération Planning IA – Premier routeur (1er avril 2026) :**
- `POST /api/v1/planning/generate` : génération quotidienne avec **Gemini 2.5 Flash**
- Parsing du résultat LLM : regex JSON + validation stricte pour éviter les hallucinations
- Intégration des blocs fixes (emploi du temps) pour éviter les chevauchements
- Buffer de 15 minutes entre sessions

**Quiz & Flashcards liés aux sessions (2 avril 2026) :**
- Ajout automatique d'une session quiz et d'une révision flashcard à chaque session terminée
- Liaison `study_session_documents` : M2M sessions ↔ documents

**4 nouvelles fonctionnalités Planning (3 avril 2026) :**
- Génération hebdomadaire `POST /generate/week` : 7 jours en une requête
- Profil sommeil → paramètres sessions (score ≥80 → 50min ; score <50 → 25min/2 sessions)
- Rotation pondérée (Weighted Round-Robin) pour équilibrer les matières
- `POST /planning/reschedule/{id}` : replanification des sessions manquées (J et J+1)

**Fix émulateur Android (4 avril 2026) :**
- Résolution du problème réseau émulateur : adresse `10.0.2.2` au lieu de `localhost`
- Connexion Flutter ↔ Backend validée sur émulateur

**Version Planning stable + multi-documents (5 avril 2026) :**
- Sélection de plusieurs documents pour générer le planning
- Version stable validée du module planning

**Stabilisation des sections + Fix dépendances (7 avril 2026) :**
- Stabilisation de toutes les sections de l'application
- Résolution de conflits de dépendances Python

### Difficultés rencontrées

- Parsing du JSON généré par le LLM : sorties parfois malformées → implémentation de regex robustes
- Chevauchement des sessions générées avec les blocs fixes de l'emploi du temps
- Compatibilité des dépendances Python (LangChain, ChromaDB, FastAPI versions)

### Objectifs semaine suivante

- Migration vers Gemini 2.5 Flash optimisé
- Amélioration du module planning (révisions examens, flashcards dues)
- Mise à jour des paramètres utilisateur

---

---

## Compte Rendu N°10
**Période** : Du 7 avril 2026 au 14 avril 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 2 – Planning Avancé, Gemini Optimisation, Paramètres (Semaine 6)

---

### Travaux réalisés

Cette semaine apporte des améliorations significatives à l'intelligence du module planning et à l'expérience utilisateur des paramètres.

**Optimisation Planning avec Gemini (13 avril 2026 – "Updating the planning (Gemini reduce)") :**
- Réduction des tokens Gemini utilisés par requête de planning (optimisation du prompt)
- Extraction déterministe de l'emploi du temps depuis CSV : `services/schedule_parser.py` (Semaine A/B)
- Extraction timetable depuis PDF (RAG) : ChromaDB + Gemini en fallback si pas de CSV
- Révisions d'examens : intensité selon `days_until_exam` (≤2j → intensité max, ≤6j → haute, ≤14j → normale, >14j → légère)
- Révisions flashcards SM-2 dues insérées automatiquement dans le planning du jour
- Révisions quiz ciblées : `weakness_score` → priorité haute si score ≥ 0.6
- Calcul de la corrélation sommeil ↔ productivité : `_compute_sleep_study_correlation()`
- Signaux de sessions reportées/annulées : `_collect_postponed_course_signals()` → boost de poids
- Sweep hebdomadaire du week-end : toutes les matières de la semaine revisitées

**Insights & Statistiques planning :**
- `GET /api/v1/planning/insights?period=week|month` : statistiques et recommandations personnalisées

**Mise à jour Paramètres (14 avril 2026 – "settings Updated") :**
- Écran Paramètres enrichi dans `features/settings/`
- Mise à jour du profil utilisateur : objectif focus, heures préférées, préférences notifications
- `PUT /api/v1/auth/me/profile` : endpoint mis à jour avec les nouveaux champs

**Module Planning – Taille atteinte :**
- `routers/planning.py` atteint **1701 lignes** de code, module le plus complexe du projet

### Difficultés rencontrées

- Optimisation du prompt Gemini pour réduire la consommation de tokens sans dégrader la qualité
- Implémentation correcte du parser CSV avec gestion des semaines A/B alternées
- Calcul des créneaux libres (`_compute_free_slots()`) entre 8h et 22h sans chevauchement

### Objectifs semaine suivante

- Implémenter l'authentification Google (Gmail Sign-In)
- Améliorer le modèle LLM pour le planning
- Envoyer les données de session en temps réel

---

---

## Compte Rendu N°11
**Période** : Du 14 avril 2026 au 21 avril 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 3 – Authentification Google, Données Temps Réel, Modèle Planning (Semaine 7)

---

### Travaux réalisés

Entrée dans la Phase 3 (IA Avancée) avec l'implémentation de fonctionnalités de temps réel et l'exploration de l'authentification Google.

**Premier essai authentification Gmail (17 avril 2026 – "First gmail sign in try") :**
- Intégration du package `google_sign_in` dans Flutter
- Configuration OAuth 2.0 côté backend FastAPI
- Premier flux d'authentification Google testé (preuve de concept)
- Liaison compte Google ↔ compte utilisateur local

**Correction problème de modèle LLM (19 avril 2026 – "fixed the model issue") :**
- Identification et correction d'un bug de sélection du modèle Gemini
- Le modèle `gemini-2.5-flash` n'était pas correctement instancié dans certains cas
- Stabilisation du service de génération de planning

**Mise à jour du modèle Planning (20 avril 2026 – "updating the planning(model)") :**
- Refactoring du modèle de données des sessions de planning
- Ajout du champ `real_time_data` aux sessions de travail
- Liaison entre sessions et données capteurs temps réel

**Envoi de données temps réel vers les sessions (20 avril 2026 – "sending real time data to the session upgrade") :**
- Endpoint d'update de session en temps réel : données capteurs (score focus, posture, FC)
- Stockage des données de session pour l'analyse historique
- Calcul du score de focus moyen par session

### Difficultés rencontrées

- Complexité de l'OAuth 2.0 Google avec FastAPI (gestion des tokens Google vs JWT interne)
- Gestion des sessions concurrentes dans le backend

### Objectifs semaine suivante

- Activer le planning temps réel (mise à jour dynamique)
- Améliorer les statistiques et données en temps réel
- Préparer la version stable avec gestion des sessions de détection

---

---

## Compte Rendu N°12
**Période** : Du 21 avril 2026 au 28 avril 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 3 – Planning Temps Réel, Statistiques Avancées (Semaine 8)

---

### Travaux réalisés

Semaine centrée sur l'activation du planning dynamique en temps réel et l'amélioration des statistiques.

**Mise à jour données et statistiques temps réel (26 avril 2026 – "updating the real time data and stats feature") :**
- Service de calcul du score de focus en temps réel basé sur les données capteurs
- Statistiques enrichies : durée effective de concentration, pauses détectées, bâillements
- `GET /api/v1/planning/insights` enrichi avec les métriques temps réel des sessions
- Dashboard Flutter mis à jour pour afficher les données live

**Activation du Planning Temps Réel (28 avril 2026 – "real time planning activated") :**
- Le planning se régénère automatiquement en tenant compte des sessions terminées en temps réel
- Ajustement dynamique des sessions futures basé sur la performance de la session courante
- Si score focus < 40% → insertion d'une pause dans les sessions suivantes
- Notification Flutter lors de la régénération automatique du planning

### Difficultés rencontrées

- Gestion des conflits de données lors des mises à jour simultanées
- Consommation CPU lors du calcul continu du score de focus

### Objectifs semaine suivante

- Stabiliser la version avec démarrage conditionnel de la détection
- Résoudre les problèmes identifiés avec les sessions
- Livrer une version stable testable

---

---

## Compte Rendu N°13
**Période** : Du 28 avril 2026 au 5 mai 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 3 – Stabilisation, Gestion des Sessions, Version Stable (Semaine 9)

---

### Travaux réalisés

Cette semaine a été marquée par un cycle de debug intense : activation d'une fonctionnalité → identification de problèmes → revert → correction propre → version stable.

**Planning Temps Réel (activé puis revert – 28-29 avril 2026) :**
- Commit "real time planning activated" (28 avril) : fonctionnalité activée
- Identification de problèmes critiques avec les sessions : sessions dupliquées, conflits de planification
- Commits de revert (29 avril) : "Revert 'real time planning activated'" et "Revert 'problems with the sessions'"
- Cette approche de revert propre préserve l'historique git et permet de repartir sur une base saine

**Correction des problèmes de sessions (29 avril 2026 – "problems with the sessions") :**
- Identification du bug : la détection s'activait même hors session → génération de données parasites
- Correction : la détection démarre **uniquement** lorsqu'une session est explicitement démarrée
- Ajout d'un flag `is_active` côté Flutter et backend pour conditionner la détection

**Version stable (29 avril 2026 – "a stable new version") :**
- Détection démarre seulement quand une session est démarrée par l'utilisateur
- Régénération du planning mise à jour : basée sur le contexte de la dernière session terminée
- Suppression du planning temps réel automatique (trop instable) → régénération manuelle à la demande
- Tests complets : création session → démarrage → détection → score → fin → planning mis à jour

**Bilan Phase 3 intermédiaire :**
- ~85% du projet complété
- Fonctionnalités IA avancées livrées : planning adaptatif sommeil↔productivité, examens, SM-2, reschedule
- Restant : tests sur téléphone réel, déploiement, intégration hardware physique

### Difficultés rencontrées

- Race conditions entre les mises à jour temps réel et la génération de planning
- Synchronisation état Flutter ↔ état backend lors du démarrage/arrêt de session

### Objectifs semaine suivante

- Tester l'application sur un téléphone physique Android
- Identifier et corriger les problèmes spécifiques au device réel
- Livrer une version stable validée sur hardware réel

---

---

## Compte Rendu N°14
**Période** : Du 5 mai 2026 au 12 mai 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 3 – Tests sur Téléphone Réel, Stabilisation Hardware (Semaine 10)

---

### Travaux réalisés

Semaine entièrement consacrée aux tests sur téléphone physique Android, une étape critique avant la phase de finition.

**Version stable sur téléphone réel (7 mai 2026 – commits "stable app(real phone)" et "stabe app (real phone tests)") :**
- Déploiement de l'APK sur un téléphone Android physique
- Identification et correction des différences de comportement émulateur vs device réel :
  - Adresse réseau différente (le `baseUrl` de Dio ajusté pour l'IP locale du serveur)
  - Permissions Android (caméra, notifications, stockage) correctement demandées au runtime
  - Gestion des certificats SSL pour les connexions HTTPS
- Tests complets du flux utilisateur sur device réel :
  - Inscription → Connexion → Dashboard → Planning → Génération IA → Session → Chatbot → Flashcards
- Validation que les notifications locales fonctionnent correctement sur device physique
- Vérification de la performance de l'interface (60fps, animations fluides)

**Corrections spécifiques device réel :**
- Ajustement des tailles de texte pour différentes densités d'écran
- Fix du file picker pour la sélection de PDF sur device physique
- Optimisation du chargement initial de l'application

**Tests du module Chatbot sur device :**
- Upload de PDF depuis la galerie du téléphone
- Questions/réponses RAG validées avec latence acceptable
- Historique de conversation persistant entre sessions

### Difficultés rencontrées

- Découverte de bugs spécifiques au device physique absents sur l'émulateur
- Gestion des permissions runtime sur Android 14 (plus stricte)
- Latence réseau réelle supérieure à l'émulateur pour les appels Gemini (~2-3s)

### Objectifs semaine suivante

- Nouvelle version stable avec corrections des bugs device réel
- Tests end-to-end approfondis
- Préparation de l'intégration Raspberry Pi

---

---

## Compte Rendu N°15
**Période** : Du 12 mai 2026 au 19 mai 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 3 – Tests End-to-End, Nouvelle Version Stable (Semaine 11)

---

### Travaux réalisés

Poursuite des tests sur device physique avec livraison d'une nouvelle version stable améliorée.

**Nouvelle version stable téléphone réel (19 mai 2026 – "newest stable real phone") :**
- Corrections de tous les bugs identifiés lors des tests de la semaine précédente
- Amélioration de la stabilité de la connexion réseau entre le téléphone et le serveur
- Optimisation du service Dio : timeout augmenté pour les opérations IA longues (30s), retry automatique sur erreur réseau transitoire
- Gestion d'erreur enrichie côté Flutter : messages d'erreur utilisateur clairs pour chaque type d'erreur backend

**Tests de scénarios complets :**
- Scénario 1 : Nouvel utilisateur → Inscription → Onboarding profil → Premier planning généré → Premier quiz
- Scénario 2 : Upload PDF cours → Q&A RAG → Génération flashcards → Révision SM-2
- Scénario 3 : Enregistrement nuit sommeil → Impact sur planning du lendemain → Adaptation sessions
- Scénario 4 : Session de travail → Détection démarrée → Score focus calculé → Planning mis à jour

**Optimisations performance :**
- Lazy loading des écrans Flutter (chargement différé des providers non actifs)
- Pagination de l'historique du chatbot
- Cache local Hive pour les données de planning fréquemment consultées

**Documentation technique mise à jour :**
- Rapport d'avancement mis à jour (version 2.0 au 9 avril)
- Mise à jour du fichier `requirements.txt` avec les versions validées

### Difficultés rencontrées

- Cas limites dans la génération du planning quand l'utilisateur n'a pas uploadé d'emploi du temps
- Gestion des sessions expirées JWT sur device réel (reconnexion transparente)

### Objectifs semaine suivante

- Déployer le backend sur Raspberry Pi 5
- Configurer le client Pi pour la réception des données hardware
- Tests d'intégration avec le dispositif physique

---

---

## Compte Rendu N°16
**Période** : Du 19 mai 2026 au 26 mai 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 4 – Déploiement Raspberry Pi 5, Build Desktop, Compatibilité ARM (Semaine 12)

---

### Travaux réalisés

Semaine majeure avec le déploiement sur Raspberry Pi 5, qui constitue le serveur embarqué du système Smart Focus.

**Support Raspberry Pi 5 + rapport mis à jour (21 mai 2026 – "add Raspberry Pi 5 deployment support and update report") :**
- Script de déploiement `deploy_pi.sh` : installation automatisée sur Raspberry Pi 5 (Ubuntu Server ARM64)
- Configuration systemd pour démarrage automatique du backend FastAPI au boot
- Adaptation de `requirements.txt` pour l'architecture ARM64 (certaines bibliothèques binaires différentes)
- Documentation du processus de déploiement dans le rapport

**Déploiement client Pi (21 mai 2026 – "pi_client deploy") :**
- Configuration du client Raspberry Pi : script de démarrage, variables d'environnement
- Test de connexion entre le backend déployé sur Pi et l'application Flutter sur téléphone
- Validation que l'API est accessible sur le réseau local (WiFi LAN)
- Configuration du pare-feu Pi pour exposer le port 8000 (API)

**Fix notifications Linux pour build desktop (24 mai 2026 – "fix: add Linux notification settings for desktop build") :**
- Ajout des configurations de notifications pour la build Linux (Raspberry Pi OS Desktop)
- Configuration `flutter_local_notifications` pour Linux dans `linux/` folder
- Tests de notifications sur build desktop Raspberry Pi

**Suppression du pin LangSmith pour compatibilité ARM Pi (24 mai 2026 – "fix: remove langsmith pin for ARM Pi compatibility") :**
- `langsmith` avait une version épinglée incompatible avec ARM Raspberry Pi
- Suppression du pin de version → installation de la version compatible ARM disponible
- Tests de compatibilité des dépendances critiques : LangChain, ChromaDB sur ARM64

**Nouvelles exigences (24 mai 2026 – "new req2") :**
- Mise à jour du fichier `requirements.txt` avec les nouvelles dépendances validées sur ARM64
- Ajout de `raspberry` commits : finalisation de la configuration Pi

### Difficultés rencontrées

- Plusieurs bibliothèques Python (LangChain, Chromadb) n'ont pas de wheels ARM64 précompilés → compilation depuis les sources (lente)
- Différence de performance entre x86 et ARM64 pour les opérations d'embedding
- Configuration réseau pour rendre le Pi accessible depuis le téléphone mobile sur le même réseau WiFi

### Objectifs semaine suivante

- Finaliser la documentation technique
- Préparer le script de démonstration finale
- Corrections et polish final de l'interface

---

---

## Compte Rendu N°17
**Période** : Du 26 mai 2026 au 30 mai 2026  
**Responsable** : Kacem Jemni  
**Thème** : Phase 4 – Finalisation, Documentation & Préparation Démo (Semaine 13-14)

---

### Travaux réalisés

Dernière période du projet. Bilan final, corrections de dernière minute et préparation de la présentation.

**Bilan des fonctionnalités livrées :**

| Module | Statut | Détail |
|--------|--------|--------|
| Infrastructure & Architecture | ✅ 100% | FastAPI + Flutter + PostgreSQL + ChromaDB |
| Authentification JWT | ✅ 100% | Register, Login, Refresh, Profil, Google Sign-In |
| Chatbot RAG | ✅ 100% | PDF/CSV upload, Q&A, historique, multi-documents |
| Quiz & Flashcards SM-2 | ✅ 100% | Génération, soumission, SM-2, multi-docs |
| Planning IA Adaptatif | ✅ 100% | Gemini 2.5 Flash, 1701 lignes, planning complet |
| Sleep Tracking | ✅ 100% | Log, stats, alarme intelligente, impact planning |
| Dashboard & Statistiques | ✅ 100% | fl_chart, graphiques, insights |
| Données Temps Réel | ✅ 100% | Score focus live, sessions conditionnelles |
| Déploiement Raspberry Pi 5 | ✅ 100% | ARM64, systemd, réseau local |
| Tests Téléphone Réel | ✅ 100% | Validé sur device Android physique |
| Tests Unitaires Backend | ⚠️ Partiel | Pas encore automatisés |

**Documentation finale :**
- Rapport d'avancement complet (version 2.0) documentant toutes les fonctionnalités
- Diagrammes UML mis à jour : cas d'utilisation, classes, séquences, ERD
- Cahier des charges annoté avec le statut réel de chaque fonctionnalité
- Documentation API Swagger accessible via `/docs`

**Préparation de la démo :**
- Scénario de démonstration défini : présentation en 5 étapes (Auth → Planning IA → Chatbot RAG → Quiz → Sleep Tracking)
- Build APK de release générée et testée
- Backup complet du projet

**Stack technique finale livrée :**
- **Backend** : FastAPI 0.115.0, Python 3.11, PostgreSQL, Alembic, LangChain 0.3.0, ChromaDB 0.5.0, Gemini 2.5 Flash
- **Mobile** : Flutter 3.x, Riverpod ^3.2.1, GoRouter ^17.1.0, Dio ^5.9.1, fl_chart ^1.1.1
- **Déploiement** : Raspberry Pi 5 (ARM64 Ubuntu), systemd, réseau local WiFi

### Bilan général du projet

- **Durée totale** : 17 semaines (3 février → 30 mai 2026)
- **Lignes de code backend** : ~8 000+ lignes Python
- **Lignes de code Flutter** : ~15 000+ lignes Dart
- **Endpoints API actifs** : 28 endpoints REST
- **Progression globale** : ~88% des fonctionnalités initialement prévues livrées

### Points restants identifiés

1. Connexion physique Raspberry ↔ Backend (dépend de Personne 1 hardware)
2. Tests unitaires automatisés (pytest backend, widget tests Flutter)
3. Déploiement Docker pour portabilité maximale
4. Écran Onboarding (premier lancement)

---

*Fin des comptes rendus – Projet Smart Focus & Life Assistant*  
*Kacem Jemni – Période : 03/02/2026 → 30/05/2026*
