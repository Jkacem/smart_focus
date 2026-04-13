# 📊 Rapport d'Avancement – Smart Focus & Life Assistant

**Date du rapport** : 9 Avril 2026  
**Projet** : Smart Focus & Life Assistant  
**Responsable** : Personne 2 – Application Mobile, Backend & IA  
**Version** : 2.0

---

## 🧭 Vue d'Ensemble

Smart Focus & Life Assistant est un assistant intelligent tout-en-un combinant :
- Un **boîtier hardware ESP32** (capteurs, caméra, LEDs, écran TFT) — *Personne 1*
- Un **backend FastAPI + PostgreSQL** avec intelligence artificielle — *Personne 2*
- Une **application mobile Flutter** connectée en temps réel — *Personne 2*

Ce rapport couvre l'avancement du périmètre **Personne 2** (logiciel).

---

## ✅ Ce qui est FAIT

### 🏗️ Infrastructure & Architecture

| Composant | Statut | Détail |
|-----------|--------|--------|
| Structure projet Flutter (Feature-First Clean Arch) | ✅ Fait | `lib/features/`, `lib/core/`, `lib/shared/` |
| Setup Backend FastAPI | ✅ Fait | `main.py`, CORS, Swagger UI (`/docs`), ReDoc (`/redoc`) |
| Configuration base de données PostgreSQL + Alembic | ✅ Fait | Migrations gérées, `ensure_schema_compatibility()` au démarrage |
| Base de données vectorielle ChromaDB | ✅ Fait | Dossier `chroma_db/` initialisé automatiquement |
| Navigation GoRouter | ✅ Fait | Routing centralisé dans `lib/core/router/` |
| Design system Flutter (thème, couleurs, polices) | ✅ Fait | `lib/core/theme/` + Google Fonts |
| Système de State Management Riverpod | ✅ Fait | Providers dans chaque feature |
| Endpoints de santé | ✅ Fait | `GET /` et `GET /health` opérationnels |

---

### 🔐 Authentification

| Fonctionnalité | Statut | Fichiers |
|----------------|--------|---------|
| Écran Welcome | ✅ Fait | `features/auth/` |
| Formulaire de Connexion | ✅ Fait | `login_screen.dart`, `login_form.dart` |
| Formulaire d'Inscription | ✅ Fait | `sign_form.dart` |
| API Auth (Register/Login) | ✅ Fait | `routers/auth.py` |
| JWT Token Management | ✅ Fait | `deps.py` — access + refresh tokens |
| Profil utilisateur (`GET/PUT /auth/me`) | ✅ Fait | Préférences, objectif focus, schedule |
| Fix login sur émulateur | ✅ Fait | Problème réseau émulateur corrigé (Avril 2026) |

---

### 🤖 Chatbot RAG (Révisions Intelligentes)

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Service RAG avec LangChain + ChromaDB | ✅ Fait | `services/rag_service.py` (~19 Ko) |
| Upload PDF **et CSV** | ✅ Fait | `POST /chatbot/upload` — PDF ou CSV acceptés |
| Validation CSV emploi du temps | ✅ Fait | Colonnes requises : `week, day, start, end, subject` |
| Embeddings avec Gemini (`text-embedding-004`) | ✅ Fait | Migration depuis OpenAI |
| Questions/Réponses sur les cours (RAG) | ✅ Fait | `POST /chatbot/chat` avec `document_ids[]` |
| Support requêtes générales (sans doc) | ✅ Fait | Fallback IA directe si `document_ids` vide |
| Historique de chat par utilisateur | ✅ Fait | `GET /chatbot/history?limit=N`, isolé par `user_id` |
| Liste & suppression de documents | ✅ Fait | `GET /chatbot/documents`, `DELETE /chatbot/documents/{id}` |
| Suppression cascade (DB + disque + ChromaDB) | ✅ Fait | Nettoyage complet lors de la suppression |
| Interface Flutter Chatbot | ✅ Fait | `features/chatbot/` |

---

### 🧠 Quiz & Flashcards

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Génération de Quiz depuis PDF | ✅ Fait | `routers/quiz.py` (~10 Ko) |
| Soumission et score de quiz | ✅ Fait | Score calculé, corrections avec explications IA |
| Algorithme SM-2 pour Flashcards | ✅ Fait | `services/sm2_service.py` — intervalle, ease factor, répétitions |
| API Flashcards (CRUD + révision SM-2) | ✅ Fait | `routers/flashcard.py` (~11 Ko) |
| Multi-documents pour Quiz | ✅ Fait | `QuizDocumentLink` — quiz lié à plusieurs documents |
| Interface Flutter Quiz | ✅ Fait | `features/quiz/` (models, providers, screens, services) |
| Interface Flutter Flashcards | ✅ Fait | `features/flashcards/` (models, providers, screens, services) |
| UI Glassmorphism cohérente | ✅ Fait | Alignement avec design system (Mars 2026) |

