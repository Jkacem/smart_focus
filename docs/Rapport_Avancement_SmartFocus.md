# 📊 Rapport d'Avancement – Smart Focus & Life Assistant

**Date du rapport** : 31 Mars 2026  
**Projet** : Smart Focus & Life Assistant  
**Responsable** : Personne 2 – Application Mobile, Backend & IA  
**Version** : 1.0

---

## 🧭 Vue d'Ensemble

Smart Focus & Life Assistant est un assistant intelligent tout-en-un combinant :
- Un **boîtier hardware ESP32** (capteurs, caméra, LEDs, écran TFT)
- Un **backend FastAPI + PostgreSQL** avec intelligence artificielle
- Une **application mobile Flutter** connectée en temps réel

Ce rapport couvre l'avancement du périmètre **Personne 2** (logiciel).

---

## ✅ Ce qui est FAIT

### 🏗️ Infrastructure & Architecture

| Composant | Statut | Détail |
|-----------|--------|--------|
| Structure projet Flutter (Feature-First Clean Arch) | ✅ Fait | `lib/features/`, `lib/core/`, `lib/shared/` |
| Setup Backend FastAPI | ✅ Fait | `main.py`, CORS, Swagger UI (`/docs`) |
| Configuration base de données PostgreSQL + Alembic | ✅ Fait | Migrations gérées |
| Base de données vectorielle ChromaDB | ✅ Fait | Dossier `chroma_db/` en place |
| Navigation GoRouter | ✅ Fait | Routing centralisé dans `lib/core/router/` |
| Design system Flutter (thème, couleurs, polices) | ✅ Fait | `lib/core/theme/` + Google Fonts |
| Système de State Management Riverpod | ✅ Fait | Providers dans chaque feature |

---

### 🔐 Authentification

| Fonctionnalité | Statut | Fichiers |
|----------------|--------|---------|
| Écran Welcome | ✅ Fait | `welcome_screen.dart` |
| Formulaire de Connexion | ✅ Fait | `login_screen.dart`, `login_form.dart` |
| Formulaire d'Inscription | ✅ Fait | `sign_form.dart` |
| API Auth (Register/Login) | ✅ Fait | `routers/auth.py` |
| JWT Token Management | ✅ Fait | `deps.py` |
| Navigation Login → Register | ✅ Fait | Corrigé avec GoRouter |

---

### 🤖 Chatbot RAG (Révisions Intelligentes)

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Service RAG avec LangChain + ChromaDB | ✅ Fait | `services/rag_service.py` (~15 Ko) |
| Upload & parsing de documents PDF | ✅ Fait | `routers/chatbot.py` |
| Embeddings avec Gemini (google-generativeai) | ✅ Fait | Migration depuis OpenAI |
| Questions/Réponses sur les cours | ✅ Fait | Endpoint `/chatbot/ask` |
| Support requêtes générales (sans doc) | ✅ Fait | Fallback IA directe |
| Historique de chat par utilisateur | ✅ Fait | Isolation par `user_id` |
| Interface Flutter Chatbot | ✅ Fait | `chatbot_screen.dart` |
| Liste & sélection de documents | ✅ Fait | UI avec sélection optionnelle |

---

### 🧠 Quiz & Flashcards

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Génération de Quiz depuis PDF | ✅ Fait | `routers/quiz.py` (~9 Ko) |
| Algorithme SM-2 pour Flashcards | ✅ Fait | `services/sm2_service.py` |
| API Flashcards (CRUD + révision) | ✅ Fait | `routers/flashcard.py` (~9 Ko) |
| Interface Flutter Quiz | ✅ Fait | `features/quiz/` (models, providers, screens, services) |
| Interface Flutter Flashcards | ✅ Fait | `features/flashcards/` (models, providers, screens, services) |
| UI Glassmorphism cohérente | ✅ Fait | Alignement avec design system |

---

### 📅 Planning Intelligent

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Service de planification IA (Gemini) | ✅ Fait | `services/planning_service.py` (~14 Ko) |
| Génération de planning par IA | ✅ Fait | Endpoint `/planning/generate` |
| Blocs fixes (rendez-vous, cours) | ✅ Fait | Respectés lors de la génération |
| Parsing d'emploi du temps CSV | ✅ Fait | `services/schedule_parser.py` |
| Fallback PDF via RAG | ✅ Fait | Pour les emplois du temps non-structurés |
| Template CSV Semaine A/B | ✅ Fait | `docs/schedule_template.csv` |
| Interface Flutter Planning | ✅ Fait | `planning_screen.dart` |

---

