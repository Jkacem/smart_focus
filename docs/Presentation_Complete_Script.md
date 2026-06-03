# Présentation Complète – Smart Focus & Life Assistant
## Contenu des slides + Script de speech

**Durée totale estimée** : 28–32 minutes  
**Répartition** : Binôme (Slides 1–7) → Toi / Kacem (Slides 8–18)

---
---

# SLIDE 1 — Titre & Introduction

## Contenu visuel du slide

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│          [LOGO DU PROJET — icône cerveau/focus]         │
│                                                         │
│        Smart Focus & Life Assistant                     │
│   ─────────────────────────────────────────────         │
│   Un assistant intelligent pour optimiser               │
│   la concentration, les révisions et le bien-être       │
│                                                         │
│   Présenté par :  [Prénom Binôme]  &  Kacem Jemni       │
│   Encadrant :     [Nom encadrant]                       │
│   Date :          [Date de soutenance]                  │
│                                                         │
│   [Badges technologies : Flutter | FastAPI | Gemini]    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Fond sombre ou dégradé bleu nuit
- Titre en grande police blanche (Inter Bold)
- Sous-titre en gris clair
- Trois petits badges de tech en bas

---

## Speech

> *"Bonjour à tous. Nous vous présentons aujourd'hui notre projet de fin d'études :
> Smart Focus & Life Assistant.
> 
> L'idée derrière ce projet est simple : créer un assistant intelligent,
> à la fois physique et digital, capable d'accompagner un étudiant ou un professionnel
> tout au long de sa journée de travail.
> 
> Je suis Kacem Jemni, responsable de la partie logicielle — backend, intelligence artificielle
> et application mobile. Mon binôme [Prénom], lui, a pris en charge la partie hardware
> et vision par ordinateur.
> 
> On va vous montrer comment ces deux parties s'assemblent pour former un produit cohérent."*

**Durée : 30 secondes**

---
---

# SLIDE 2 — Problématique

## Contenu visuel du slide

```
┌─────────────────────────────────────────────────────────┐
│  Pourquoi ce projet ?                                   │
│  ─────────────────────────────────────────────          │
│                                                         │
│   😵  Concentration    │   🪑  Mauvaise posture         │
│   difficile à          │   → fatigue, douleurs          │
│   maintenir            │   dorsales                     │
│   ────────────────────────────────────────              │
│   📚  Révisions        │   😴  Sommeil irrégulier       │
│   désorganisées        │   → mémoire affectée,          │
│   → mauvais résultats  │   moins de concentration       │
│                                                         │
│   ──────────────────────────────────────────            │
│   ⚠️  Les solutions actuelles sont fragmentées.         │
│   Aucune app ne règle tout ça ensemble.                 │
└─────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- 4 blocs colorés (rouge/orange) avec icône + texte court
- Ligne de conclusion en bas, mise en évidence (fond coloré ou encadré)

---

## Speech

> *"Commençons par la problématique.
>
> Quand on observe le quotidien d'un étudiant, on constate quatre problèmes récurrents.
>
> Premier problème : la concentration. Il est très difficile de maintenir un niveau
> de focus élevé pendant plusieurs heures de travail, surtout avec les distractions
> numériques d'aujourd'hui.
>
> Deuxième problème : la posture. Rester assis mal positionné pendant des heures
> entraîne de la fatigue physique et des douleurs qui réduisent encore plus la productivité.
>
> Troisième problème : les révisions. Sans méthode structurée, les étudiants révisent
> de manière inefficace — trop tard, sans priorisation, sans feedback sur leurs lacunes.
>
> Quatrième problème : le sommeil. Un sommeil de mauvaise qualité impacte directement
> la mémorisation et la capacité de concentration le lendemain.
>
> Le vrai problème, c'est qu'il existe des applications pour chacun de ces problèmes séparément,
> mais aucune solution unifiée, physique, et réellement intelligente ne les adresse tous ensemble."*

**Durée : 1 minute**

---
---

# SLIDE 3 — Notre Solution

## Contenu visuel du slide

```
┌─────────────────────────────────────────────────────────┐
│  Smart Focus & Life Assistant                           │
│  ─────────────────────────────────────────────          │
│                                                         │
│  ┌──────────────┐   ┌──────────────┐   ┌─────────────┐ │
│  │  RASPBERRY   │   │   BACKEND    │   │  APP MOBILE │ │
│  │  PI + CAM    │──▶│   FASTAPI    │──▶│   FLUTTER   │ │
│  │              │   │   + IA       │   │             │ │
│  │ Détecte :    │   │ Analyse,     │   │ Affiche,    │ │
│  │ posture,     │   │ planifie,    │   │ guide,      │ │
│  │ fatigue,     │   │ conseille    │   │ notifie     │ │
│  │ focus        │   │              │   │             │ │
│  └──────────────┘   └──────────────┘   └─────────────┘ │
│    [Binôme]              [Kacem]           [Kacem]      │
│                                                         │
│  → Un seul système, une seule expérience utilisateur    │
└─────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- 3 blocs distincts reliés par des flèches
- Couleurs différentes pour chaque couche
- Nom du responsable de chaque bloc en petit sous le bloc

