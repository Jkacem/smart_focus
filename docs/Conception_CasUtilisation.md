# 📐 Diagrammes de Cas d'Utilisation – Smart Focus & Life Assistant

**Version** : 1.0  
**Date** : 17 Février 2026  
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
        API_EXT["☁️ API OpenAI"]
    end
```

| Acteur | Type | Description |
|--------|------|-------------|
| **Utilisateur** | Principal | Étudiant, professionnel ou enseignant qui interagit avec l'application mobile |
| **Boîtier ESP32** | Secondaire | Dispositif IoT qui capture les données physiques (caméra, capteurs) |
| **Service ML** | Secondaire | Module serveur d'analyse d'images (posture, fatigue, visage) |
| **Système IA** | Secondaire | Module RAG/LLM pour le chatbot et le planning intelligent |
| **API OpenAI** | Externe | Service cloud pour la génération de texte (GPT-3.5/4) |

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
        UC9["Générer un planning intelligent"]
        UC10["Modifier une session planifiée"]
        UC11["Supprimer une session planifiée"]
    end

    %% CU Chatbot
    subgraph CHATBOT ["💬 Chatbot RAG"]
        UC12["Uploader un document PDF"]
        UC13["Poser une question sur les cours"]
        UC14["Générer un quiz"]
        UC15["Créer des flashcards"]
        UC16["Planifier les révisions"]
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
        UC23["Configurer le réveil intelligent"]
        UC24["Adapter le planning selon le sommeil"]
    end

    %% CU Stress
    subgraph STRESS ["🧘 Gestion du Stress"]
        UC25["Lancer un exercice de respiration"]
        UC26["Recevoir des suggestions de micro-pauses"]
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
    User --> UC4
    User --> UC5
    User --> UC7
    User --> UC8
    User --> UC9
    User --> UC10
    User --> UC11
    User --> UC12
    User --> UC13
    User --> UC14
    User --> UC15
    User --> UC16
    User --> UC17
    User --> UC19
    User --> UC21
    User --> UC22
    User --> UC23
    User --> UC25
    User --> UC27
    User --> UC28

    %% Relations ESP32
    ESP32 --> UC6
    ESP32 --> UC17
    ESP32 --> UC18
    ESP32 --> UC21

    %% Relations IA
    IA --> UC9
    IA --> UC13
    IA --> UC14
    IA --> UC15
    IA --> UC16
    IA --> UC20
    IA --> UC24
    IA --> UC29

    %% Relations ML
    ML --> UC5
    ML --> UC6
    ML --> UC17
    ML --> UC18
    ML --> UC26
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
    UC3a["Modifier les informations"]
    UC3b["Définir les objectifs"]
    UC3c["Configurer les notifications"]

    User --> UC1
    User --> UC2
    User --> UC3

    UC3 -.->|include| UC3a
    UC3 -.->|include| UC3b
    UC3 -.->|include| UC3c

    UC2 -.->|extend| UC1
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC1 | S'inscrire | Utilisateur | Aucun compte existant | 1. Saisir email, mot de passe, nom<br/>2. Valider<br/>3. Compte créé | Compte actif, JWT généré |
| UC2 | Se connecter | Utilisateur | Compte existant | 1. Saisir email/mot de passe<br/>2. Authentification<br/>3. Token JWT retourné | Session active |
| UC3 | Gérer le profil | Utilisateur | Connecté | 1. Accéder aux paramètres<br/>2. Modifier infos/objectifs<br/>3. Sauvegarder | Profil mis à jour |

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

---

### 3.3 📅 Module Planning Intelligent

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA / LLM"))

    UC8["Consulter le planning"]
    UC9["Générer un planning IA"]
    UC10["Modifier une session"]
    UC11["Supprimer une session"]

    UC9a["Analyser données utilisateur"]
    UC9b["Optimiser les créneaux"]
    UC9c["Adapter selon le sommeil"]

    User --> UC8
    User --> UC9
    User --> UC10
    User --> UC11

    IA --> UC9a
    IA --> UC9b

    UC9 -.->|include| UC9a
    UC9 -.->|include| UC9b
    UC9 -.->|extend| UC9c
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC8 | Consulter le planning | Utilisateur | Connecté | 1. Ouvrir l'écran Planning<br/>2. Voir sessions du jour<br/>3. Naviguer par date | Planning affiché |
| UC9 | Générer planning IA | Utilisateur, IA | Connecté, données disponibles | 1. Cliquer "Générer"<br/>2. IA analyse patterns<br/>3. Créneaux optimisés proposés<br/>4. Utilisateur valide | Planning créé |
| UC10 | Modifier une session | Utilisateur | Session existante | 1. Sélectionner session<br/>2. Modifier horaire/sujet<br/>3. Sauvegarder | Session modifiée |
| UC11 | Supprimer une session | Utilisateur | Session existante | 1. Sélectionner session<br/>2. Confirmer suppression | Session supprimée |

---

### 3.4 💬 Module Chatbot RAG

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA / LLM"))
    API(("☁️ OpenAI"))

    UC12["Uploader un PDF"]
    UC13["Poser une question"]
    UC14["Générer un quiz"]
    UC15["Créer des flashcards"]
    UC16["Planifier les révisions"]

    UC12a["Parser le document"]
    UC12b["Découper en chunks"]
    UC12c["Générer les embeddings"]
    UC13a["Recherche sémantique"]
    UC13b["Génération de réponse LLM"]

    User --> UC12
    User --> UC13
    User --> UC14
    User --> UC15
    User --> UC16

    UC12 -.->|include| UC12a
    UC12 -.->|include| UC12b
    UC12 -.->|include| UC12c

    UC13 -.->|include| UC13a
    UC13 -.->|include| UC13b

    IA --> UC13a
    IA --> UC14
    IA --> UC15
    API --> UC13b
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC12 | Uploader un PDF | Utilisateur, IA | Connecté | 1. Sélectionner fichier PDF<br/>2. Upload vers serveur<br/>3. Parsing + chunking<br/>4. Embeddings générés<br/>5. Stockage dans ChromaDB | Document indexé |
| UC13 | Poser une question | Utilisateur, IA, OpenAI | Document(s) uploadé(s) | 1. Taper la question<br/>2. Recherche sémantique<br/>3. Chunks pertinents trouvés<br/>4. LLM génère la réponse<br/>5. Réponse affichée avec sources | Réponse affichée |
| UC14 | Générer un quiz | Utilisateur, IA | Document(s) uploadé(s) | 1. Sélectionner sujet/document<br/>2. IA génère questions QCM<br/>3. Quiz interactif affiché | Quiz généré |
| UC15 | Créer des flashcards | Utilisateur, IA | Document(s) uploadé(s) | 1. Sélectionner contenu<br/>2. IA extrait concepts clés<br/>3. Flashcards générées | Flashcards créées |
| UC16 | Planifier révisions | Utilisateur, IA | Documents + deadlines | 1. Définir dates d'examens<br/>2. IA planifie les révisions<br/>3. Sessions espacées créées | Révisions planifiées |

---

### 3.5 🧍 Module Posture & Ergonomie

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

---

### 3.6 🌙 Module Sommeil & Réveil

```mermaid
graph LR
    User(("👤 Utilisateur"))
    ESP32(("📟 ESP32"))
    IA(("🤖 IA"))

    UC21["Enregistrer données sommeil"]
    UC22["Consulter score sommeil"]
    UC23["Configurer réveil intelligent"]
    UC24["Adapter le planning"]

    UC21a["Détecter via capteur pression"]
    UC21b["Analyser via microphone"]
    UC23a["Réveil progressif LED + son"]

    ESP32 --> UC21a
    ESP32 --> UC21b

    User --> UC22
    User --> UC23

    UC21 -.->|include| UC21a
    UC21 -.->|include| UC21b
    UC23 -.->|include| UC23a

    UC22 -.->|extend| UC24
    IA --> UC24
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC21 | Enregistrer sommeil | ESP32 | Boîtier actif la nuit | 1. Capteur pression détecte<br/>2. Micro analyse sons<br/>3. Données envoyées au serveur | Données enregistrées |
| UC22 | Score sommeil | Utilisateur | Données de nuit | 1. Ouvrir dashboard matin<br/>2. Score sommeil affiché<br/>3. Détails (léger/profond) | Score consulté |
| UC23 | Réveil intelligent | Utilisateur, ESP32 | Réveil configuré | 1. Phase de sommeil léger détectée<br/>2. LED progressives<br/>3. Son doux croissant<br/>4. Vibration légère | Utilisateur réveillé |
| UC24 | Adapter planning | IA | Score sommeil disponible | 1. Mauvais score détecté<br/>2. IA ajuste planning<br/>3. Pauses plus fréquentes<br/>4. Sessions plus courtes | Planning adapté |