---

### 📅 Planning Intelligent (Module le plus avancé)

Le module planning est le plus complet et sophistiqué du projet, avec **1701 lignes** de code dans le routeur seul.

#### Génération de planning

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| **Génération quotidienne IA** (`POST /generate`) | ✅ Fait | Gemini 2.5 Flash — sessions adaptées au profil |
| **Génération hebdomadaire** (`POST /generate/week`) | ✅ Fait | 7 jours générés en une seule requête |
| Parsing d'emploi du temps CSV déterministe | ✅ Fait | `services/schedule_parser.py` — Semaine A/B |
| Extraction timetable depuis PDF (RAG) | ✅ Fait | ChromaDB + Gemini — fallback si pas de CSV |
| Blocs fixes respectés (non-chevauchement) | ✅ Fait | Buffer de 15 min entre sessions |
| Gestion des erreurs de parsing LLM | ✅ Fait | Regex JSON + validation stricte |

#### Planification adaptative intelligente

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| **Profil sommeil → paramètres sessions** | ✅ Fait | Score ≥80 → 50min/session ; Score <50 → 25min/2 sessions |
| Créneaux libres calculés automatiquement | ✅ Fait | `_compute_free_slots()` — entre 8h et 22h |
| Heures préférées (matin/après-midi/soir) | ✅ Fait | Depuis profil utilisateur ou historique completion |
| Rotation par poids (Weighted Round-Robin) | ✅ Fait | `_build_weighted_rotation()` — équilibre les matières |
| Révisions de cours (Revision: [matière]) | ✅ Fait | Poids basé sur recency + fréquence de cours |
| Révisions d'examens (`Revision examen: X`) | ✅ Fait | Intensité selon `days_until_exam` (≤2j, ≤6j, ≤14j, >14j) |
| Révisions flashcards SM-2 dues | ✅ Fait | Sessions flashcards insérées si cartes dues ce jour |
| Révisions quiz ciblées (sujets faibles) | ✅ Fait | `weakness_score` → priorité high si ≥0.6 |
| **Reprise sessions manquées** (`POST /reschedule/{id}`) | ✅ Fait | Cherche créneau libre sur J et J+1 |
| Corrélation sommeil ↔ productivité | ✅ Fait | `_compute_sleep_study_correlation()` |
| Signaux de sessions reportées/annulées | ✅ Fait | `_collect_postponed_course_signals()` — boost de poids |
| Week-end : sweep hebdomadaire des cours | ✅ Fait | Toutes les matières de la semaine revisitées |
| Insights & statistiques planning | ✅ Fait | `GET /insights?period=week|month` |

#### CRUD sessions & examens

| Fonctionnalité | Statut | Endpoint |
|----------------|--------|----------|
| Lire planning du jour | ✅ Fait | `GET /today` |
| Lire planning par date | ✅ Fait | `GET /{date}` |
| Créer session manuelle | ✅ Fait | `POST /sessions` |
| Modifier session | ✅ Fait | `PATCH /sessions/{id}` |
| Marquer session terminée | ✅ Fait | `PATCH /sessions/{id}/complete` |
| Supprimer session | ✅ Fait | `DELETE /sessions/{id}` |
| Créer un examen | ✅ Fait | `POST /exams` |
| Lister examens | ✅ Fait | `GET /exams` |
| Supprimer un examen | ✅ Fait | `DELETE /exams/{exam_id}` |

---

### 😴 Sleep Tracking

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| API Enregistrement sommeil | ✅ Fait | `POST /api/v1/sleep/log` — calcul du `sleep_score` |
| Statistiques sommeil (semaine/mois) | ✅ Fait | `GET /api/v1/sleep/stats?period=week|month` |
| Historique des nuits | ✅ Fait | `GET /api/v1/sleep/history?limit=N` |
| Configuration alarme intelligente | ✅ Fait | `PUT /api/v1/sleep/alarm` — mode gradual/normal/silent |
| Lecture config alarme | ✅ Fait | `GET /api/v1/sleep/alarm` |
| Alarme locale (package `alarm`) | ✅ Fait | `alarm: ^5.2.1` intégré dans Flutter |
| Notifications locales | ✅ Fait | `flutter_local_notifications` |
| Correction bug navigation bottom bar | ✅ Fait | Highlighting corrigé |
| Intégration score sommeil → planning | ✅ Fait | Le planning adapte nb/durée sessions selon score |

---

### 📈 Dashboard & Statistiques

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Écran Dashboard | ✅ Fait | `features/dashboard/` |
| Graphiques avec fl_chart | ✅ Fait | Courbes progression, scores |
| Écran Statistiques | ✅ Fait | `features/stats/` |
| Écran Paramètres | ✅ Fait | `features/settings/` |

