"""
RAG Service — Core logic for the SmartFocus chatbot.

Pipeline:
  1. PDF ingestion  → PyMuPDF extracts text per page
  2. Chunking       → LangChain RecursiveCharacterTextSplitter
  3. Embedding      → HuggingFace sentence-transformers (local, free)
  4. Vector Store   → ChromaDB (persisted on disk)
  5. Query          → retrieve top-k chunks → build prompt → Gemini 1.5 Flash
"""

import os
import re
import json
import random
import uuid
import fitz  # PyMuPDF
from pathlib import Path
from typing import List, Dict, Any

from langchain_text_splitters import RecursiveCharacterTextSplitter
import google.generativeai as genai
from langchain_community.vectorstores import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_core.documents import Document
from langchain_core.prompts import PromptTemplate

from app.config import settings


# ── Singleton: reuse embedding model across requests ──────────────────────────
# Uses a local sentence-transformers model (free, no API key needed for embeddings)

_embeddings: HuggingFaceEmbeddings | None = None


def _get_embeddings() -> HuggingFaceEmbeddings:
    global _embeddings
    if _embeddings is None:
        _embeddings = HuggingFaceEmbeddings(
            model_name="all-MiniLM-L6-v2",
            model_kwargs={"device": "cpu"},
            encode_kwargs={"normalize_embeddings": True},
        )
    return _embeddings


# ── Helper: resolve persist directory ─────────────────────────────────────────

def _chroma_path() -> str:
    """Return absolute path to the ChromaDB persistence directory."""
    base = Path(settings.CHROMA_DB_PATH)
    if not base.is_absolute():
        # Resolve relative to the backend root (two levels up from app/)
        base = Path(__file__).resolve().parent.parent.parent / settings.CHROMA_DB_PATH
    base.mkdir(parents=True, exist_ok=True)
    return str(base)


# ══════════════════════════════════════════════════════════════════════════════
# INGESTION
# ══════════════════════════════════════════════════════════════════════════════

def ingest_pdf(file_path: str, collection_name: str) -> int:
    """
    Load a PDF, chunk it, embed the chunks, and persist them in ChromaDB.

    Args:
        file_path:       Absolute path to the saved PDF on disk.
        collection_name: Unique ChromaDB collection identifier for this document.

    Returns:
        Number of PDF pages ingested.
    """
    # 1. Extract text from every page with PyMuPDF
    doc = fitz.open(file_path)
    page_count = len(doc)
    raw_docs: List[Document] = []

    for page_num, page in enumerate(doc, start=1):
        text = page.get_text("text").strip()
        if not text:
            continue
        raw_docs.append(
            Document(
                page_content=text,
                metadata={
                    "page": page_num,
                    "source": os.path.basename(file_path),
                    "collection": collection_name,
                },
            )
        )
    doc.close()

    if not raw_docs:
        raise ValueError("PDF appears to be empty or contains only images (no extractable text).")

    # 2. Split into smaller chunks
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        separators=["\n\n", "\n", ".", " ", ""],
    )
    chunks = splitter.split_documents(raw_docs)

    # 3. Embed & store in ChromaDB
    Chroma.from_documents(
        documents=chunks,
        embedding=_get_embeddings(),
        collection_name=collection_name,
        persist_directory=_chroma_path(),
    )

    return page_count


# ══════════════════════════════════════════════════════════════════════════════
# QUERYING
# ══════════════════════════════════════════════════════════════════════════════

_RAG_PROMPT = PromptTemplate(
    input_variables=["context", "question"],
    template="""Tu es un assistant pédagogique intelligent pour l'application SmartFocus.
Réponds à la question de l'étudiant en te basant UNIQUEMENT sur le contexte fourni.
Si la réponse n'est pas dans le contexte, dis-le clairement.
Réponds en français sauf si la question est posée dans une autre langue.

CONTEXTE :
{context}

QUESTION : {question}

RÉPONSE :""",
)