---

### 3.7 🧘 Module Gestion du Stress

```mermaid
graph LR
    User(("👤 Utilisateur"))
    ML(("🧠 ML Vision"))
    ESP32(("📟 ESP32"))

    UC25["Exercice de respiration"]
    UC26["Suggestions micro-pauses"]

    UC25a["Afficher guide sur écran TFT"]
    UC25b["LED synchronisées"]

    UC26a["Détecter distraction prolongée"]

    User --> UC25
    ML --> UC26a

    UC25 -.->|include| UC25a
    UC25 -.->|include| UC25b
    UC26 -.->|include| UC26a

    ESP32 --> UC25a
    ESP32 --> UC25b
```

| # | Cas d'Utilisation | Acteur(s) | Pré-condition | Scénario Principal | Post-condition |
|---|-------------------|-----------|---------------|---------------------|----------------|
| UC25 | Exercice respiration | Utilisateur, ESP32 | Session active | 1. Cliquer "Respiration" ou auto-déclenché<br/>2. Guide affiché sur TFT<br/>3. LEDs synchronisées<br/>4. 3-5 min d'exercice | Stress réduit |
| UC26 | Micro-pauses | ML, Utilisateur | Distraction détectée | 1. ML détecte distraction > 5min<br/>2. Suggestion de pause<br/>3. Activité courte proposée | Utilisateur reposé |

