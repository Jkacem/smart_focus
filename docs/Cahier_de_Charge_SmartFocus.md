# 📋 Cahier de Charge – Smart Focus & Life Assistant

**Version** : 1.0  
**Date** : 02 Février 2026  
**Projet** : Smart Focus & Life Assistant  
**Type** : Assistant Intelligent IoT + IA  

---

## 1. Présentation du Projet

### 1.1 Contexte

Les étudiants, professionnels et enseignants font face à plusieurs défis quotidiens :
- Difficulté à maintenir la concentration (distractions, multitâche)
- Mauvaise posture entraînant fatigue et douleurs
- Gestion inefficace du temps et des révisions
- Sommeil irrégulier affectant la mémoire et l'apprentissage

**Constat** : Les solutions actuelles sont fragmentées (applications, objet bureautique). Aucune solution unifiée, physique, intelligente et interactive n'existe.

### 1.2 Objectif

Créer un **assistant intelligent tout-en-un** qui :
- Centralise toutes les fonctions critiques dans un objet tangible
- Intègre une IA avancée pour personnaliser l'accompagnement
- Connecte le boîtier à une application mobile intelligente
- Offre un feedback physique et digital pour optimiser le bien-être

### 1.3 Public Cible

| Cible | Besoins |
|-------|---------|
| **Étudiants** | Révisions optimisées, concentration, gestion du stress |
| **Professionnels** | Productivité, posture, équilibre travail-repos |
| **Enseignants** | Organisation, préparation de cours, bien-être |

---

## 2. Description Fonctionnelle

### 2.1 Architecture Globale

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ARCHITECTURE SYSTÈME                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   [BOÎTIER HARDWARE - ESP32]                                       │
│   • ESP32-CAM (capture images, WiFi)                               │
│   • Capteurs (MAX30102, micro, pression)                           │
│   • Écran TFT, LEDs RGB, haut-parleur                              │
│   • Envoie images/données brutes au serveur                        │
│              │                                                      │
│              │ HTTP/MQTT (images + données capteurs)               │
│              ▼                                                      │
│   [BACKEND SERVEUR]                                                │
│   • API REST/WebSocket                                              │
│   • Base de données PostgreSQL                                      │
│   • ML : Détection posture, fatigue, visage (Python)               │
│   • IA : LangChain, RAG, Planning                                  │
│              │                                                      │
│              │ HTTP/WebSocket (résultats ML + données)             │
│              ▼                                                      │
│   [APPLICATION MOBILE FLUTTER]                                      │
│   • Dashboard temps réel                                            │
│   • Planning intelligent                                            │
│   • Chatbot RAG                                                     │
│   • Statistiques & conseils                                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Fonctionnalités Principales

#### A. Smart Study Assistant (Concentration)
| Fonctionnalité | Description |
|----------------|-------------|
| Suivi temps réel | Analyse posture, visage, bâillements, regard via caméra |
| Score de focus | Calcul en temps réel basé sur les capteurs |
| Alertes | LED et vibration en cas de baisse d'attention |
| Mesure durée | Tracking des sessions de concentration |

#### B. Chatbot RAG (Révisions Intelligentes)
| Fonctionnalité | Description |
|----------------|-------------|
| Import documents | Upload PDF, slides, cours |
| Questions/Réponses | Réponses basées uniquement sur les documents |
| Quiz automatiques | Génération de questions pour tester les connaissances |
| Flashcards | Création de fiches de révision |
| Planning révision | Sessions automatiquement planifiées |

#### C. Posture & Ergonomie
| Fonctionnalité | Description |
|----------------|-------------|
| Détection posture | Caméra détecte dos courbé, tête basse |
| Alertes immédiates | LED orange + vibration douce |
| Statistiques | Suivi journalier et hebdomadaire |
| Conseils | Recommandations ergonomiques personnalisées |

#### D. Smart Sleep & Réveil
| Fonctionnalité | Description |
|----------------|-------------|
| Détection sommeil | Capteurs pression, vibration, micro |
| Score sommeil | Analyse qualité (léger/profond) |
| Réveil intelligent | Progressif avec LED, son doux, vibration |
| Adaptation planning | Mauvais sommeil → révisions allégées |

#### E. Application Mobile
| Fonctionnalité | Description |
|----------------|-------------|
| Dashboard | Vue globale scores, graphiques, alertes |
| Planning | Calendrier intelligent avec sessions |
| Statistiques | Historique focus, posture, sommeil |
| Notifications | Alertes non agressives, conseils |
| Réseaux sociaux | Limites d'utilisation, blocage automatique |

