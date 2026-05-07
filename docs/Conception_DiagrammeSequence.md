# 📐 Diagrammes de Séquence – Smart Focus & Life Assistant

**Version** : 3.0  
**Date** : 03 Mai 2026  
**Phase** : Conception  
**Approche** : BCE (Boundary – Control – Entity)  

> **Convention BCE** : Chaque diagramme utilise l'architecture d'analyse UML en 3 couches.

| Stéréotype | Rôle | Notation |
|:---:|--------|---------|
| `<<Boundary>>` | Interface utilisateur / point d'entrée externe | `🖥️` |
| `<<Control>>` | Logique métier / orchestration | `⚙️` |
| `<<Entity>>` | Données persistantes / modèle du domaine | `🗄️` |

---

## 1. 🔐 Module Authentification

### 1.1 Inscription (UC1)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface d'inscription
    participant C as ⚙️ AuthController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Saisir email, mot de passe, nom, rôle
    B->>B: Valider les champs (format email, mdp fort)
    B->>C: demanderInscription(email, mdp, nom, rôle)
    C->>E: rechercherUtilisateur(email)

    alt Email déjà utilisé
        E-->>C: Utilisateur existant
        C-->>B: Erreur "Email déjà utilisé"
        B-->>Utilisateur: Afficher message d'erreur
    else Email disponible
        E-->>C: Aucun résultat
        C->>C: hasherMotDePasse(mdp)
        C->>E: créerUtilisateur(email, hash, nom, rôle)
        C->>E: créerProfil(userId, valeurs par défaut)
        C->>C: générerJetons(accessToken, refreshToken)
        C-->>B: Inscription réussie + jetons
        B->>B: sauvegarderJetons(localement)
        B-->>Utilisateur: Rediriger vers le tableau de bord
    end
```

### 1.2 Connexion (UC2)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface de connexion
    participant C as ⚙️ AuthController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Saisir email et mot de passe
    B->>C: demanderConnexion(email, mdp)
    C->>E: rechercherUtilisateur(email)

    alt Utilisateur non trouvé ou mot de passe incorrect
        E-->>C: Échec vérification
        C-->>B: Erreur "Identifiants invalides"
        B-->>Utilisateur: Afficher message d'erreur
    else Authentification réussie
        E-->>C: Utilisateur vérifié
        C->>E: mettreAJourDernièreConnexion(userId)
        C->>C: générerJetons(accessToken, refreshToken)
        C-->>B: Connexion réussie + jetons
        B->>B: sauvegarderJetons(localement)
        B-->>Utilisateur: Rediriger vers le tableau de bord
    end
```

### 1.3 Gestion du Profil (UC3)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface des paramètres
    participant C as ⚙️ ProfilController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Ouvrir les paramètres
    B->>C: chargerProfil(userId)
    C->>E: lireProfil(userId)
    E-->>C: Données du profil
    C-->>B: Profil chargé
    B-->>Utilisateur: Afficher formulaire pré-rempli

    Utilisateur->>B: Modifier (objectifs, notifications, avatar)
    B->>C: mettreAJourProfil(userId, modifications)
    C->>C: validerModifications()
    C->>E: sauvegarderProfil(userId, modifications)
    E-->>C: Profil mis à jour
    C-->>B: Confirmation
    B-->>Utilisateur: "Profil mis à jour ✅"
```

---

## 2. 👁️ Module Vision & Monitoring CV

### 2.1 Démarrer une Session de Monitoring (UC4)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant BP as 🖥️ Interface pi_client
    participant BM as 🖥️ Interface mobile (Dashboard)
    participant C as ⚙️ VisionController
    participant E as 🗄️ Base de Données

    Note over BP: Lancement du pipeline caméra

    BP->>C: créerSession(id, horodatage)
    C->>E: insérerSession(id, début, active=vrai)
    E-->>C: Session créée
    C-->>BP: Confirmation

    Utilisateur->>BM: Ouvrir le tableau de bord
    BM->>C: récupérerSessionsActives()
    C->>E: lireSessionsActives()
    E-->>C: Liste des sessions
    C-->>BM: Sessions actives
    BM-->>Utilisateur: Session de monitoring détectée 🟢

    loop Acquisition continue (~500ms)
        BP->>BP: Capturer image → Analyse locale (pose, visage)
        BP->>BP: Calculer scores (attention, posture, vigilance, stress, focus)
        BP->>C: envoyerSnapshot(sessionId, scores)
        C->>E: insérerSnapshot(sessionId, scores, horodatage)
        C-->>BP: Confirmation
    end

    loop Consultation périodique (3-5s)
        BM->>C: récupérerDernierSnapshot(sessionId)
        C->>E: lireDernierSnapshot(sessionId)
        E-->>C: Snapshot le plus récent
        C-->>BM: Données de monitoring
        BM-->>Utilisateur: Mise à jour des jauges en temps réel 📊
    end
```