def query_rag(
    question: str,
    collection_names: List[str],
    k: int = 5,
) -> Dict[str, Any]:
    """
    Retrieve relevant chunks from ChromaDB and generate an answer with Gemini.

    Args:
        question:         The student's question.
        collection_names: List of ChromaDB collection names (one per selected document).
        k:                Number of chunks to retrieve per collection.

    Returns:
        dict with keys:
            - answer  (str)
            - sources (list of dicts: {filename, page, excerpt})
    """
    embeddings = _get_embeddings()
    all_chunks: List[Document] = []

    # Retrieve top-k chunks from each selected collection
    for col_name in collection_names:
        try:
            vectorstore = Chroma(
                collection_name=col_name,
                embedding_function=embeddings,
                persist_directory=_chroma_path(),
            )
            results = vectorstore.similarity_search(question, k=k)
            all_chunks.extend(results)
        except Exception:
            # Collection may not exist yet — skip silently
            continue

    if not all_chunks:
        return {
            "answer": "Je ne trouve pas d'information pertinente dans les documents sélectionnés.",
            "sources": [],
        }

    # Build context string from retrieved chunks
    context = "\n\n---\n\n".join(
        f"[{c.metadata.get('source', '?')}, p.{c.metadata.get('page', '?')}]\n{c.page_content}"
        for c in all_chunks
    )

    # Generate answer with Gemini 1.5 Flash using direct SDK
    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel('gemini-2.5-flash')
    prompt_text = _RAG_PROMPT.format(context=context, question=question)
    response = llm.generate_content(prompt_text)
    answer = response.text.strip()

    # Build source citations (deduplicated by page)
    seen = set()
    sources = []
    for chunk in all_chunks:
        key = (chunk.metadata.get("source"), chunk.metadata.get("page"))
        if key not in seen:
            seen.add(key)
            sources.append({
                "filename": chunk.metadata.get("source", "Unknown"),
                "page": chunk.metadata.get("page"),
                "excerpt": chunk.page_content[:200].replace("\n", " "),
            })

    return {"answer": answer, "sources": sources}


def query_general(question: str) -> Dict[str, Any]:
    """
    Answer a general question directly with Gemini (No RAG context).
    """
    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel('gemini-2.5-flash')
    response = llm.generate_content(f"Tu es un assistant pédagogique intelligent pour l'application SmartFocus.\n\nRéponds à la question suivante : {question}")
    
    return {
        "answer": response.text.strip(),
        "sources": []
    }


# ══════════════════════════════════════════════════════════════════════════════
# QUIZ GENERATION
# ══════════════════════════════════════════════════════════════════════════════

_QUIZ_PROMPT = PromptTemplate(
    input_variables=["context", "num_questions"],
    template="""Tu es un enseignant expert. À partir du contenu suivant, génère exactement {num_questions} questions à choix multiples (QCM).

Pour chaque question, fournis :
- La question
- 4 options de réponse (A, B, C, D)
- L'index de la bonne réponse (0 = A, 1 = B, 2 = C, 3 = D)
- Une explication courte de pourquoi c'est la bonne réponse

Réponds UNIQUEMENT en JSON valide, sans markdown, sans code fences :
[
  {{
    "question": "...",
    "options": ["A...", "B...", "C...", "D..."],
    "correct_index": 0,
    "explanation": "..."
  }}
]

CONTENU :
{context}
""",
)


