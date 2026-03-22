# 📅 PV Planning Formation Intensif – 1 Mois

**Projet** : Smart Focus & Life Assistant  
**Responsable** : Personne 2  
**Date de début** : 02 Février 2026  
**Durée** : 4 semaines (28 jours)  
**Objectif** : Maîtriser Flutter, Backend et IA/RAG pour livrer l'application

---

## 🎯 Résumé Exécutif

| Métrique | Valeur |
|----------|--------|
| **Durée totale** | 4 semaines |
| **Heures formation** | 30h |
| **Heures projet** | 40h |
| **Total** | 70h (~2.5h/jour) |
| **Livrable final** | App Flutter + Backend + Chatbot RAG |

---

## 📚 Formations Sélectionnées

| # | Formation | Durée | Lien |
|---|-----------|-------|------|
| 1 | Flutter & Dart - The Complete Guide | 15h | [Udemy](https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/) |
| 2 | FastAPI Tutorial | 6h | [fastapi.tiangolo.com](https://fastapi.tiangolo.com/tutorial/) |
| 3 | ChatGPT Prompt Engineering for Developers | 1.5h | [DeepLearning.AI](https://learn.deeplearning.ai/courses/chatgpt-prompt-eng) |
| 4 | LangChain for LLM Application Development | 3h | [DeepLearning.AI](https://learn.deeplearning.ai/courses/langchain) |
| 5 | Retrieval Augmented Generation | 3h | [DeepLearning.AI](https://learn.deeplearning.ai/courses/retrieval-augmented-generation) |
| 6 | LangChain: Chat with Your Data | 4h | [DeepLearning.AI](https://learn.deeplearning.ai/courses/langchain-chat-with-your-data) |

---

## 📆 SEMAINE 1 : Flutter Express

**Objectif** : Créer une app Flutter qui communique avec une API

### Sections du Cours Udemy (Maximilian Schwarzmüller)

| Section | Titre Exact | Durée | Jour |
|---------|-------------|-------|------|
| 1 | Introduction | 30min | Lun |
| 2 | Flutter & Dart Basics I - Getting a Solid Foundation | 2h | Lun |
| 3 | Flutter & Dart Basics II - Fundamentals Deep Dive | 2h | Mar |
| 4 | Debugging Flutter Apps | 30min | Mar |
| 5 | Adding Interactivity & Theming | 1.5h | Mer |
| 6 | Building Responsive & Adaptive User Interfaces | 1.5h | Mer |
| 7 | Flutter & Dart Internals | 1h | Jeu |
| 8 | Building Multi-Screen Apps & Navigating Between Screens | 2h | Jeu |
| 10 | Connecting a Backend & Sending HTTP Requests | 2h | Ven |
| 13 | Using Riverpod for State Management | 2h | Sam |

### Planning Journalier

| Jour | Date | Sections | Contenu | Durée |
|------|------|----------|---------|-------|
| **Lun** | 03/02 | 1-2 | Introduction + Dart & Flutter Basics I | 2.5h |
| **Mar** | 04/02 | 3-4 | Flutter Basics II + Debugging | 2.5h |
| **Mer** | 05/02 | 5-6 | Interactivity + Responsive UI | 3h |
| **Jeu** | 06/02 | 7-8 | Internals + Multi-Screen & Navigation | 3h |
| **Ven** | 07/02 | 10 | HTTP Requests & Backend Connection | 2h |
| **Sam** | 08/02 | 13 | State Management avec Riverpod | 2h |
| **Dim** | 09/02 | — | 🔄 Révision + Mini-projet test | 2h |

### Sections à IGNORER (Gain de temps)

| Section | Titre | Raison |
|---------|-------|--------|
| 9 | Managing App-Wide State | Riverpod utilisé à la place |
| 11 | Using Native Device Features | Pas nécessaire pour MVP |
| 12 | Push Notifications & Chat | Trop avancé |
| 14+ | Animations, Testing, Deployment | Phase finale |

### Checklist Semaine 1

- [ ] Section 1 : Introduction
- [ ] Section 2 : Flutter & Dart Basics I
- [ ] Section 3 : Flutter & Dart Basics II
- [ ] Section 4 : Debugging Flutter Apps
- [ ] Section 5 : Adding Interactivity & Theming
- [ ] Section 6 : Responsive & Adaptive UI
- [ ] Section 7 : Flutter & Dart Internals
- [ ] Section 8 : Multi-Screen Apps & Navigation
- [ ] Section 10 : HTTP Requests & Backend
- [ ] Section 13 : Riverpod State Management
- [ ] ✅ Mini-app : Liste qui fetch une API

---

## 📆 SEMAINE 2 : Backend + IA

**Objectif** : API fonctionnelle + Chatbot RAG qui répond aux questions

### Planning Journalier

| Jour | Date | Formation | Contenu | Durée |
|------|------|-----------|---------|-------|
| **Lun** | 10/02 | FastAPI Tutorial | First Steps, Path Parameters, Query Parameters | 3h |
| **Mar** | 11/02 | FastAPI Tutorial | Request Body, Response Model, SQL Databases | 3h |
| **Mer** | 12/02 | ChatGPT Prompt Engineering | Cours complet (7 lessons) | 1.5h |
| **Mer** | 12/02 | LangChain for LLM Apps | Lessons 1-3 (Models, Memory, Chains) | 1.5h |
| **Jeu** | 13/02 | LangChain for LLM Apps | Lessons 4-6 (Q&A, Evaluation, Agents) | 1.5h |
| **Jeu** | 13/02 | RAG Course | Module 1-2 (Introduction, Architecture) | 1.5h |
| **Ven** | 14/02 | RAG Course | Module 3-4 (Retrieval, Evaluation) | 1.5h |
| **Ven** | 14/02 | LangChain Chat with Data | Lessons 1-3 (Loading, Splitting, Embeddings) | 1.5h |
| **Sam** | 15/02 | LangChain Chat with Data | Lessons 4-6 (Retrieval, Q&A, Chat) | 2.5h |
| **Dim** | 16/02 | Pratique | Test RAG local + Intégration API | 3h |

### FastAPI Sections Essentielles

| Chapitre | Contenu | Obligatoire |
|----------|---------|-------------|
| First Steps | Hello World API | ✅ |
| Path Parameters | Routes dynamiques /users/{id} | ✅ |
| Query Parameters | Filtres ?limit=10 | ✅ |
| Request Body | Recevoir du JSON | ✅ |
| Response Model | Valider les réponses | ✅ |
| SQL Databases | PostgreSQL + SQLAlchemy | ✅ |
| Background Tasks | Tâches async | 🟡 |
| WebSockets | Temps réel | ✅ |

### Checklist Semaine 2

- [ ] FastAPI : First Steps + Path/Query Params
- [ ] FastAPI : Request Body + Response Models
- [ ] FastAPI : SQL Databases (PostgreSQL)
- [ ] ChatGPT Prompt Engineering (complet)
- [ ] LangChain for LLM Apps (6 lessons)
- [ ] RAG Course (4 modules)
- [ ] LangChain Chat with Data (6 lessons)
- [ ] ✅ Test : Chatbot répond sur un PDF

---

## 📆 SEMAINE 3 : Développement MVP

**Objectif** : App Smart Focus fonctionnelle (Dashboard + Planning + Chatbot)

### Planning Journalier

| Jour | Date | Matin (2h) | Après-midi (2h) | Livrable |
|------|------|------------|-----------------|----------|
| **Lun** | 17/02 | Dashboard UI layout | Score Circle Widget | ✅ Dashboard 50% |
| **Mar** | 18/02 | Graphiques (fl_chart) | Alertes et notifications UI | ✅ Dashboard 100% |
| **Mer** | 19/02 | Planning Screen layout | Calendar Widget | ✅ Planning UI |
| **Jeu** | 20/02 | Backend: Endpoints Focus | Backend: Endpoints Planning | ✅ API Focus+Plan |
| **Ven** | 21/02 | Chatbot Screen UI | Backend: RAG Integration | ✅ Chatbot OK |
| **Sam** | 22/02 | Flutter ↔ Backend (Dio) | Tests connexion complète | ✅ Tout connecté |
| **Dim** | 23/02 | Bug fixes | Code review | ✅ MVP stable |

### Checklist Semaine 3

- [ ] Dashboard : Layout et structure
- [ ] Dashboard : Score widget animé
- [ ] Dashboard : Graphique temps réel (fl_chart)
- [ ] Planning : Écran calendrier
- [ ] Planning : Sessions cards
- [ ] Chatbot : Interface chat bulles
- [ ] Chatbot : Upload PDF
- [ ] Backend : Endpoints focus (/focus/*)
- [ ] Backend : Endpoints planning (/planning/*)
- [ ] Backend : RAG intégré
- [ ] Connexion Flutter ↔ Backend avec Dio

---

## 📆 SEMAINE 4 : Finition & Intégration

**Objectif** : App complète, testée, prête pour démo

### Planning Journalier

| Jour | Date | Matin (2h) | Après-midi (2h) | Livrable |
|------|------|------------|-----------------|----------|
| **Lun** | 24/02 | Stats Screen | Graphiques historique | ✅ Stats OK |
| **Mar** | 25/02 | WebSocket setup (Backend) | WebSocket Flutter | ✅ Real-time |
| **Mer** | 26/02 | Settings Screen | Notifications locales | ✅ Settings OK |
| **Jeu** | 27/02 | Intégration Hardware | Tests avec ESP32 data | ✅ Hardware OK |
| **Ven** | 28/02 | Bug fixes | Tests complets | ✅ Bugs fixés |
| **Sam** | 01/03 | UI Polish | Animations simples | ✅ UI belle |
| **Dim** | 02/03 | Documentation | Préparation démo | ✅ TERMINÉ |

### Checklist Semaine 4

- [ ] Écran Statistiques complet
- [ ] WebSocket temps réel fonctionnel
- [ ] Écran Paramètres
- [ ] Notifications locales
- [ ] Réception données Hardware (mocks ou réel)
- [ ] Tests end-to-end
- [ ] Bug fixes
- [ ] UI Polish final
- [ ] Documentation README
- [ ] Démo préparée

---

## 📊 Jalons Clés

| Jalon | Date | Critère de succès |
|-------|------|-------------------|
| **J1** | 09/02 | App Flutter qui appelle une API externe ✓ |
| **J2** | 16/02 | Backend + Chatbot RAG fonctionnel ✓ |
| **J3** | 23/02 | MVP complet (Dashboard + Planning + Chat) ✓ |
| **J4** | 02/03 | 🎉 App terminée, prête pour démo |

---

## ⏰ Temps Quotidien

| Semaine | Type | Heures/jour | Total |
|---------|------|-------------|-------|
| S1 | Formation Flutter | 2.5h | 17h |
| S2 | Formation Backend + IA | 3h | 21h |
| S3 | Développement MVP | 4h | 28h |
| S4 | Finition | 4h | 28h |
| **TOTAL** | | | **~70-75h** |

---

## ✅ Livrables Finaux

| Livrable | Format | Date |
|----------|--------|------|
| Application Flutter | APK Android | 02/03 |
| Backend API | Docker container | 02/03 |
| Documentation | README.md | 02/03 |
| Démo | Vidéo 3 min | 02/03 |

---

**Signature** : _________________________  
**Date** : _________________________