### 2.2 Événements et Finalisation (UC5, UC7)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant BP as 🖥️ Interface pi_client
    participant BM as 🖥️ Interface mobile
    participant C as ⚙️ VisionController
    participant E as 🗄️ Base de Données

    alt Événement détecté (distraction, mauvaise posture)
        BP->>C: signalerÉvénement(sessionId, type, niveau, description)
        C->>E: insérerÉvénement(sessionId, type, niveau, description)
        C-->>BP: Confirmation
    end

    Note over BP: Fin de session (arrêt manuel ou timeout)

    BP->>C: finaliserSession(sessionId, résumé)
    C->>E: clôturerSession(sessionId, fin, métadonnées)
    E-->>C: Session finalisée
    C-->>BP: Confirmation

    BM->>C: La consultation détecte session inactive
    C-->>BM: Session terminée
    BM-->>Utilisateur: Afficher résumé de la session 📊
```

---

## 3. 📅 Module Planning Intelligent

### 3.1 Générer un Planning IA (UC9)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface de planning
    participant C as ⚙️ PlanningController
    participant AI as ⚙️ PlanningAIService
    participant LLM as ⚙️ GeminiClient (Groq)
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Demander "Générer Planning"
    B->>C: générerPlanning(date, documentId?)
    C->>E: supprimerSessionsIA(date)
    C->>E: chargerContexte(profil, sessions, examens, sommeil)

    alt Document CSV fourni
        C->>AI: analyserCSV(date, typeSemaine)
        AI->>AI: calculerCréneauxLibres(8h-22h)
        AI->>LLM: personnaliserSujets(créneaux)
        LLM-->>AI: Assignations sujets/priorités
    else Document PDF fourni
        C->>AI: extraireEmploiDuTemps(collection, jour)
        AI->>LLM: extraireCréneaux(contenu)
        LLM-->>AI: Créneaux structurés
    else Sans document
        C->>AI: générerPlanningLibre(date, profil)
        AI->>LLM: assignerSujets(créneauxLibres)
        LLM-->>AI: Sujets assignés
    end

    AI-->>C: Sessions générées
    loop Pour chaque session
        C->>E: insérerSession(sujet, début, fin, ia=vrai)
    end

    C-->>B: Planning généré
    B-->>Utilisateur: Afficher le planning ✅
```

### 3.2 Modifier / Supprimer une Session (UC10, UC11)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface de planning
    participant C as ⚙️ PlanningController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Consulter le planning du jour
    B->>C: chargerPlanning(date)
    C->>E: lireSessionsDuJour(date)
    E-->>C: Sessions
    C-->>B: Planning du jour
    B-->>Utilisateur: Afficher le planning

    Note over Utilisateur, B: --- Modification ---

    Utilisateur->>B: Modifier une session
    B->>C: modifierSession(id, modifications)
    C->>E: mettreAJourSession(id, modifications)
    C-->>B: Session modifiée
    B-->>Utilisateur: Mise à jour confirmée ✅

    Note over Utilisateur, B: --- Suppression ---

    Utilisateur->>B: Supprimer une session
    B-->>Utilisateur: Demander confirmation
    Utilisateur->>B: Confirmer
    B->>C: supprimerSession(id)
    C->>E: supprimerSession(id)
    C-->>B: Session supprimée
    B-->>Utilisateur: Suppression confirmée ✅