---

## Speech

> *"Notre réponse à cette problématique, c'est Smart Focus & Life Assistant.
>
> Le système est composé de trois couches qui travaillent ensemble.
>
> La première couche, c'est le dispositif physique : un Raspberry Pi avec une caméra,
> que mon binôme a configuré. Ce dispositif regarde l'utilisateur pendant qu'il travaille,
> et il détecte en temps réel sa posture, son niveau de fatigue, et sa concentration.
>
> La deuxième couche, c'est le backend intelligent que j'ai développé.
> Il reçoit les données du Raspberry Pi, les traite, génère un planning personnalisé
> avec l'IA, gère les révisions, le chatbot, le suivi du sommeil.
>
> La troisième couche, c'est l'application mobile Flutter, également de mon côté,
> qui permet à l'utilisateur d'interagir avec tout le système depuis son téléphone.
>
> L'objectif, c'est que l'utilisateur n'ait qu'une seule expérience cohérente,
> sans avoir à jongler entre plusieurs outils."*

**Durée : 1 minute**

---
---

# SLIDE 4 — Architecture Globale

## Contenu visuel du slide

```
┌─────────────────────────────────────────────────────────────┐
│  Architecture Technique                                     │
│  ─────────────────────────────────────────────              │
│                                                             │
│  [Caméra USB]──▶[Raspberry Pi]                             │
│                  pi_client.py                               │
│                  MediaPipe + OpenCV                         │
│                       │ HTTP POST                           │
│                       ▼                                     │
│              [Backend FastAPI]                              │
│         ┌────────────────────────┐                         │
│         │ Auth │ Planning │ RAG  │                         │
│         │ Sleep│ Quiz     │Focus │                         │
│         └────┬───────────────┬──┘                         │
│              │               │                             │
│         [PostgreSQL]    [ChromaDB]   ←→  [Gemini API]      │
│                                                             │
│                       │ HTTPS                              │
│                       ▼                                     │
│              [App Flutter]                                  │
│         Dashboard │ Planning │ Chatbot │ Stats              │
└─────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Diagramme en couches, avec flèches directionnelles
- 4 couleurs distinctes : rouge (hardware), bleu (backend), violet (données), vert (mobile)
- Logos des technologies à côté de chaque bloc

---

## Speech

> *"Voici l'architecture complète du système.
>
> Tout commence avec le Raspberry Pi. Un script Python — qu'on appelle pi_client —
> utilise MediaPipe et OpenCV pour analyser le flux vidéo de la caméra.
> Il envoie ensuite les résultats au backend via des requêtes HTTP POST.
>
> Le backend est une API REST développée avec FastAPI.
> Il expose plusieurs modules : authentification JWT, génération de planning par IA,
> chatbot RAG, suivi du sommeil, quiz et flashcards.
> Il s'appuie sur PostgreSQL pour les données relationnelles,
> ChromaDB pour les vecteurs d'embeddings,
> et Gemini 2.5 Flash pour l'intelligence artificielle.
>
> Enfin, l'application Flutter sur téléphone communique avec le backend via HTTPS.
> Elle affiche les données en temps réel et permet à l'utilisateur de contrôler
> tout le système depuis son téléphone.
>
> Ce qui est important ici, c'est que tout — le backend et le Raspberry Pi —
> tourne sur la même machine physique, ce qui permet un déploiement autonome
> sans dépendance à un serveur cloud."*

**Durée : 1 minute 15 secondes**

---
---

# SLIDES 5, 6, 7 — PARTIE BINÔME

> *(Ces trois slides sont présentés par ton binôme. Le contenu est fourni à titre indicatif.)*

---

# SLIDE 5 — Hardware : Le Dispositif Physique (Binôme)

## Contenu visuel du slide

```
┌──────────────────────────────────────────────────────────┐
│  Le Dispositif Physique                                  │
│  ────────────────────────────────────────────            │
│                                                          │
│  [PHOTO DU BOÎTIER PHYSIQUE]    [SCHÉMA DES COMPOSANTS] │
│                                                          │
│  Composants :                                            │
│  • Raspberry Pi 5               Rôle : cerveau du système│
│  • Caméra USB                   Rôle : capture vidéo     │
│  • LEDs RGB WS2812B             Rôle : feedback visuel   │
│  • Écran TFT 2.4"               Rôle : affichage score   │
│  • Boîtier imprimé en 3D        Matériau : PLA           │
│  • Alimentation USB-C 5V                                 │
│                                                          │
│  Dimensions : H 25–30 cm                                 │
└──────────────────────────────────────────────────────────┘
```

---

## Speech (Binôme)

> *"Ma partie concerne le dispositif physique qui observe l'utilisateur.
>
> Le boîtier contient un Raspberry Pi 5 qui joue le rôle de cerveau,
> une caméra USB braquée vers l'utilisateur, un anneau de LEDs RGB
> qui donne un retour visuel coloré selon l'état de concentration,
> et un petit écran TFT qui affiche le score de focus.
>
> Tout est intégré dans un boîtier que j'ai conçu et imprimé en 3D."*

---
---

# SLIDE 6 — ML Vision : Les Modèles de Détection (Binôme)

## Contenu visuel du slide

```
┌───────────────────────────────────────────────────────────┐
│  Vision par Ordinateur : 3 modèles                        │
│  ──────────────────────────────────────────               │
│                                                           │
│  [IMAGE CAMÉRA]                                           │
│       │                                                   │
│       ├──▶ MediaPipe Pose   →  posture_ok / angle_tête    │
│       ├──▶ Face Mesh + CNN  →  fatigue_level / EAR / MAR  │
│       └──▶ Face Detection   →  face_detected / regard     │
│                                                           │
│  ┌───────────────┐ ┌─────────────────┐ ┌──────────────┐  │
│  │   POSTURE     │ │    FATIGUE      │ │   PRÉSENCE   │  │
│  │ Dos courbé ?  │ │ Yeux fermés ?   │ │ Utilisateur  │  │
│  │ Tête basse ?  │ │ Bâillements ?   │ │ présent et   │  │
│  │               │ │ Clignements ?   │ │ concentré ?  │  │
│  └───────────────┘ └─────────────────┘ └──────────────┘  │
│                                                           │
│  Latence < 500ms par analyse                              │
└───────────────────────────────────────────────────────────┘
```

---

## Speech (Binôme)

> *"Le script pi_client.py exploite trois modèles de détection basés sur MediaPipe.
>
> Le premier détecte la posture : il analyse la position des épaules et de la tête
> pour identifier si l'utilisateur est bien assis ou en train de se courber.
>
> Le deuxième détecte la fatigue : il mesure le ratio d'aspect des yeux — ce qu'on
> appelle l'EAR — et détecte les bâillements via le ratio d'ouverture de la bouche.
>
> Le troisième vérifie que l'utilisateur est bien présent et qu'il regarde l'écran.
>
> Tout cela est analysé en moins de 500 millisecondes, ce qui permet un retour
> quasi instantané."*

---
---

# SLIDE 7 — Calcul du Score de Focus (Binôme)

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Score de Focus — Comment ça marche ?                      │
│  ──────────────────────────────────────────                │
│                                                            │
│  posture_ok  +  fatigue_level  +  face_detected            │
│       +  mouvement_détecté                                 │
│                │                                           │
│                ▼                                           │
│         Score Focus (0 → 100)                              │
│                │                                           │
│    ┌───────────┼──────────────┐                           │
│    ▼           ▼              ▼                            │
│  🟢 80–100   🟠 50–79       🔴 0–49                       │
│  LED Verte   LED Orange     LED Rouge                      │
│  "Focus!"    "Distrait"     "Fatigue!"                     │
│                                                            │
│   → Envoyé au backend toutes les secondes via HTTP POST    │
└────────────────────────────────────────────────────────────┘
```