### 😴 Sleep Tracking

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| API Enregistrement sommeil | ✅ Fait | `routers/sleep.py` (~4 Ko) |
| Statistiques sommeil | ✅ Fait | Endpoint `/sleep/stats` |
| Interface Flutter Sleep | ✅ Fait | `features/sleep/` (models, providers, screens, services) |
| Alarme locale intelligente | ✅ Fait | Package `alarm: ^5.2.1` intégré |
| Notifications locales | ✅ Fait | Package `flutter_local_notifications` |
| Correction bug navigation bottom bar | ✅ Fait | Highlighting corrigé |

---

### 📈 Dashboard & Statistiques

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Écran Dashboard | ✅ Fait | `features/dashboard/` |
| Graphiques avec fl_chart | ✅ Fait | Intégré dans stats |
| Écran Statistiques | ✅ Fait | `features/stats/` |
| Écran Paramètres | ✅ Fait | `features/settings/` |

---

## 🔄 En Cours / Partiellement Fait

| Fonctionnalité | Statut | Problème identifié |
|----------------|--------|--------------------|
| Génération planning depuis emploi du temps PDF | ⚠️ Partiel | Erreurs de parsing LLM sur les PDF non-structurés → remplacé par CSV |
| Intégration WebSocket temps réel | ⚠️ Partiel | `socket_io_client` installé, non finalisé |
| Connexion réelle hardware ESP32 | ⚠️ Partiel | Module installé côté frontend, connexion physique en attente hardw. |

---

## ❌ Pas encore fait

| Fonctionnalité | Priorité | Phase |
|----------------|----------|-------|
| Écran Onboarding (intro + profil) | Moyenne | Phase 4 |
| Conseils personnalisés (analyse patterns) | Moyenne | Phase 3 |
| Blocage / limites réseaux sociaux | Basse | Phase 4 |
| Tests unitaires backend | Haute | En continu |
| Déploiement Docker | Moyenne | Phase 4 |
| Documentation API complète (Swagger enrichi) | Moyenne | Phase 4 |
| Vidéo démo + Poster | Haute | Phase 4 |

---

## 📦 Stack Technique Réelle (à ce jour)

### Backend
| Technologie | Usage |
|-------------|-------|
| Python 3.11 + FastAPI | Framework API |
| PostgreSQL + Alembic | Base de données + migrations |
| LangChain + ChromaDB | RAG & recherche vectorielle |
| **Google Gemini** (gemini-1.5-flash) | LLM principal (remplace GPT) |
| **Gemini Embeddings** (text-embedding-004) | Vectorisation documents |
| PyPDF | Extraction texte PDF |

### Mobile Flutter
| Package | Version | Usage |
|---------|---------|-------|
| `flutter_riverpod` | ^3.2.1 | State management |
| `dio` | ^5.9.1 | HTTP client |
| `go_router` | ^17.1.0 | Navigation centralisée |
| `fl_chart` | ^1.1.1 | Graphiques |
| `hive` + `hive_flutter` | ^2.2.3 | Stockage local |
| `google_fonts` | ^8.0.2 | Typographie |
| `socket_io_client` | ^3.1.4 | WebSocket |
| `flutter_local_notifications` | ^20.1.0 | Notifications |
| `alarm` | ^5.2.1 | Alarme sommeil |
| `file_picker` | ^10.3.10 | Sélection fichiers |

---

## 📅 Planning Projet – Avancement par Phase

```
Phase 1 – Fondations (S1-S3)        [████████████████████] 100% ✅
Phase 2 – Features Core (S4-S7)     [████████████████░░░░]  80% 🔄
Phase 3 – IA Avancée (S8-S11)       [████████████░░░░░░░░]  60% 🔄
Phase 4 – Finition (S12-S14)        [████░░░░░░░░░░░░░░░░]  20% ⏳
```

### Progression globale estimée : **~65%**

---

## 🗓️ Historique des Conversations (Travail réalisé)

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

---

## 🎯 Prochaines Étapes Prioritaires

1. **[ ] Finaliser le WebSocket** temps réel pour le score focus
2. **[ ] Créer l'écran Onboarding** (profil utilisateur)
3. **[ ] Tests unitaires** pour les endpoints critiques (auth, chatbot, planning)
4. **[ ] Préparer le déploiement Docker** du backend
5. **[ ] Intégration hardware réel** (quand disponible côté Personne 1)
6. **[ ] Préparation démo** : vidéo + poster

---

## ⚠️ Points d'Attention

> **Dépendance externe** : Le planning intelligent dépend de l'API Google Gemini.
> Un quota élevé de requêtes peut générer des coûts. Prévoir un cache ou un mode dégradé.

> **Intégration Hardware** : La partie connexion ESP32 est bloquée en attente du travail de Personne 1.
> Les mocks permettent de continuer les tests en parallèle.

> **Tests manquants** : Les endpoints backend n'ont pas encore de tests automatisés.
> Ce point est critique avant la démo finale.

---

*Rapport généré automatiquement le 31 Mars 2026*  
*Projet Smart Focus & Life Assistant – Personne 2*