```

---

## 4. 💬 Module Chatbot RAG

### 4.1 Uploader un Document PDF (UC12)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface chatbot
    participant C as ⚙️ ChatbotController
    participant RAG as ⚙️ RAGService
    participant EV as 🗄️ Base Vectorielle
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Sélectionner un fichier PDF
    B->>B: Valider format et taille
    B->>C: uploaderDocument(fichier)
    C->>E: enregistrerDocument(nom, chemin, utilisateur)
    E-->>C: documentId

    C->>RAG: indexerDocument(chemin, collection)
    RAG->>RAG: Extraire texte → découper en chunks
    loop Pour chaque chunk
        RAG->>RAG: Générer embedding (768 dimensions)
        RAG->>EV: stockerChunk(chunk, embedding)
    end

    RAG-->>C: Indexation terminée (nombre de pages)
    C->>E: mettreAJourDocument(documentId, pages)
    C-->>B: Document indexé
    B-->>Utilisateur: "Document indexé ✅"
```

### 4.2 Poser une Question RAG (UC13)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface chatbot
    participant C as ⚙️ ChatbotController
    participant RAG as ⚙️ RAGService
    participant EV as 🗄️ Base Vectorielle
    participant LLM as ⚙️ GeminiClient (Groq)
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Poser une question
    B->>C: envoyerQuestion(question, documentIds)
    C->>RAG: rechercherContexte(question, collections)

    RAG->>RAG: Générer embedding de la question
    RAG->>EV: rechercheSimilarité(embedding, k=5)
    EV-->>RAG: 5 chunks les plus pertinents

    RAG->>RAG: Construire le prompt (système + contexte + question)
    RAG->>LLM: générerRéponse(prompt)
    LLM-->>RAG: Réponse générée
    RAG->>RAG: Extraire les sources
    RAG-->>C: Réponse + sources

    C->>E: sauvegarderMessage(question, réponse, sources)
    C-->>B: Réponse avec sources
    B-->>Utilisateur: Afficher réponse + sources citées 📄
```

### 4.3 Générer un Quiz (UC14)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface quiz
    participant C as ⚙️ QuizController
    participant RAG as ⚙️ RAGService
    participant LLM as ⚙️ GeminiClient (Groq)
    participant E as 🗄️ Base de Données

    Utilisateur->>B: "Générer un Quiz"
    B->>C: générerQuiz(documentId, nombreQuestions)
    C->>RAG: générerQuiz(collection, nombreQuestions)
    RAG->>LLM: promptGénérationQCM(contenu)
    LLM-->>RAG: Questions structurées (JSON)
    RAG-->>C: Quiz généré

    C->>E: insérerQuiz(utilisateur, document, titre)
    loop Pour chaque question
        C->>E: insérerQuestion(quizId, question, options, correct)
    end

    C-->>B: Quiz prêt
    B-->>Utilisateur: Afficher quiz interactif 📝
```

### 4.4 Créer et Réviser des Flashcards (UC15)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface flashcards
    participant C as ⚙️ FlashcardController
    participant RAG as ⚙️ RAGService
    participant SM2 as ⚙️ SM2Service
    participant E as 🗄️ Base de Données

    Utilisateur->>B: "Créer des Flashcards"
    B->>C: générerFlashcards(documentId, nombre)
    C->>RAG: générerFlashcards(collection, nombre)
    RAG-->>C: Flashcards (recto/verso)

    loop Pour chaque flashcard
        C->>E: insérerFlashcard(recto, verso, facteur=2.5)
    end
    C-->>B: Flashcards créées
    B-->>Utilisateur: Afficher le deck 🃏

    Note over Utilisateur, B: --- Mode Révision (SM-2) ---

    loop Pour chaque flashcard à réviser
        B-->>Utilisateur: Afficher recto (question)
        Utilisateur->>B: Retourner → évaluer (qualité: 0-5)
        B->>C: réviserFlashcard(id, qualité)
        C->>SM2: calculerProchainRappel(qualité, répétitions, facteur, intervalle)
        SM2-->>C: Nouveaux paramètres (intervalle, facteur, prochainRappel)
        C->>E: mettreAJourFlashcard(id, nouveauxParamètres)
        C-->>B: Prochaine date de révision
    end
```

---

## 5. 🌙 Module Sommeil & Réveil

### 5.1 Enregistrer les Données de Sommeil (UC21)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface sommeil
    participant C as ⚙️ SleepController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Saisir données de sommeil (heure coucher/lever)
    B->>C: enregistrerSommeil(début, fin, durée)
    C->>C: calculerScoreSommeil(durée, phases)
    C->>E: insérerEnregistrement(userId, début, fin, score)
    E-->>C: Enregistrement créé
    C-->>B: Score calculé
    B-->>Utilisateur: "Sommeil enregistré ✅ Score: 78/100"
```