#### F. Gestion Stress & Respiration
| Fonctionnalité | Description |
|----------------|-------------|
| Détection distractions | Alertes en cas de distraction prolongée |
| Exercices guidés | Respiration affichée sur écran |
| Micro-pauses | Suggestions pour améliorer bien-être |

#### G. Interaction Vocale (Optionnelle)
| Fonctionnalité | Description |
|----------------|-------------|
| Commandes vocales | Poser des questions au boîtier |
| Réponses audio | L'IA répond oralement |
| Intégration chatbot | Questions sur les cours à la voix |

---

## 3. Spécifications Techniques

### 3.1 Hardware (Boîtier)

#### Composants Principaux
| Composant | Modèle | Rôle |
|-----------|--------|------|
| Microcontrôleur | ESP32-CAM | Caméra + WiFi + traitement |
| Capteur cardiaque | MAX30102 | Rythme cardiaque, SpO2 |
| Écran | TFT ILI9341 2.4" | Affichage score, alertes |
| LEDs | WS2812B (NeoPixel) | Anneau RGB feedback visuel |
| Audio sortie | MAX98357A I2S | Haut-parleur |
| Audio entrée | INMP441 I2S | Microphone |
| Capteur pression | Optionnel | Détection présence |

#### Spécifications Boîtier
| Caractéristique | Valeur |
|-----------------|--------|
| Dimensions | H: 25-30 cm, L: 15 cm |
| Forme | Cylindre ou ovale arrondi |
| Matériau | ABS ou impression 3D |
| Couleurs | Blanc, gris, bleu clair |
| Alimentation | USB-C 5V |

### 3.2 Backend API

#### Technologies
| Technologie | Version | Usage |
|-------------|---------|-------|
| Python | 3.11+ | Langage principal |
| FastAPI | 0.100+ | Framework API |
| PostgreSQL | 15+ | Base de données |
| Redis | 7+ | Cache, sessions |
| LangChain | 0.1+ | Framework RAG |
| ChromaDB | 0.4+ | Base vectorielle |
| OpenAI API | GPT-3.5/4 | Modèle de langage |

#### Endpoints API
| Catégorie | Endpoints |
|-----------|-----------|
| Auth | `/auth/register`, `/auth/login`, `/auth/refresh` |
| Focus | `/focus/session`, `/focus/update`, `/focus/stats` |
| Planning | `/planning/today`, `/planning/generate` |
| Chatbot | `/chatbot/ask`, `/chatbot/documents`, `/chatbot/quiz` |
| Sleep | `/sleep/log`, `/sleep/stats` |
| WebSocket | `/ws/realtime` |

### 3.3 Application Mobile

#### Technologies
| Technologie | Version | Usage |
|-------------|---------|-------|
| Flutter | 3.16+ | Framework mobile |
| Dart | 3.2+ | Langage |
| Riverpod | 2.4+ | State management |
| Dio | 5.3+ | HTTP client |
| fl_chart | 0.65+ | Graphiques |
| Hive | 2.2+ | Stockage local |

#### Écrans
| Écran | Priorité |
|-------|----------|
| Dashboard | Haute |
| Planning | Haute |
| Statistiques | Moyenne |
| Chatbot | Haute |
| Paramètres | Moyenne |
| Onboarding | Basse |

### 3.4 IA & Machine Learning (Côté Serveur)

> **Note** : Tout le ML est exécuté côté serveur. L'ESP32 envoie les images/données brutes, le serveur traite et renvoie les résultats.

#### Modèles ML Vision (Personne 1 – Serveur Python)
| Modèle | Technologie | Usage | Responsable |
|--------|-------------|-------|-------------|
| Détection posture | MediaPipe / OpenCV | Analyse position corps | Personne 1 |
| Détection fatigue | TensorFlow / PyTorch | Bâillements, yeux fermés | Personne 1 |
| Détection visage | MediaPipe Pose | Position tête, regard | Personne 1 |
| Analyse mouvement | OpenCV | Distraction, absence | Personne 1 |

#### IA NLP & Planning (Personne 2 – Serveur Python)
| Composant | Technologie | Usage | Responsable |
|-----------|-------------|-------|-------------|
| RAG Chatbot | LangChain + ChromaDB | Questions sur les cours | Personne 2 |
| Embeddings | OpenAI text-embedding-3 | Vectorisation documents | Personne 2 |
| LLM | GPT-3.5-turbo / GPT-4 | Génération réponses | Personne 2 |
| Planning IA | Algorithme custom | Optimisation sessions | Personne 2 |

---

## 4. Répartition des Tâches

### 4.1 Équipe

