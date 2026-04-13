  # 📱 PV Personne 2 – Application Mobile, Backend & IA

  **Projet** : Smart Focus & Life Assistant  
  **Responsable** : Personne 2  
  **Date** : 02 Février 2026  

  ---

  ## 🎯 Périmètre de Responsabilité

  Personne 2 est responsable de **toute la partie logicielle** du projet :

  | Domaine | Description |
  |---------|-------------|
  | **Application Flutter** | Interface utilisateur mobile complète |
  | **Backend API** | Serveur, base de données, logique métier |
  | **IA & Chatbot RAG** | Intelligence artificielle, planning adaptatif |
  | **Intégration** | Communication avec le hardware (ESP32) |

  ---

  ## 1️⃣ Application Flutter

  ### 1.1 Écrans à Développer

  | Écran | Fonctionnalités |
  |-------|-----------------|
  | **Onboarding** | Introduction, création profil, objectifs |
  | **Dashboard** | Score focus temps réel, graphiques, alertes visuelles |
  | **Planning** | Calendrier intelligent, sessions de révision |
  | **Statistiques** | Historique focus, posture, sommeil (graphiques) |
  | **Chatbot** | Interface conversation, upload PDF, quiz |
  | **Paramètres** | Profil, notifications, limites réseaux sociaux |

  ### 1.2 Stack Technique Flutter

  | Package | Usage |
  |---------|-------|
  | `flutter_riverpod` | State management |
  | `dio` | Requêtes HTTP |
  | `socket_io_client` | WebSocket temps réel |
  | `fl_chart` | Graphiques et statistiques |
  | `hive` | Stockage local |
  | `flutter_local_notifications` | Notifications locales |
  | `google_fonts` | Typographie moderne |

  ### 1.3 Livrables Flutter

  - [ ] Structure projet et architecture clean
  - [ ] Design system (couleurs, fonts, composants)
  - [ ] Navigation et routing
  - [ ] Écran Dashboard avec score temps réel
  - [ ] Écran Planning avec calendrier
  - [ ] Écran Statistiques avec graphiques
  - [ ] Interface Chatbot
  - [ ] Écran Paramètres
  - [ ] Notifications intelligentes
  - [ ] Connexion avec Backend API

  ---

  ## 2️⃣ Backend API

  ### 2.1 Technologies

  | Technologie | Usage |
  |-------------|-------|
  | **FastAPI** | Framework API Python |
  | **PostgreSQL** | Base de données principale |
  | **Redis** | Cache et sessions |
  | **WebSocket** | Communication temps réel |
  | **Docker** | Conteneurisation |

  ### 2.2 Endpoints à Développer

  #### Authentification
  ```
  POST   /api/auth/register     → Inscription utilisateur
  POST   /api/auth/login        → Connexion
  POST   /api/auth/refresh      → Rafraîchir token
  ```

  #### Focus & Monitoring
  ```
  POST   /api/focus/session     → Créer session de travail
  PUT    /api/focus/session/{id}/update   → MAJ score temps réel
  GET    /api/focus/stats/daily           → Stats journalières
  GET    /api/focus/stats/weekly          → Stats hebdomadaires
  WS     /ws/realtime                     → WebSocket temps réel
  ```

  #### Planning
  ```
  GET    /api/planning/today        → Planning du jour
  POST   /api/planning/generate     → Générer planning intelligent
  PUT    /api/planning/session/{id} → Modifier session
  DELETE /api/planning/session/{id} → Supprimer session
  ```

  #### Chatbot RAG
  ```
  POST   /api/chatbot/ask            → Poser une question
  POST   /api/chatbot/documents      → Uploader un PDF
  GET    /api/chatbot/documents      → Liste des documents
  POST   /api/chatbot/quiz/generate  → Générer un quiz
  ```

  #### Sommeil & Bien-être
  ```
  POST   /api/sleep/log         → Enregistrer données sommeil
  GET    /api/sleep/stats       → Statistiques sommeil
  GET    /api/wellness/tips     → Conseils personnalisés
  ```

  ### 2.3 Livrables Backend

  - [ ] Setup projet FastAPI
  - [ ] Configuration PostgreSQL + migrations
  - [ ] Endpoints authentification (JWT)
  - [ ] Endpoints focus avec WebSocket
  - [ ] Endpoints planning
  - [ ] Endpoints chatbot
  - [ ] Endpoints sommeil
  - [ ] Documentation API (Swagger)
  - [ ] Tests unitaires
  - [ ] Déploiement Docker

  ---

  ## 3️⃣ IA & Chatbot RAG

  ### 3.1 Technologies IA

  | Technologie | Usage |
  |-------------|-------|
  | **LangChain** | Framework RAG et chaînes LLM |
  | **ChromaDB** | Base de données vectorielle |
  | **OpenAI API** | Modèle de langage (GPT-3.5/4) |
  | **PyPDF** | Extraction texte PDF |
  | **Sentence Transformers** | Embeddings locaux (option) |

  ### 3.2 Fonctionnalités IA

  #### Chatbot RAG (Révisions)
  - [ ] Import et parsing de documents PDF
  - [ ] Découpage en chunks avec overlap
  - [ ] Génération embeddings et stockage vectoriel
  - [ ] Recherche sémantique dans les documents
  - [ ] Génération de réponses contextuelles
  - [ ] Génération de quiz automatiques
  - [ ] Création de flashcards

  #### Planning Intelligent
  - [ ] Analyse des données utilisateur (fatigue, sommeil)
  - [ ] Algorithme d'optimisation du planning
  - [ ] Adaptation dynamique (mauvais sommeil → pauses plus fréquentes)
  - [ ] Priorisation des sujets selon les deadlines
  - [ ] Suggestions de pauses et exercices

  #### Conseils Personnalisés
  - [ ] Analyse des patterns de concentration
  - [ ] Détection des heures productives
  - [ ] Génération de conseils ergonomiques
  - [ ] Recommandations sommeil basées sur les données

  ### 3.3 Livrables IA

  - [ ] Service RAG fonctionnel
  - [ ] Pipeline d'import de documents
  - [ ] Endpoint questions/réponses
  - [ ] Générateur de quiz
  - [ ] Algorithme de planning adaptatif
  - [ ] Système de conseils personnalisés

  ---

  ## 4️⃣ Intégration Hardware

  ### 4.1 Responsabilités Intégration

  | Tâche | Description |
  |-------|-------------|
  | **Contrat API** | Définir le format des données avec Personne 1 |
  | **Endpoints réception** | Recevoir les données des capteurs ESP32 |
  | **WebSocket broadcast** | Envoyer les mises à jour à l'app Flutter |
  | **Mock hardware** | Simuler les données pour développer en parallèle |

  ### 4.2 Format de Données (à valider avec Personne 1)

  ```json
  // Données reçues de l'ESP32
  {
    "device_id": "esp32_001",
    "timestamp": "2026-02-02T10:30:00Z",
    "focus_score": 85,
    "posture_ok": true,
    "heart_rate": 72,
    "fatigue_level": 3,
    "blink_rate": 15,
    "face_detected": true
  }
  ```

  ### 4.3 Livrables Intégration

  - [ ] Document contrat API partagé
  - [ ] Service mock pour simuler hardware
  - [ ] Endpoints réception données capteurs
  - [ ] Logique de traitement temps réel
  - [ ] Tests d'intégration end-to-end

  ---

  ## 📅 Planning Personnel

  ### Phase 1 : Fondations (Semaines 1-3)
  | Semaine | Tâches |
  |---------|--------|
  | **S1** | Setup Flutter + Backend, Design system, Navigation |
  | **S2** | Auth, Dashboard UI, Endpoints de base |
  | **S3** | Connexion Flutter↔Backend, WebSocket, Mock hardware |

  ### Phase 2 : Features Core (Semaines 4-7)
  | Semaine | Tâches |
  |---------|--------|
  | **S4** | Planning UI + endpoints, Statistiques |
  | **S5** | Graphiques, Notifications, Stockage local |
  | **S6** | Setup RAG, Import PDF, ChromaDB |
  | **S7** | Interface Chatbot, Quiz génération |

  ### Phase 3 : IA Avancée (Semaines 8-11)
  | Semaine | Tâches |
  |---------|--------|
  | **S8** | Planning adaptatif, Analyse patterns |
  | **S9** | Conseils personnalisés, Optimisations |
  | **S10** | Intégration hardware réel |
  | **S11** | Tests end-to-end, Debug |

  ### Phase 4 : Finition (Semaines 12-14)
  | Semaine | Tâches |
  |---------|--------|
  | **S12** | UI/UX polish, Animations |
  | **S13** | Tests utilisateurs, Corrections |
  | **S14** | Documentation, Préparation démo |

  ---

  ## ✅ Critères de Validation

  | Critère | Validation |
  |---------|------------|
  | App Flutter fonctionnelle | Dashboard, Planning, Stats, Chatbot |
  | Backend API opérationnel | Tous endpoints fonctionnels |
  | IA RAG performante | Réponses précises basées sur les cours |
  | Temps réel | WebSocket fonctionne sans latence |
  | Intégration | Communication fluide avec hardware |

  ---

  ## 📝 Notes

  - Réunion hebdomadaire avec Personne 1 pour synchronisation
  - Utiliser GitHub avec branches feature pour chaque fonctionnalité
  - Documenter les API avec Swagger/OpenAPI
  - Créer des tests pour les fonctionnalités critiques

  ---

  **Signature** : _________________________  
  **Date** : _________________________