def generate_quiz(collection_name: str, num_questions: int = 10) -> List[Dict]:
    """
    Generate a quiz from a document's chunks using Gemini.

    Flow (from design doc Section 4):
      1. Read chunks from ChromaDB
      2. Sample diverse chunks
      3. Build prompt → Gemini generates QCM JSON
      4. Parse & validate JSON

    Returns:
        List of dicts with keys: question, options, correct_index, explanation
    """
    embeddings = _get_embeddings()
    vectorstore = Chroma(
        collection_name=collection_name,
        embedding_function=embeddings,
        persist_directory=_chroma_path(),
    )

    # Retrieve a broad set of chunks for diversity
    all_chunks = vectorstore.similarity_search("résumé du contenu principal", k=30)
    if not all_chunks:
        raise ValueError("No chunks found for this document.")

    # Sample for thematic diversity
    sample_size = min(len(all_chunks), max(num_questions, 15))
    sampled = random.sample(all_chunks, sample_size)

    context = "\n\n---\n\n".join(c.page_content for c in sampled)

    # Generate with Gemini
    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel('gemini-2.5-flash')
    prompt_text = _QUIZ_PROMPT.format(context=context, num_questions=num_questions)
    response = llm.generate_content(prompt_text)

    # Parse JSON response using regex to extract array
    raw_text = response.text.strip()
    match = re.search(r'\[\s*\{.*\}\s*\]', raw_text, re.DOTALL)
    if match:
        raw_text = match.group(0)

    try:
        questions = json.loads(raw_text)
    except json.JSONDecodeError as e:
        raise ValueError(f"Gemini returned invalid JSON (quiz): {e}\nRaw output: {raw_text}")


    # Validate structure
    validated = []
    for q in questions:
        if "question" in q and "options" in q and "correct_index" in q:
            if len(q["options"]) == 4 and 0 <= q["correct_index"] <= 3:
                validated.append(q)

    if not validated:
        raise ValueError("Failed to generate valid quiz questions from the document.")

    return validated[:num_questions]


def generate_quiz_from_collections(
    collection_names: List[str],
    num_questions: int = 10,
) -> List[Dict]:
    """Generate one quiz from multiple document collections."""
    unique_collections = list(dict.fromkeys(collection_names))
    if not unique_collections:
        raise ValueError("No document collections provided for quiz generation.")

    if len(unique_collections) == 1:
        return generate_quiz(unique_collections[0], num_questions=num_questions)

    embeddings = _get_embeddings()
    all_chunks: List[Document] = []

    for collection_name in unique_collections:
        vectorstore = Chroma(
            collection_name=collection_name,
            embedding_function=embeddings,
            persist_directory=_chroma_path(),
        )
        all_chunks.extend(
            vectorstore.similarity_search("resume du contenu principal", k=12)
        )

    if not all_chunks:
        raise ValueError("No chunks found for the selected documents.")

    sample_size = min(len(all_chunks), max(num_questions * 2, 18))
    sampled = random.sample(all_chunks, sample_size)
    context = "\n\n---\n\n".join(chunk.page_content for chunk in sampled)

    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel('gemini-2.5-flash')
    prompt_text = _QUIZ_PROMPT.format(context=context, num_questions=num_questions)
    response = llm.generate_content(prompt_text)

    raw_text = response.text.strip()
    match = re.search(r'\[\s*\{.*\}\s*\]', raw_text, re.DOTALL)
    if match:
        raw_text = match.group(0)

    try:
        questions = json.loads(raw_text)
    except json.JSONDecodeError as e:
        raise ValueError(
            f"Gemini returned invalid JSON (quiz): {e}\nRaw output: {raw_text}"
        )

    validated = []
    for q in questions:
        if "question" in q and "options" in q and "correct_index" in q:
            if len(q["options"]) == 4 and 0 <= q["correct_index"] <= 3:
                validated.append(q)

    if not validated:
        raise ValueError("Failed to generate valid quiz questions from the selected documents.")

    return validated[:num_questions]


# ══════════════════════════════════════════════════════════════════════════════
# FLASHCARD GENERATION
# ══════════════════════════════════════════════════════════════════════════════

_FLASHCARD_PROMPT = PromptTemplate(
    input_variables=["context", "num_cards"],
    template="""Tu es un enseignant expert. À partir du contenu suivant, génère exactement {num_cards} flashcards éducatives.

Chaque flashcard doit contenir :
- "front" : une question courte, un terme ou un concept clé
- "back" : la réponse, la définition ou l'explication

Réponds UNIQUEMENT en JSON valide, sans markdown, sans code fences :
[
  {{
    "front": "Qu'est-ce que la mitose ?",
    "back": "La mitose est un processus de division cellulaire qui produit deux cellules filles identiques."
  }}
]

CONTENU :
{context}
""",
)