---

## 🔄 En Cours / Partiellement Fait

| Fonctionnalité | Statut | État actuel |
|----------------|--------|-------------|
| Intégration WebSocket temps réel | ⚠️ Partiel | `socket_io_client: ^3.1.4` installé côté Flutter, endpoints backend non finalisés |
| Connexion réelle hardware ESP32 | ⚠️ Partiel | Architecture prête, connexion physique bloquée côté Personne 1 |
| Tests unitaires backend | ⚠️ Partiel | Pas encore de tests automatisés |

---

## ❌ Pas encore fait

| Fonctionnalité | Priorité | Phase |
|----------------|----------|-------|
| Écran Onboarding (intro + profil utilisateur) | Moyenne | Phase 4 |
| Blocage / limites réseaux sociaux | Basse | Phase 4 |
| Tests unitaires endpoints critiques | Haute | En continu |
| Déploiement Docker | Moyenne | Phase 4 |
| Vidéo démo + Poster | Haute | Phase 4 |

---

## 📦 Stack Technique Réelle (à ce jour)

### Backend

| Technologie | Version | Usage |
|-------------|---------|-------|
| Python | 3.11 | Langage principal |
| FastAPI | 0.115.0 | Framework API REST |
| Uvicorn | 0.32.0 | Serveur ASGI |
| PostgreSQL | — | Base de données relationnelle |
| SQLAlchemy | 2.0.36 | ORM |
| Alembic | 1.14.0 | Migrations DB |
| **Google Gemini 2.5 Flash** | — | LLM planning + extraction timetable |
| **Gemini Embeddings** (`text-embedding-004`) | — | Vectorisation documents |
| LangChain | 0.3.0 | Chaînes RAG |
| ChromaDB | 0.5.0 | Base vectorielle locale |
| PyMuPDF | 1.24.0 | Extraction texte PDF |
| python-jose | 3.3.0 | JWT Auth |
| passlib[bcrypt] | 1.7.4 | Hashing mots de passe |
| pydantic-settings | 2.6.0 | Configuration .env |

### Mobile Flutter

| Package | Version | Usage |
|---------|---------|-------|
| `flutter_riverpod` | ^3.2.1 | State management |
| `dio` | ^5.9.1 | Client HTTP |
| `go_router` | ^17.1.0 | Navigation centralisée |
| `fl_chart` | ^1.1.1 | Graphiques et visualisations |
| `hive` + `hive_flutter` | ^2.2.3 | Stockage local (cache) |
| `google_fonts` | ^8.0.2 | Typographie (Inter, etc.) |
| `socket_io_client` | ^3.1.4 | WebSocket temps réel |
| `flutter_local_notifications` | ^20.1.0 | Notifications push locales |
| `alarm` | ^5.2.1 | Alarme sommeil intelligente |
| `file_picker` | ^10.3.10 | Sélection fichiers PDF/CSV |
| `intl` | ^0.20.2 | Formatage dates/heures |

---

## 🗃️ Schéma de Base de Données (Tables actives)

| Table | Description |
|-------|-------------|
| `users` | Comptes utilisateurs (email, password hash, rôle) |
| `user_profiles` | Préférences (objectif focus, horaires, notifs) |
| `chat_documents` | Documents uploadés (PDF/CSV) + référence ChromaDB |
| `chat_messages` | Historique Q&A chatbot par utilisateur |
| `quizzes` | Quiz générés (lié à document, score, statut) |
| `quiz_questions` | Questions QCM avec options + réponse correcte |
| `quiz_documents` | Lien M2M quiz ↔ documents sources |
| `flashcards` | Cartes avec champs SM-2 (ease_factor, interval, next_review) |
| `sleep_records` | Enregistrements nuits (heures, score 0-100, raw data) |
| `smart_alarms` | Config alarme par utilisateur (heure, mode, intensité) |
| `study_sessions` | Sessions de travail planifiées (AI ou manuelles) |
| `study_session_documents` | Lien M2M session ↔ documents |
| `exams` | Examens définis par l'utilisateur (date, titre, document) |

---

## 🌐 Endpoints API Actifs (Résumé)

### `/api/v1/auth`
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/register` | Créer un compte |
| `POST` | `/login` | Connexion, retourne JWT |
| `GET` | `/me` | Profil courant |
| `PUT` | `/me/profile` | MAJ préférences utilisateur |

### `/chatbot`
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/upload` | Upload PDF ou CSV emploi du temps |
| `GET` | `/documents` | Lister mes documents |
| `DELETE` | `/documents/{id}` | Supprimer document (DB + disque + Chroma) |
| `POST` | `/chat` | Poser une question (RAG ou général) |
| `GET` | `/history` | Historique des échanges |

