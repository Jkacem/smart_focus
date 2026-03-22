# 🤖 Diagramme de Flux RAG Chatbot – Smart Focus & Life Assistant

**Version** : 1.0  
**Date** : 01 Mars 2026  
**Phase** : Conception  
**Technologies** : LangChain · ChromaDB · OpenAI GPT-3.5/4 · FastAPI

---

## 1. Vue d'Ensemble du Pipeline RAG

```mermaid
flowchart TD
    subgraph INGEST["📥 Phase 1 – Ingestion (Upload)"]
        UP["📄 Upload Document\n(PDF / PPTX / DOCX)"]
        PARSE["📝 Parsing du fichier\n(PyMuPDF / python-pptx)"]
        CHUNK["✂️ Chunking\n(500 tokens, overlap 50)"]
        EMBED["🔢 Génération Embeddings\n(text-embedding-3-small)"]
        STORE["💾 Stockage\nChromaDB (vecteurs)\n+ PostgreSQL (métadonnées)"]

        UP --> PARSE --> CHUNK --> EMBED --> STORE
    end

    subgraph QUERY["🔍 Phase 2 – Requête (Question)"]
        QUESTION["❓ Question Utilisateur\n(via Flutter Chatbot)"]
        EMBED_Q["🔢 Embedding de la question\n(text-embedding-3-small)"]
        SEARCH["🔎 Recherche Sémantique\n(ChromaDB cosine similarity\nTop-K = 5 chunks)"]
        RERANK["📊 Re-ranking\n(pertinence + diversité)"]
        CONTEXT["📋 Construction du Contexte\n(chunks sélectionnés + historique chat)"]

        QUESTION --> EMBED_Q --> SEARCH --> RERANK --> CONTEXT
    end

    subgraph GENERATE["💬 Phase 3 – Génération"]
        PROMPT["🧩 Construction du Prompt\nSystem + Context + Question"]
        LLM["🤖 LLM (GPT-3.5-turbo)\nGénération de la réponse"]
        SOURCES["📎 Attribution des sources\n(doc + page + chunk)"]
        ANSWER["✅ Réponse finale\n+ sources affichées"]

        PROMPT --> LLM --> SOURCES --> ANSWER
    end

    STORE -.->|"Vecteurs disponibles"| SEARCH
    CONTEXT --> PROMPT

    style INGEST fill:#1a1a2e,stroke:#e94560,color:#fff
    style QUERY fill:#16213e,stroke:#0f3460,color:#fff
    style GENERATE fill:#0f3460,stroke:#533483,color:#fff
```

---

## 2. Flux d'Ingestion (Upload Document)

```mermaid
sequenceDiagram
    participant USER as 👤 Utilisateur
    participant APP as 📱 Flutter App
    participant API as ⚙️ FastAPI
    participant RAG as 🤖 RAGService
    participant OAI as 🌐 OpenAI API
    participant CHROMA as 💾 ChromaDB
    participant PG as 🗄️ PostgreSQL

    USER->>APP: Sélectionner fichier PDF
    APP->>API: POST /chatbot/documents/upload\n(multipart/form-data)
    API->>PG: INSERT INTO documents\n{filename, path, user_id}
    API->>RAG: indexDocument(document_id, file_path)

    RAG->>RAG: 1. Lire et parser le PDF\n(PyMuPDF → texte brut)
    RAG->>RAG: 2. Diviser en chunks\n(RecursiveCharacterTextSplitter\n500 tokens, overlap=50)

    loop Pour chaque chunk
        RAG->>OAI: text-embedding-3-small\n(chunk.content)
        OAI-->>RAG: embedding [1536 floats]
        RAG->>CHROMA: add_documents(chunk + embedding + metadata)
        RAG->>PG: INSERT INTO document_chunks\n{content, chunk_index, chroma_id}
    end

    RAG-->>API: {chunks_count: 47}
    API->>PG: UPDATE documents SET is_indexed=true, num_chunks=47
    API-->>APP: 200 {document_id, chunks_count: 47, status: "indexed"}
    APP->>USER: ✅ "Document indexé (47 chunks)"
```

