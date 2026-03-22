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