### `/api/v1/quiz`
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/generate` | Générer un quiz depuis un document |
| `POST` | `/{id}/submit` | Soumettre les réponses |
| `GET` | `/` | Lister mes quiz |

### `/api/v1/flashcards` (via `routers/flashcard.py`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/generate` | Générer des flashcards |
| `GET` | `/due` | Cartes dues aujourd'hui (SM-2) |
| `POST` | `/{id}/review` | Soumettre révision (ease 0–5) |

### `/api/v1/sleep`
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/log` | Enregistrer une nuit |
| `GET` | `/stats` | Statistiques (week/month) |
| `GET` | `/history` | Historique des nuits |
| `PUT` | `/alarm` | Configurer l'alarme |
| `GET` | `/alarm` | Lire la config alarme |

### `/api/v1/planning`
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/today` | Planning du jour |
| `GET` | `/{date}` | Planning d'une date |
| `POST` | `/generate` | Générer planning IA (1 jour) |
| `POST` | `/generate/week` | Générer planning IA (7 jours) |
| `GET` | `/insights` | Stats & recommandations |
| `POST` | `/sessions` | Créer session manuelle |
| `PATCH` | `/sessions/{id}` | Modifier une session |
| `PATCH` | `/sessions/{id}/complete` | Marquer terminée |
| `DELETE` | `/sessions/{id}` | Supprimer une session |
| `POST` | `/reschedule/{id}` | Replanifier session manquée |
| `GET` | `/exams` | Lister les examens |
| `POST` | `/exams` | Créer un examen |
| `DELETE` | `/exams/{id}` | Supprimer un examen |

---

## 📅 Planning Projet – Avancement par Phase

```
Phase 1 – Fondations (S1-S3)        [████████████████████] 100% ✅
Phase 2 – Features Core (S4-S7)     [████████████████████]  100% ✅
Phase 3 – IA Avancée (S8-S11)       [████████████████████]  100% ✅
Phase 4 – Finition (S12-S14)        [████████░░░░░░░░░░░░]  40% 🔄
```

### Progression globale estimée : **~85%**

---

## 🗓️ Historique des Travaux Réalisés

| Date | Sujet | Résultat |
|------|-------|----------|
| 12 Mars 2026 | Setup navigation, Planning screen UI | Navigation de base opérationnelle |
| 13 Mars 2026 | Migration vers GoRouter | Routing centralisé complet |
| 18-21 Mars 2026 | RAG Chatbot setup, fix Gemini embedding | RAG fonctionnel avec Gemini |
| 22 Mars 2026 | Chatbot général (sans document) | Fallback IA direct implémenté |
| 23 Mars 2026 | Quiz & Flashcards UI | UI glassmorphism cohérente |
| 24 Mars 2026 | Fix historique chat par utilisateur | Isolation user_id corrigée |
| 25-27 Mars 2026 | Sleep Tracking + alarme locale | Feature sommeil complète |
| 27-30 Mars 2026 | Planning IA intelligent | Service Gemini + blocs fixes |
| 30 Mars 2026 | Fix parsing emploi du temps | Template CSV + parser déterministe |
| 31 Mars 2026 | Fix réponse FastAPI `/generate` | Endpoint planning fonctionnel |
| 4 Avril 2026 | Fix login émulateur Android | Problème réseau résolu |
| Avril 2026 | Planning adaptatif avancé | Sommeil ↔ planning, examens, flashcards dues, reschedule, semaine entière |

---

## 🎯 Prochaines Étapes Prioritaires

1. **[  ] WebSocket temps réel** — finaliser la diffusion du score focus
2. **[  ] Écran Onboarding** — profil utilisateur au premier lancement
3. **[  ] Tests unitaires** — auth, chatbot, planning (cas critiques)
4. **[  ] Déploiement Docker** — conteneurisation backend + PostgreSQL
5. **[  ] Intégration hardware réel** — quand disponible côté Personne 1
6. **[  ] Préparation démo** — vidéo + poster de présentation finale

---

## ⚠️ Points d'Attention

> **LLM externe** : Le planning intelligent et la RAG dépendent de l'API Google Gemini (modèle `gemini-2.5-flash`).
> Un quota élevé peut générer des coûts. Prévoir un cache ou un mode dégradé pour la démo.

> **Intégration Hardware** : La connexion ESP32 est bloquée en attente du travail de Personne 1.
> Les mocks permettent de continuer les tests en parallèle.

> **Tests manquants** : Les endpoints backend n'ont pas de tests automatisés.
> Ce point est critique avant la démo finale — prioriser auth, `/generate` et `/chatbot/chat`.

> **WebSocket** : `socket_io_client` est installé côté Flutter mais le backend n'expose pas encore les événements temps réel. Nécessaire pour diffuser le score focus depuis l'ESP32.

---

*Rapport mis à jour le 9 Avril 2026*  
*Projet Smart Focus & Life Assistant – Personne 2*