---

## Speech (Binôme)

> *"Tous ces signaux sont combinés dans une formule de score de focus,
> qui produit un nombre entre 0 et 100.
>
> Ce score alimente en temps réel les LEDs du boîtier :
> vert si l'utilisateur est concentré, orange si on détecte une distraction,
> rouge si on détecte de la fatigue ou une absence.
>
> Ce même score est envoyé chaque seconde au backend via une requête HTTP,
> où Kacem le traite pour mettre à jour l'application mobile et adapter le planning."*

---
---
---

# TA PARTIE — Backend, IA & Application Mobile

---
---

# SLIDE 8 — Stack Technique

## Contenu visuel du slide

```
┌──────────────────────────────────────────────────────────┐
│  Stack Technique — Mon Périmètre                         │
│  ──────────────────────────────────────────              │
│                                                          │
│   BACKEND                     MOBILE                    │
│   ─────────────────            ─────────────────         │
│   🐍 Python 3.11               🎯 Flutter 3.x (Dart)    │
│   ⚡ FastAPI 0.115              📦 Riverpod 3.2          │
│   🗄️ PostgreSQL + Alembic       🧭 GoRouter 17.1        │
│   🔗 LangChain 0.3              🌐 Dio 5.9              │
│   🧠 Gemini 2.5 Flash           📊 fl_chart 1.1         │
│   📁 ChromaDB 0.5               💾 Hive 2.2             │
│   🔐 JWT (python-jose)          🔔 flutter_local_notif  │
│                                                          │
│   28 endpoints REST                                      │
│   13 tables PostgreSQL                                   │
│   ~23 000 lignes de code total                          │
└──────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Deux colonnes bien séparées avec icônes technologies
- Chiffres clés en bas, mis en évidence

---

## Speech

> *"Je vais maintenant vous présenter ma partie du projet.
>
> Du côté backend, j'ai utilisé FastAPI avec Python pour construire l'API REST,
> PostgreSQL comme base de données principale avec Alembic pour les migrations,
> LangChain et ChromaDB pour la partie RAG — c'est-à-dire le chatbot intelligent —
> et Gemini 2.5 Flash de Google comme modèle de langage pour l'IA.
>
> Du côté mobile, l'application est développée en Flutter avec Dart.
> J'utilise Riverpod pour la gestion d'état, GoRouter pour la navigation centralisée,
> et Dio pour les appels HTTP vers le backend.
>
> Au total, le projet compte 28 endpoints API actifs, 13 tables en base de données,
> et environ 23 000 lignes de code entre le backend et l'application mobile."*

**Durée : 1 minute**

---
---

# SLIDE 9 — Authentification & Profil Utilisateur

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Authentification                                          │
│  ──────────────────────────────────────────               │
│                                                            │
│  [SCREENSHOT : Écran Login]  [SCREENSHOT : Écran Register] │
│                                                            │
│  Backend :                                                 │
│  POST /auth/register  → hash bcrypt + création compte      │
│  POST /auth/login     → Access Token + Refresh Token JWT   │
│  GET  /auth/me        → profil utilisateur courant         │
│  PUT  /auth/me/profile → mise à jour préférences           │
│                                                            │
│  Profil stocké :                                           │
│  • Objectif focus (heures/jour)                            │
│  • Horaires préférés (matin / après-midi / soir)           │
│  • Préférences de notification                             │
│  • Emploi du temps hebdomadaire                            │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Screenshots de l'app à gauche
- Liste des endpoints et données à droite

---

## Speech

> *"La première brique du backend, c'est l'authentification.
>
> L'utilisateur peut créer un compte et se connecter.
> Les mots de passe sont hachés avec bcrypt, et l'authentification
> repose sur des tokens JWT — un access token de courte durée
> et un refresh token pour le renouvellement automatique.
>
> Ce qui est intéressant, c'est le profil utilisateur.
> Lors de la création du compte, on demande à l'utilisateur
> ses objectifs de focus quotidien, ses horaires préférés de travail —
> est-ce qu'il est plutôt du matin ou du soir —
> et ses préférences de notification.
>
> Ces informations ne sont pas cosmétiques. Elles sont utilisées directement
> par le module de planning pour personnaliser les sessions de travail générées."*

**Durée : 50 secondes**

---
---

# SLIDE 10 — Chatbot RAG

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Chatbot RAG — Révisions Intelligentes                     │
│  ──────────────────────────────────────────               │
│                                                            │
│  Pipeline :                                                │
│                                                            │
│  [📄 PDF / CSV]                                            │
│       │                                                    │
│       ▼                                                    │
│  Découpage en chunks (overlap)                             │
│       │                                                    │
│       ▼                                                    │
│  Embeddings Gemini text-embedding-004                      │
│       │                                                    │
│       ▼                                                    │
│  Stockage ChromaDB                                         │
│       │                                                    │
│       ▼                                                    │
│  Question utilisateur → Recherche sémantique → Réponse IA  │
│                                                            │
│  [SCREENSHOT : Interface Chatbot de l'app]                 │
│                                                            │
│  ✅ PDF de cours     ✅ CSV emploi du temps                 │
│  ✅ Multi-documents  ✅ Mode sans document (IA directe)     │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Pipeline vertical à gauche avec flèches
- Screenshot du chatbot à droite
- Checklist des capacités en bas

---

## Speech

> *"Le deuxième module majeur, c'est le chatbot RAG — Retrieval-Augmented Generation.
>
> L'idée est simple : l'étudiant uploade ses PDF de cours dans l'application.
> Le système les découpe en petits morceaux de texte, génère des vecteurs
> d'embeddings avec Gemini, et les stocke dans ChromaDB, une base de données vectorielle.
>
> Quand l'étudiant pose une question, le système fait une recherche sémantique
> dans ses documents, récupère les passages les plus pertinents,
> et Gemini génère une réponse contextualisée.
>
> Ce n'est pas un simple chatbot qui répond de manière générique.
> Il répond basé sur le contenu réel des cours de l'étudiant.
>
> Et si l'étudiant n'a pas de document chargé, le chatbot bascule
> en mode conversation générale directement avec Gemini.
>
> On supporte aussi l'upload de CSV d'emploi du temps, avec validation
> automatique des colonnes, ce qui permet au planning IA de connaître
> l'agenda de l'étudiant."*

**Durée : 1 minute 10 secondes**

---
---

# SLIDE 11 — Quiz & Flashcards (Algorithme SM-2)

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Quiz & Flashcards — Apprendre mieux                       │
│  ──────────────────────────────────────────               │
│                                                            │
│   QUIZ                           FLASHCARDS               │
│   ───────────────────            ─────────────────         │
│   Généré par Gemini              Algorithme SM-2           │
│   depuis PDF                     (répétition espacée)      │
│                                                            │
│   → QCM 4 choix                  ease_factor              │
│   → Corrections                  interval                  │
│     expliquées                   next_review_date          │
│   → Score                                                  │
│   → Multi-documents              Cartes dues               │
│                                  aujourd'hui ?             │
│                                  → Insérées dans           │
│   [SCREENSHOT Quiz]              le planning !             │
│                                  [SCREENSHOT Flashcards]   │
│                                                            │
│  Ajoutés automatiquement à chaque session terminée ✅      │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Deux colonnes Quiz / Flashcards
- Screenshots en bas de chaque colonne
- Ligne de conclusion centrée en bas

---

## Speech

> *"Pour renforcer l'apprentissage, j'ai intégré deux modules : les quiz et les flashcards.
>
> Pour les quiz : l'étudiant sélectionne un ou plusieurs documents,
> et Gemini génère automatiquement des QCM avec quatre choix.
> Quand il soumet ses réponses, il reçoit son score et les corrections
> avec explications pour chaque question ratée.
>
> Pour les flashcards, j'ai implémenté l'algorithme SM-2 —
> c'est l'algorithme de répétition espacée utilisé par Anki.
> Chaque carte a un facteur de facilité et un intervalle calculés dynamiquement.
> Si l'étudiant a du mal avec une carte, elle revient plus souvent.
> Si elle est bien maîtrisée, l'intervalle s'allonge.
>
> Ce qui est intéressant, c'est l'intégration avec le planning :
> quand des flashcards sont dues pour révision ce jour-là,
> le planning IA les insère automatiquement dans les sessions de la journée.
> Tout le système est connecté."*

**Durée : 1 minute 10 secondes**

---
---

# SLIDE 12 — Planning Intelligent (Module Central)

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Planning IA Adaptatif — Le Module Central                 │
│  ──────────────────────────────────────────               │
│  1701 lignes de code | Gemini 2.5 Flash                   │
│                                                            │
│  GÉNÉRATION                    ADAPTATION                  │
│  ─────────────────             ──────────────              │
│  POST /generate                                            │
│  → 1 jour                      Sommeil ≥ 80 → 50 min/session│
│  POST /generate/week           Sommeil < 50 → 25 min × 2  │
│  → 7 jours en 1 appel          Examen dans ≤ 2j → max     │
│                                Quiz faible → priorité ↑   │
│  Respecte :                    Session manquée → reschedule│
│  • Emploi du temps CSV/PDF                                 │
│  • Blocs fixes (cours)         INTELLIGENCE               │
│  • Buffer 15 min               ──────────────              │
│                                Rotation équilibrée matières│
│  [SCREENSHOT Planning App]     Corrélation sommeil/prod.   │
│                                Révisions examens par urgence│
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Titre avec chiffres clés mis en évidence (1701 lignes)
- Deux colonnes : Génération / Adaptation
- Screenshot de l'écran planning à gauche

---

## Speech

> *"Le module le plus avancé du projet, c'est le planning intelligent.
> Le routeur seul fait 1701 lignes de code.
>
> Voici comment ça marche.
>
> L'étudiant demande à générer son planning pour aujourd'hui ou pour la semaine.
> Gemini 2.5 Flash analyse le profil, les documents disponibles,
> l'emploi du temps CSV s'il existe, et génère un planning structuré.
> Il respecte les créneaux de cours existants, ajoute des buffers de 15 minutes
> entre les sessions, et équilibre les matières.
>
> Mais ce qui rend ce planning vraiment intelligent, c'est son côté adaptatif.
>
> Si l'étudiant a mal dormi — score sommeil inférieur à 50 —
> le planning génère des sessions plus courtes de 25 minutes au lieu de 50.
> Si un examen est dans deux jours, l'intensité de révision passe au maximum.
> Si l'étudiant est en difficulté sur un sujet de quiz, ce sujet remonte en priorité.
> Et si une session est manquée, le système la replanifie automatiquement
> sur le jour même ou le lendemain.
>
> C'est un planning qui apprend du comportement de l'utilisateur et s'adapte continuellement."*

**Durée : 1 minute 30 secondes**

---
---

# SLIDE 13 — Sleep Tracking & Alarme Intelligente

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Suivi du Sommeil                                          │
│  ──────────────────────────────────────────               │
│                                                            │
│  [SCREENSHOT : Écran sommeil de l'app]                     │
│                                                            │
│  L'utilisateur enregistre sa nuit :                        │
│  heure de coucher, heure de lever, qualité perçue          │
│                                                            │
│  → sleep_score calculé automatiquement (0–100)             │
│                                                            │
│  Statistiques : semaine | mois                             │
│                                                            │
│  Alarme intelligente :                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐         │
│  │ Gradual  │  │  Normal  │  │     Silent       │         │
│  │ Réveil   │  │ Standard │  │ Vibrations seul. │         │
│  │ progressif│  │          │  │                  │         │
│  └──────────┘  └──────────┘  └──────────────────┘         │
│                                                            │
│  ⚡ Impact direct sur le planning du lendemain             │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Screenshot de l'interface sommeil
- 3 modes d'alarme visualisés
- Ligne d'impact sur le planning mise en évidence

---

## Speech

> *"Le module sommeil est une pièce clé du système, parce qu'il influence directement le planning.
>
> Chaque soir, l'utilisateur enregistre sa nuit : l'heure à laquelle il s'est couché,
> l'heure de réveil, et sa perception subjective de la qualité du sommeil.
> Le système calcule automatiquement un score de sommeil sur 100
> basé sur la durée, la régularité et la qualité déclarée.
>
> L'application permet aussi de configurer une alarme intelligente
> avec trois modes : réveil progressif — l'alarme monte graduellement en volume —,
> réveil normal, ou mode silencieux pour les nuits difficiles.
>
> Et comme je le disais pour le planning :
> si le score de sommeil est mauvais, le lendemain matin le planning
> adapte automatiquement la durée des sessions.
> C'est cette connexion entre les modules qui rend le système cohérent."*

**Durée : 1 minute**

---
---

# SLIDE 14 — Dashboard Temps Réel

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Dashboard — Vue Temps Réel                                │
│  ──────────────────────────────────────────               │
│                                                            │
│  [SCREENSHOT : Dashboard de l'app Flutter]                 │
│                                                            │
│  Ce que l'utilisateur voit :                               │
│                                                            │
│  🎯  Score de focus live                                   │
│      (envoyé par le Raspberry Pi chaque seconde)           │
│                                                            │
│  📊  Graphiques fl_chart                                   │
│      → Courbe score de focus sur la session                │
│      → Barres performance hebdomadaire                     │
│                                                            │
│  💡  Insights personnalisés                                │
│      → "Vos heures productives : 9h–11h"                  │
│      → "Vous avez raté 2 sessions cette semaine"           │
│                                                            │
│  ⚠️  La détection démarre UNIQUEMENT                       │
│      quand une session est démarrée                        │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Grand screenshot du dashboard centré
- Liste des éléments visibles à droite
- Note technique en bas sur le démarrage conditionnel

---

## Speech

> *"Le dashboard est la première chose que voit l'utilisateur quand il ouvre l'application.
>
> Au centre, le score de focus en temps réel — c'est la valeur calculée par le Raspberry Pi
> et envoyée chaque seconde au backend, qui la transmet ensuite à l'application.
>
> En dessous, des graphiques fl_chart : une courbe du score de focus
> pendant la session en cours, et des graphiques de performance hebdomadaire
> pour voir l'évolution dans le temps.
>
> Il y a aussi des insights générés par le système :
> par exemple les heures de la journée où l'utilisateur est historiquement
> le plus concentré, ou des alertes si plusieurs sessions ont été manquées.
>
> Un point technique important : le système de détection ne s'active pas
> en permanence. Il démarre uniquement quand l'utilisateur lance
> explicitement une session de travail. Cela évite les faux positifs
> et les données parasites."*

**Durée : 1 minute**

---
---

# SLIDE 15 — Déploiement sur Raspberry Pi 5

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Déploiement Autonome — Raspberry Pi 5                     │
│  ──────────────────────────────────────────               │
│                                                            │
│                  [PHOTO Raspberry Pi 5]                    │
│                                                            │
│  Raspberry Pi 5 (ARM64 – Ubuntu Server)                    │
│  ┌──────────────────────────────────────┐                  │
│  │  pi_client.py   (caméra + ML)        │                  │
│  │  backend/       (FastAPI + PostgreSQL)│                  │
│  │  chromadb/      (base vectorielle)   │                  │
│  └──────────────────────────────────────┘                  │
│                    │                                       │
│              WiFi réseau local                             │
│                    │                                       │
│          [App Flutter sur téléphone]                       │
│                                                            │
│  ✅ Démarrage automatique au boot (systemd)                │
│  ✅ Script deploy_pi.sh (installation en 1 commande)       │
│  ✅ Compatibilité ARM64 validée (LangChain, ChromaDB)      │
│  ✅ Aucune dépendance à un serveur cloud                   │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Photo du Raspberry Pi 5
- Schéma de l'arborescence sur le Pi
- Checklist des avantages en bas

---

## Speech

> *"Un aspect important du projet, c'est le déploiement.
>
> Tout le système — le backend FastAPI, la base de données PostgreSQL,
> ChromaDB pour les vecteurs, et le script de détection MediaPipe —
> tourne sur un seul Raspberry Pi 5.
>
> J'ai développé un script deploy_pi.sh qui automatise l'installation complète
> sur le Raspberry en une seule commande.
> Le service backend démarre automatiquement au boot grâce à systemd,
> donc le boîtier est autonome dès qu'on le branche.
>
> Une difficulté technique à souligner ici : plusieurs bibliothèques Python
> comme LangChain et ChromaDB n'ont pas de packages précompilés pour ARM64.
> J'ai dû résoudre des problèmes de compatibilité, notamment en supprimant
> un pin de version de LangSmith qui était incompatible avec l'architecture ARM.
>
> Le résultat, c'est un système entièrement autonome, sans dépendance cloud,
> qui tourne sur du matériel accessible à moins de 100 euros."*

**Durée : 1 minute 10 secondes**

---
---

# SLIDE 16 — Démonstration Live

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Démonstration                                             │
│  ──────────────────────────────────────────               │
│                                                            │
│  Scénario en 5 étapes :                                    │
│                                                            │
│  1️⃣  Connexion                                            │
│      Login → Dashboard s'affiche                           │
│                                                            │
│  2️⃣  Générer un planning                                   │
│      Import CSV emploi du temps → Planning IA généré       │
│                                                            │
│  3️⃣  Démarrer une session                                  │
│      Détection Raspberry s'active → Score live sur Dashboard│
│                                                            │
│  4️⃣  Chatbot RAG                                           │
│      Upload PDF cours → Question → Réponse contextualisée  │
│                                                            │
│  5️⃣  Quiz                                                  │
│      Générer quiz depuis PDF → Soumettre → Score + corrections│
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Fond simple, texte clair
- 5 étapes numérotées avec description courte
- Slide épuré pour ne pas distraire pendant la démo live

---

## Speech

> *"On va maintenant vous faire une démonstration live du système.
>
> On va suivre le parcours d'un étudiant qui utilise Smart Focus pour la première fois aujourd'hui.
>
> Première étape : il se connecte à l'application.
> [Montrer l'écran Login → Dashboard]
>
> Deuxième étape : il génère son planning pour aujourd'hui.
> Il a déjà uploadé son emploi du temps en CSV.
> On clique sur 'Générer' et Gemini produit un planning personnalisé pour la journée.
> [Montrer la génération du planning]
>
> Troisième étape : il démarre une session de travail.
> Dès qu'il clique sur 'Démarrer', le Raspberry Pi active la détection.
> Le score de focus s'affiche en temps réel sur le dashboard.
> [Montrer le score live]
>
> Quatrième étape : il veut poser une question sur son cours.
> Il upload son PDF de cours, pose une question,
> et le chatbot répond basé sur le contenu exact du document.
> [Montrer le chatbot RAG]
>
> Cinquième étape : il génère un quiz depuis ce même PDF.
> Il répond aux questions et reçoit son score avec les corrections.
> [Montrer le quiz]"*

**Durée : 2 minutes (variable selon la démo)**

---
---

# SLIDE 17 — Résultats & Bilan

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Bilan du Projet                                           │
│  ──────────────────────────────────────────               │
│                                                            │
│   PARTIE BINÔME                 PARTIE KACEM               │
│   ─────────────────             ─────────────────          │
│   ✅ Raspberry Pi configuré     ✅ 28 endpoints API REST    │
│   ✅ MediaPipe : posture         ✅ Chatbot RAG opérationnel│
│      + fatigue + présence       ✅ Planning IA (1701 lignes)│
│   ✅ Score de focus calculé     ✅ Quiz + Flashcards SM-2   │
│   ✅ Boîtier 3D imprimé         ✅ Sleep Tracking complet   │
│   ✅ Feedback LED temps réel    ✅ App validée téléphone réel│
│                                 ✅ Déployé sur Raspberry Pi5│
│                                                            │
│   ──────────────────────────────────────────              │
│   📊  Chiffres clés                                        │
│   ~23 000 lignes de code   |   13 tables PostgreSQL        │
│   6 modules fonctionnels   |   17 semaines de développement│
│                                                            │
│             Progression globale : ~88%                     │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Deux colonnes symétriques avec checkmarks verts
- Barre de progression en bas (style jauge)
- Chiffres clés en bas encadrés

---

## Speech

> *"Voici le bilan de ce que nous avons livré.
>
> Du côté hardware, mon binôme a configuré le Raspberry Pi avec les modèles
> MediaPipe pour la détection posture, fatigue et présence.
> Le score de focus est calculé et envoyé en temps réel,
> et le boîtier 3D intègre tous les composants avec le feedback LED.
>
> Du côté logiciel, j'ai livré 28 endpoints REST actifs,
> un chatbot RAG fonctionnel basé sur Gemini et ChromaDB,
> un module de planning IA adaptatif de 1701 lignes,
> des quiz et flashcards avec l'algorithme SM-2,
> le suivi du sommeil avec impact sur le planning,
> et tout ça a été validé sur un téléphone Android physique
> et déployé sur le Raspberry Pi 5.
>
> Au total, 23 000 lignes de code, 17 semaines de développement,
> et une progression globale d'environ 88% des fonctionnalités prévues.
>
> Les 12% restants concernent principalement les tests unitaires automatisés
> et l'écran d'onboarding, qui sont prévus en phase de finition."*

**Durée : 1 minute 10 secondes**

---
---

# SLIDE 18 — Perspectives & Conclusion

## Contenu visuel du slide

```
┌────────────────────────────────────────────────────────────┐
│  Perspectives & Conclusion                                 │
│  ──────────────────────────────────────────               │
│                                                            │
│  Ce qui reste :                                            │
│  ○ Tests unitaires automatisés (pytest + widget tests)     │
│  ○ Déploiement Docker (portabilité maximale)               │
│  ○ Écran Onboarding (premier lancement guidé)              │
│                                                            │
│  ──────────────────────────────────────────               │
│                                                            │
│  Ce projet démontre que :                                  │
│                                                            │
│  🤖  L'IA générative (Gemini) peut personnaliser           │
│      réellement l'expérience d'apprentissage               │
│                                                            │
│  👁️  La vision par ordinateur (MediaPipe) est accessible   │
│      sur du matériel embarqué low-cost                     │
│                                                            │
│  📱  Flutter permet de livrer une app complète             │
│      connectée à un système IA en quelques mois            │
│                                                            │
│  ──────────────────────────────────────────               │
│          Merci de votre attention — Questions ?            │
└────────────────────────────────────────────────────────────┘
```

**Éléments visuels :**
- Section "Ce qui reste" épurée
- 3 conclusions clés avec icônes
- Ligne finale "Merci" bien visible, sobre

---

## Speech

> *"Pour terminer, quelques perspectives.
>
> Il reste à finaliser les tests unitaires automatisés côté backend et Flutter,
> à containeriser le système avec Docker pour faciliter le déploiement,
> et à développer un écran d'onboarding pour guider les nouveaux utilisateurs.
>
> Mais au-delà du projet lui-même, ce travail démontre trois choses importantes.
>
> Premièrement : l'IA générative, et Gemini en particulier,
> est aujourd'hui suffisamment capable pour personnaliser réellement
> l'expérience d'apprentissage — pas juste répondre à des questions,
> mais adapter dynamiquement un planning en fonction du sommeil,
> de la performance et des examens à venir.
>
> Deuxièmement : la vision par ordinateur avec MediaPipe
> est accessible sur du matériel embarqué à faible coût comme le Raspberry Pi.
> On n'a pas besoin d'un GPU ou d'un serveur cloud pour faire de l'analyse
> posture et fatigue en temps réel.
>
> Troisièmement : Flutter permet de livrer une application mobile complète,
> connectée à un système IA complexe, en quelques mois de développement.
>
> Smart Focus & Life Assistant est un assistant qui observe, apprend et s'adapte.
> Nous sommes convaincus que ce type de solution a un vrai potentiel
> pour améliorer la productivité et le bien-être des étudiants.
>
> Merci pour votre attention. Nous sommes disponibles pour vos questions."*

**Durée : 1 minute 30 secondes**

---
---

# Récapitulatif des durées

| Slide | Présentateur | Contenu | Durée |
|-------|-------------|---------|-------|
| 1 | Les deux | Titre | 30 sec |
| 2 | Binôme | Problématique | 1 min |
| 3 | Binôme | Solution globale | 1 min |
| 4 | Les deux | Architecture | 1 min 15 |
| 5 | Binôme | Hardware | 1 min |
| 6 | Binôme | ML Vision | 1 min |
| 7 | Binôme | Score de focus | 45 sec |
| 8 | **Kacem** | Stack technique | 1 min |
| 9 | **Kacem** | Authentification | 50 sec |
| 10 | **Kacem** | Chatbot RAG | 1 min 10 |
| 11 | **Kacem** | Quiz & Flashcards | 1 min 10 |
| 12 | **Kacem** | Planning IA | 1 min 30 |
| 13 | **Kacem** | Sleep Tracking | 1 min |
| 14 | **Kacem** | Dashboard | 1 min |
| 15 | **Kacem** | Déploiement Pi | 1 min 10 |
| 16 | Les deux | Démo live | 2 min |
| 17 | Les deux | Bilan | 1 min 10 |
| 18 | Les deux | Conclusion | 1 min 30 |
| **TOTAL** | | | **~20 min + démo** |

---

# Conseils finaux

**Transitions entre toi et ton binôme :**
- Après le slide 7, dire : *"Je laisse maintenant la parole à Kacem pour la partie logicielle."*
- Toi, commencer le slide 8 par : *"Merci [Prénom]. Je vais maintenant vous présenter le backend, l'IA et l'application mobile."*

**Pendant la démo :**
- Avoir le téléphone chargé et l'app lancée en avance
- Avoir le Raspberry Pi démarré avec le backend prêt
- Préparer un PDF de cours en avance pour l'upload chatbot
- Avoir un CSV d'emploi du temps prêt pour la génération du planning

**En cas de question technique difficile :**
- Sur le RAG : *"Le système récupère les k passages les plus proches sémantiquement de la question, puis Gemini les utilise comme contexte pour générer la réponse."*
- Sur le planning : *"Le LLM ne génère pas le planning librement — il reçoit un contexte structuré avec les créneaux libres calculés côté Python, et ne fait que choisir le contenu des sessions."*
- Sur MediaPipe : *"MediaPipe est une bibliothèque Google open source. Elle tourne localement sur le Raspberry Pi, sans envoyer de données vidéo vers le cloud."*