| Membre | Responsabilités |
|--------|-----------------|
| **Personne 1** | Hardware, Firmware ESP32, Capteurs, Boîtier 3D ,AI/ML|
| **Personne 2** | Application Flutter, Backend API, IA/RAG, Intégration |

### 4.2 Détail par Personne

#### Personne 1 – Hardware, Firmware & ML Serveur
**Hardware (ESP32)** :
- Configuration ESP32-CAM (capture + envoi images)
- Intégration capteurs (MAX30102, micro)
- Conception écran TFT et LEDs
- Conception et impression 3D du boîtier
- Communication HTTP/MQTT vers backend

**ML Serveur (Python)** :
- Modèle détection posture (MediaPipe/OpenCV)
- Modèle détection fatigue (TensorFlow/PyTorch)
- Modèle analyse visage et regard
- API endpoints pour recevoir images et retourner résultats

#### Personne 2 – Application Flutter & IA NLP
**Application Mobile** :
- Application Flutter complète
- Dashboard, Planning, Statistiques, Chatbot

**Backend & IA** :
- Backend FastAPI avec PostgreSQL
- Chatbot RAG avec LangChain
- Planning intelligent avec IA
- WebSocket temps réel
- Intégration et tests end-to-end

---

## 5. Planning Projet

### 5.1 Phases

| Phase | Durée | Description |
|-------|-------|-------------|
| **Phase 1** | Semaines 1-3 | Fondations (setup, structure, prototypes) |
| **Phase 2** | Semaines 4-7 | Features Core (dashboard, planning, capteurs) |
| **Phase 3** | Semaines 8-11 | IA & Intégration (RAG, planning adaptatif) |
| **Phase 4** | Semaines 12-14 | Finition (tests, polish, documentation) |

### 5.2 Jalons Clés

| Jalon | Semaine | Livrable |
|-------|---------|----------|
| J1 | S3 | Prototype boîtier + App skeleton connectée |
| J2 | S7 | Dashboard fonctionnel + Capteurs opérationnels |
| J3 | S11 | IA RAG + Planning + Intégration complète |
| J4 | S14 | Produit final prêt pour démonstration |

---

## 6. Contraintes et Risques

### 6.1 Contraintes

| Contrainte | Impact | Mitigation |
|------------|--------|------------|
| Délai limité | Prioriser features essentielles | Planning serré, MVP first |
| Budget matériel | Composants accessibles | ESP32 + capteurs basiques |
| Connexion WiFi | Dépendance réseau | Mode offline partiel |
| API OpenAI | Coût tokens | Modèle frugal, cache réponses |

### 6.2 Risques

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Retard intégration | Moyenne | Élevé | Mocks + tests précoces |
| Performance IA | Moyenne | Moyen | Optimisation prompts |
| Problème capteurs | Faible | Élevé | Tests unitaires hardware |
| Complexité RAG | Moyenne | Moyen | Documentation LangChain |

---

## 7. Livrables

### 7.1 Livrables Techniques

| Livrable | Format | Responsable |
|----------|--------|-------------|
| Boîtier complet | Physique | Personne 1 |
| Code firmware | Repository Git | Personne 1 |
| Application mobile | APK / TestFlight | Personne 2 |
| Backend API | Docker + cloud | Personne 2 |
| Documentation technique | Markdown/PDF | Les deux |

### 7.2 Livrables Démonstration

| Livrable | Description |
|----------|-------------|
| Démo live | Démonstration complète du système |
| Vidéo | Présentation 3-5 minutes |
| Poster | Affiche récapitulative |
| Rapport | Document technique complet |

---

## 8. Critères de Succès

| Critère | Objectif |
|---------|----------|
| Fonctionnalité | Toutes les features principales opérationnelles |
| Performance | Temps réel < 500ms latence |
| Fiabilité | Système stable sur démo de 15 minutes |
| UX | Interface intuitive, feedback clair |
| Innovation | Originalité de la solution unifiée |
| Présentation | Démonstration convaincante au jury |

---

## 9. Annexes

### 9.1 Glossaire

| Terme | Définition |
|-------|------------|
| RAG | Retrieval Augmented Generation – IA qui répond basée sur des documents |
| ESP32 | Microcontrôleur WiFi/Bluetooth pour IoT |
| WebSocket | Protocole de communication temps réel bidirectionnelle |
| Embeddings | Représentation vectorielle de texte pour l'IA |
| Riverpod | Solution de state management pour Flutter |

### 9.2 Références

- Flutter Documentation : https://flutter.dev
- FastAPI Documentation : https://fastapi.tiangolo.com
- LangChain Documentation : https://python.langchain.com
- ESP32 Documentation : https://docs.espressif.com

---

**Validé par** : _________________________  
**Date de validation** : _________________________

---