---

## 3. Flux de Question-Réponse

```mermaid
sequenceDiagram
    participant USER as 👤 Utilisateur
    participant APP as 📱 Flutter App
    participant API as ⚙️ FastAPI
    participant RAG as 🤖 RAGService
    participant OAI as 🌐 OpenAI API
    participant CHROMA as 💾 ChromaDB
    participant PG as 🗄️ PostgreSQL
    participant CACHE as ⚡ Redis Cache

    USER->>APP: "Explique le cycle de Krebs"
    APP->>API: POST /chatbot/ask\n{question, conversation_id, doc_ids?}

    API->>CACHE: get(hash(question + doc_ids))
    alt Cache HIT
        CACHE-->>API: {answer, sources}
        API-->>APP: 200 {answer, sources} (rapide)
    else Cache MISS
        API->>PG: SELECT messages FROM chat_conversations\n(historique récent)
        API->>RAG: query(question, doc_ids, history)

        RAG->>OAI: text-embedding-3-small(question)
        OAI-->>RAG: question_embedding [1536 floats]

        RAG->>CHROMA: similarity_search(\n  query=question_embedding,\n  filter={doc_ids},\n  k=5\n)
        CHROMA-->>RAG: [chunk1, chunk2, chunk3, chunk4, chunk5]

        RAG->>RAG: Re-rank chunks\n(MMR – Max Marginal Relevance)

        RAG->>RAG: Construire le prompt:\n[SYSTEM]: Tu es un assistant pédagogique...\n[CONTEXT]: {chunk1}\n{chunk2}...\n[HISTORY]: {msg1, msg2}\n[QUESTION]: Explique le cycle de Krebs

        RAG->>OAI: ChatCompletion GPT-3.5-turbo\n(prompt complet)
        OAI-->>RAG: "Le cycle de Krebs (ou cycle\nde l'acide citrique)..."

        RAG->>RAG: Extraire sources\n[{doc: "Biochimie_L2.pdf", page: 45}, ...]
        RAG-->>API: {answer, sources, tokens_used}

        API->>PG: INSERT INTO chat_messages\n{question (user), answer (assistant), sources}
        API->>CACHE: set(hash, {answer, sources}, ttl=3600)
        API-->>APP: 200 {answer, sources, conversation_id}
    end

    APP->>USER: Afficher réponse\n+ sources cliquables
```

---

## 4. Flux de Génération de Quiz

```mermaid
flowchart TD
    START["🎯 Utilisateur demande un quiz\nPOST /chatbot/quiz/generate\n{document_id, num_questions: 10}"]

    READ["📖 Lecture du document\n(chunks depuis PostgreSQL)"]
    SAMPLE["🎲 Sélection aléatoire de chunks\n(diversité thématique)"]
    PROMPT_Q["🧩 Prompt de génération\nSystem: Génère 10 QCM en JSON...\nContext: chunks sélectionnés"]
    GEN["🤖 GPT-3.5-turbo\nGénération des questions + options"]
    PARSE_Q["📝 Parsing JSON\n(validation des options, index correct)"]
    SAVE["💾 Sauvegarde\nPostgreSQL: quizzes + quiz_questions"]
    RETURN["✅ Retour à Flutter\n{quiz_id, questions[]}"]

    START --> READ --> SAMPLE --> PROMPT_Q --> GEN --> PARSE_Q --> SAVE --> RETURN

    style START fill:#e94560,color:#fff
    style RETURN fill:#533483,color:#fff
```

---

## 5. Flux Flashcards avec Spaced Repetition (SM-2)