def generate_flashcards(collection_name: str, num_cards: int = 15) -> List[Dict]:
    """
    Generate flashcards from a document's chunks using Gemini.

    Flow (from design doc Section 5 — GENERATE_FC):
      1. Read chunks from ChromaDB
      2. Build prompt → Gemini generates recto/verso JSON
      3. Parse & validate

    Returns:
        List of dicts with keys: front, back
    """
    embeddings = _get_embeddings()
    vectorstore = Chroma(
        collection_name=collection_name,
        embedding_function=embeddings,
        persist_directory=_chroma_path(),
    )

    all_chunks = vectorstore.similarity_search("concepts et définitions importants", k=30)
    if not all_chunks:
        raise ValueError("No chunks found for this document.")

    sample_size = min(len(all_chunks), max(num_cards, 15))
    sampled = random.sample(all_chunks, sample_size)

    context = "\n\n---\n\n".join(c.page_content for c in sampled)

    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel('gemini-2.5-flash')
    prompt_text = _FLASHCARD_PROMPT.format(context=context, num_cards=num_cards)
    response = llm.generate_content(prompt_text)

    raw_text = response.text.strip()
    match = re.search(r'\[\s*\{.*\}\s*\]', raw_text, re.DOTALL)
    if match:
        raw_text = match.group(0)

    try:
        cards = json.loads(raw_text)
    except json.JSONDecodeError as e:
        raise ValueError(f"Gemini returned invalid JSON (flashcards): {e}\nRaw output: {raw_text}")


    # Validate structure
    validated = []
    for card in cards:
        if "front" in card and "back" in card:
            validated.append(card)

    if not validated:
        raise ValueError("Failed to generate valid flashcards from the document.")

    return validated[:num_cards]


def generate_flashcards_from_collections(
    collection_names: List[str],
    num_cards: int = 15,
) -> List[Dict]:
    """Generate one flashcard deck from multiple document collections."""
    unique_collections = list(dict.fromkeys(collection_names))
    if not unique_collections:
        raise ValueError("No document collections provided for flashcard generation.")

    if len(unique_collections) == 1:
        return generate_flashcards(unique_collections[0], num_cards=num_cards)

    embeddings = _get_embeddings()
    all_chunks: List[Document] = []

    for collection_name in unique_collections:
        vectorstore = Chroma(
            collection_name=collection_name,
            embedding_function=embeddings,
            persist_directory=_chroma_path(),
        )
        all_chunks.extend(
            vectorstore.similarity_search("concepts et definitions importants", k=12)
        )

    if not all_chunks:
        raise ValueError("No chunks found for the selected documents.")

    sample_size = min(len(all_chunks), max(num_cards * 2, 18))
    sampled = random.sample(all_chunks, sample_size)
    context = "\n\n---\n\n".join(chunk.page_content for chunk in sampled)

    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel('gemini-2.5-flash')
    prompt_text = _FLASHCARD_PROMPT.format(context=context, num_cards=num_cards)
    response = llm.generate_content(prompt_text)

    raw_text = response.text.strip()
    match = re.search(r'\[\s*\{.*\}\s*\]', raw_text, re.DOTALL)
    if match:
        raw_text = match.group(0)

    try:
        cards = json.loads(raw_text)
    except json.JSONDecodeError as e:
        raise ValueError(
            f"Gemini returned invalid JSON (flashcards): {e}\nRaw output: {raw_text}"
        )

    validated = []
    for card in cards:
        if "front" in card and "back" in card:
            validated.append(card)

    if not validated:
        raise ValueError("Failed to generate valid flashcards from the selected documents.")

    return validated[:num_cards]


# ══════════════════════════════════════════════════════════════════════════════
# CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

def delete_collection(collection_name: str) -> None:
    """Remove a ChromaDB collection (all vectors for a document)."""
    try:
        import chromadb
        client = chromadb.PersistentClient(path=_chroma_path())
        client.delete_collection(name=collection_name)
    except Exception:
        pass  # Collection may not exist; that's fine