---

### 3.8 📊 Module Dashboard & Statistiques

```mermaid
graph LR
    User(("👤 Utilisateur"))
    IA(("🤖 IA"))

    UC27["Dashboard global"]
    UC28["Stats hebdomadaires"]
    UC29["Conseils personnalisés"]

    UC27a["Score focus du jour"]
    UC27b["Score posture"]
    UC27c["Score sommeil"]
    UC27d["Prochaine session"]

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
| UC28 | Stats hebdomadaires | Utilisateur | Données collectées | 1. Ouvrir Statistiques<br/>2. Graphiques par semaine<br/>3. Tendances et progrès | Progrès visualisés |
| UC29 | Conseils personnalisés | Utilisateur, IA | Historique suffisant | 1. IA analyse les patterns<br/>2. Détecte heures productives<br/>3. Génère recommandations | Conseils affichés |

---

## 4. Matrice Acteurs / Cas d'Utilisation

| Cas d'Utilisation | 👤 Utilisateur | 📟 ESP32 | 🧠 ML Vision | 🤖 IA/LLM | ☁️ OpenAI |
|-------------------|:-:|:-:|:-:|:-:|:-:|
| S'inscrire | ✅ | | | | |
| Se connecter | ✅ | | | | |
| Gérer profil | ✅ | | | | |
| Démarrer session focus | ✅ | ✅ | ✅ | | |
| Voir score temps réel | ✅ | | ✅ | | |
| Alerte concentration | ✅ | ✅ | ✅ | | |
| Historique sessions | ✅ | | | | |
| Consulter planning | ✅ | | | | |
| Générer planning IA | ✅ | | | ✅ | |
| Modifier session | ✅ | | | | |
| Supprimer session | ✅ | | | | |
| Uploader PDF | ✅ | | | ✅ | |
| Poser question | ✅ | | | ✅ | ✅ |
| Générer quiz | ✅ | | | ✅ | ✅ |
| Créer flashcards | ✅ | | | ✅ | ✅ |
| Planifier révisions | ✅ | | | ✅ | |
| Détecter posture | | ✅ | ✅ | | |
| Alerte posture | ✅ | ✅ | ✅ | | |
| Stats posture | ✅ | | | | |
| Conseils ergonomiques | ✅ | | | ✅ | |
| Enregistrer sommeil | | ✅ | | | |
| Score sommeil | ✅ | | | | |
| Réveil intelligent | ✅ | ✅ | | | |
| Adapter planning/sommeil | | | | ✅ | |
| Exercice respiration | ✅ | ✅ | | | |
| Micro-pauses | ✅ | | ✅ | | |
| Dashboard global | ✅ | | | | |
| Stats hebdomadaires | ✅ | | | | |
| Conseils personnalisés | ✅ | | | ✅ | ✅ |

---

## 5. Résumé des Cas d'Utilisation

| Module | Nombre de CU | Priorité |
|--------|:---:|:---:|
| 🔐 Authentification | 3 | Haute |
| 🎯 Focus & Concentration | 4 | Haute |
| 📅 Planning Intelligent | 4 | Haute |
| 💬 Chatbot RAG | 5 | Haute |
| 🧍 Posture & Ergonomie | 4 | Moyenne |
| 🌙 Sommeil & Réveil | 4 | Moyenne |
| 🧘 Gestion du Stress | 2 | Basse |
| 📊 Dashboard & Stats | 3 | Haute |
| **Total** | **29** | |

---

**Validé par** : _________________________  
**Date de validation** : _________________________