### 5.2 Consulter l'Historique Sommeil (UC22)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface sommeil
    participant C as ⚙️ SleepController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Ouvrir "Sommeil"
    B->>C: chargerHistorique(userId)
    C->>E: lireEnregistrements(userId, limite=30)
    E-->>C: Historique
    C-->>B: Données formatées
    B-->>Utilisateur: Afficher graphiques sommeil 📊
```

### 5.3 Adapter le Planning selon le Sommeil (UC24)

```mermaid
sequenceDiagram
    participant C as ⚙️ PlanningController
    participant AI as ⚙️ PlanningAIService
    participant E as 🗄️ Base de Données
    participant B as 🖥️ Interface de planning
    actor Utilisateur

    Note over C: Déclenché lors de la génération du planning

    C->>E: lireScoreSommeil(date)
    E-->>C: scoreSommeil = 45

    alt Score sommeil < 60
        C->>AI: recalculerPlanning(sessions, scoreSommeil)
        AI->>AI: Ajuster durées et pauses des sessions IA
        AI-->>C: Sessions recalculées
        C->>E: mettreAJourSessions(sessionsAjustées)
        C-->>B: Planning allégé
        B-->>Utilisateur: "⚠️ Sommeil insuffisant. Planning adapté."
    end
```

---

## 6. 📊 Module Dashboard & Statistiques

### 6.1 Consulter le Dashboard Global (UC27)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface Dashboard
    participant C as ⚙️ DashboardController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Ouvrir l'application
    B->>C: chargerTableauDeBord(userId)

    C->>E: lireSessionsDuJour(userId, date)
    C->>E: lireScoreSommeil(userId, date)
    C->>E: lireMoyenneFocus(userId, date)
    E-->>C: Données agrégées

    C->>C: assemblerDonnéesDashboard()
    C-->>B: Tableau de bord complet
    B-->>Utilisateur: Afficher Dashboard 🏠

    Note over B, Utilisateur: 🎯 Focus: 78% | 🌙 Sommeil: 72<br/>📅 Sessions: 4 | Prochaine: Math 14h
```

### 6.2 Consulter les Insights (UC28)

```mermaid
sequenceDiagram
    actor Utilisateur
    participant B as 🖥️ Interface statistiques
    participant C as ⚙️ StatsController
    participant E as 🗄️ Base de Données

    Utilisateur->>B: Ouvrir "Statistiques"
    B->>C: chargerInsights(userId, période=7j)

    C->>E: lireSessionsSemaine(userId)
    C->>E: lireTendanceFocus(userId)
    C->>C: calculerTauxComplétion()
    C->>C: identifierSujetsForts/Faibles()

    C-->>B: Insights structurés
    B-->>Utilisateur: Afficher statistiques hebdomadaires 📊
```

---

## 7. Résumé des Diagrammes de Séquence

| Module | Diagrammes | CU Couverts |
|--------|:----------:|:-----------:|
| 🔐 Authentification | 3 | UC1, UC2, UC3 |
| 👁️ Vision & Monitoring CV | 2 | UC4, UC5, UC7 |
| 📅 Planning Intelligent | 2 | UC9, UC10, UC11 |
| 💬 Chatbot RAG | 4 | UC12, UC13, UC14, UC15 |
| 🌙 Sommeil & Réveil | 3 | UC21, UC22, UC24 |
| 📊 Dashboard & Stats | 2 | UC27, UC28 |
| **Total** | **16** | **22 CU** |

---

## 8. Légende BCE

| Stéréotype | Symbole | Rôle | Exemples |
|:---:|:---:|--------|---------|
| `<<Boundary>>` | `🖥️` | Interface / Point d'entrée | Interface de connexion, Interface chatbot, Interface pi_client |
| `<<Control>>` | `⚙️` | Logique métier / Orchestration | AuthController, PlanningController, RAGService, SM2Service |
| `<<Entity>>` | `🗄️` | Données persistantes | Base de Données, Base Vectorielle |

---

**Validé par** : _________________________  
**Date de validation** : _________________________