```mermaid
flowchart LR
    subgraph GENERATE_FC["Génération"]
        DOC["📄 Document"]
        LLM_FC["🤖 GPT génère\nRecto / Verso"]
        FC["🗃 Flashcard créée\ndifficulty=3, ease=2.5"]

        DOC --> LLM_FC --> FC
    end

    subgraph REVIEW_CYCLE["Cycle de Révision (SM-2)"]
        DUE["📅 next_review ≤ today\n→ carte affichée"]
        USER_RATE["👤 Utilisateur note\nease: 0=Blackout\n3=Correct\n5=Parfait"]
        UPDATE["🔢 Mise à jour SM-2\nease_factor = f(ease)\ninterval = ease_factor × interval\nnext_review = today + interval"]
        NEXT["📅 Prochaine révision\nplanifiée"]

        DUE --> USER_RATE --> UPDATE --> NEXT
        NEXT -.->|"interval jours"| DUE
    end

    FC --> DUE
    style GENERATE_FC fill:#1a1a2e,stroke:#e94560,color:#fff
    style REVIEW_CYCLE fill:#0f3460,stroke:#533483,color:#fff
```

---

## 6. Architecture LangChain

```mermaid
graph TB
    subgraph LC["LangChain Pipeline"]
        LOADER["DocumentLoader\n(PyMuPDFLoader)"]
        SPLITTER["TextSplitter\n(RecursiveCharacterText\nchunk_size=500\noverlap=50)"]
        EMBEDDINGS["OpenAIEmbeddings\n(text-embedding-3-small\n1536 dims)"]
        VECTORSTORE["ChromaDB\n(VectorStore)"]
        RETRIEVER["Retriever\n(MMR, k=5)"]
        CHAIN["ConversationalRetrievalChain\n(QA avec historique)"]
        LLM_MODEL["ChatOpenAI\n(gpt-3.5-turbo\ntemperature=0.1)"]
    end

    INPUT_DOC["📄 Document"] --> LOADER --> SPLITTER --> EMBEDDINGS --> VECTORSTORE
    INPUT_Q["❓ Question"] --> CHAIN
    RETRIEVER --> CHAIN
    LLM_MODEL --> CHAIN
    VECTORSTORE --> RETRIEVER
    CHAIN --> OUTPUT["💬 Réponse + Sources"]
```

---

## 7. Gestion du Contexte Multi-Documents

```mermaid
flowchart TD
    Q["Question utilisateur"]
    SCOPE{"Portée de\nla recherche?"}
    ALL["🔍 Tous les documents\nde l'utilisateur"]
    SELECT["📑 Documents\nsélectionnés\n(filtrage par doc_ids)"]
    MERGE["Fusion des résultats\n+ déduplication"]
    RANK["Classement par\npertinence (cosine)"]
    WINDOW["Fenêtre de contexte\n~3000 tokens max"]
    LLM_C["GPT génère la réponse\navec sources multiples"]

    Q --> SCOPE
    SCOPE -->|"Aucun filtre"| ALL
    SCOPE -->|"doc_ids fournis"| SELECT
    ALL --> MERGE
    SELECT --> MERGE
    MERGE --> RANK --> WINDOW --> LLM_C
```

---

## 8. Paramètres de Configuration RAG

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| `chunk_size` | 500 tokens | Bon équilibre contexte/précision |
| `chunk_overlap` | 50 tokens | Préserve la cohérence entre chunks |
| `embedding_model` | `text-embedding-3-small` | Coût réduit, qualité suffisante |
| `llm_model` | `gpt-3.5-turbo` | Rapide + économique (fallback GPT-4) |
| `temperature` | `0.1` | Réponses factuelles et stables |
| `top_k_chunks` | `5` | Contexte riche sans overflow |
| `retrieval_strategy` | `MMR` | Diversité maximale des résultats |
| `max_context_tokens` | `3000` | Laisse de la place pour la réponse |
| `cache_ttl` | `3600s` | Cache Redis pour questions fréquentes |
| `conversation_history` | `5 messages` | Contexte conversationnel maintenu |
