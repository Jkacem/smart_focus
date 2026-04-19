"""Centralized LLM client with provider switch (Gemini or Groq).

All text generation calls in the backend should go through ``gemini_generate``.
The function name is kept for backward compatibility with existing imports.
"""

from __future__ import annotations

import logging
import random
import re
import threading
import time
from collections import deque
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

try:
    import google.generativeai as genai
    from google.api_core.exceptions import ResourceExhausted as GeminiRateLimitError
except Exception:  # pragma: no cover - optional import at runtime
    genai = None
    GeminiRateLimitError = Exception  # type: ignore[assignment]

_MAX_RETRIES = 3
_BASE_BACKOFF_SECONDS = 5.0

_lock = threading.Lock()
_call_timestamps: deque[float] = deque()
_groq_http_client: httpx.Client | None = None


def _effective_max_rpm() -> int:
    value = int(getattr(settings, "LLM_MAX_RPM", 0) or 0)
    if value > 0:
        return value
    provider = (settings.AI_PROVIDER or "gemini").strip().lower()
    if provider == "groq":
        return 25  # under Groq free-tier 30 RPM
    return 4  # under Gemini free-tier 5 RPM


def _wait_for_token() -> None:
    window_seconds = 60.0
    max_rpm = _effective_max_rpm()

    while True:
        with _lock:
            now = time.monotonic()
            while _call_timestamps and now - _call_timestamps[0] >= window_seconds:
                _call_timestamps.popleft()

            if len(_call_timestamps) < max_rpm:
                _call_timestamps.append(now)
                return

            wait_until = _call_timestamps[0] + window_seconds
            sleep_for = wait_until - now + 0.1

        logger.debug("LLM rate-limiter: waiting %.1fs for a free slot", sleep_for)
        time.sleep(max(sleep_for, 0.1))


def _sleep_with_jitter(base_seconds: float) -> None:
    jitter = random.uniform(1.0, 3.0)
    time.sleep(max(base_seconds, 0.1) + jitter)


def _default_model_for_provider(provider: str) -> str:
    if provider == "groq":
        return settings.GROQ_MODEL
    return settings.GEMINI_MODEL


def _generate_with_gemini(prompt: str, model: str) -> str:
    if genai is None:
        raise RuntimeError(
            "google-generativeai is not installed. Add it to requirements first."
        )
    if not settings.GOOGLE_API_KEY:
        raise ValueError("GOOGLE_API_KEY is not configured.")

    genai.configure(api_key=settings.GOOGLE_API_KEY)
    llm = genai.GenerativeModel(model)

    for attempt in range(1, _MAX_RETRIES + 1):
        _wait_for_token()
        try:
            response = llm.generate_content(prompt)
            text = (response.text or "").strip()
            if text:
                return text
            raise ValueError("Gemini returned an empty response.")
        except GeminiRateLimitError as exc:
            if attempt == _MAX_RETRIES:
                logger.error("Gemini rate limit after %d attempts.", attempt)
                raise
            wait_seconds = _BASE_BACKOFF_SECONDS
            delay_match = re.search(r"retry in\s+([\d.]+)s", str(exc), re.IGNORECASE)
            if delay_match:
                wait_seconds = float(delay_match.group(1))
            logger.warning(
                "Gemini rate-limited (%d/%d), retrying in %.1fs",
                attempt,
                _MAX_RETRIES,
                wait_seconds,
            )
            _sleep_with_jitter(wait_seconds)

    raise RuntimeError("Gemini retry loop ended unexpectedly.")


def _get_groq_http_client() -> httpx.Client:
    global _groq_http_client
    if _groq_http_client is not None:
        return _groq_http_client
    if not settings.GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY is not configured.")

    _groq_http_client = httpx.Client(
        base_url="https://api.groq.com/openai/v1",
        timeout=60.0,
        headers={
            "Authorization": f"Bearer {settings.GROQ_API_KEY}",
            "Content-Type": "application/json",
        },
    )
    return _groq_http_client


def _generate_with_groq(prompt: str, model: str) -> str:
    client = _get_groq_http_client()

    for attempt in range(1, _MAX_RETRIES + 1):
        _wait_for_token()
        try:
            response = client.post(
                "/chat/completions",
                json={
                    "model": model,
                    "messages": [{"role": "user", "content": prompt}],
                    "temperature": 0.2,
                },
            )

            if response.status_code == 429:
                raise httpx.HTTPStatusError(
                    "Groq rate limit",
                    request=response.request,
                    response=response,
                )

            response.raise_for_status()
            payload = response.json()
            text = (
                payload.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
                .strip()
            )
            if text:
                return text
            raise ValueError("Groq returned an empty response.")
        except httpx.HTTPStatusError as exc:
            if exc.response is None or exc.response.status_code != 429:
                raise
            if attempt == _MAX_RETRIES:
                logger.error("Groq rate limit after %d attempts.", attempt)
                raise
            wait_seconds = _BASE_BACKOFF_SECONDS
            logger.warning(
                "Groq rate-limited (%d/%d), retrying in %.1fs",
                attempt,
                _MAX_RETRIES,
                wait_seconds,
            )
            _sleep_with_jitter(wait_seconds)

    raise RuntimeError("Groq retry loop ended unexpectedly.")


def gemini_generate(prompt: str, *, model: str | None = None) -> str:
    """Generate text using configured provider.

    Compatibility note:
    The function name stays ``gemini_generate`` to avoid touching all callers.
    Provider is selected by ``AI_PROVIDER`` in `.env`.
    """
    provider = (settings.AI_PROVIDER or "gemini").strip().lower()
    selected_model = (model or _default_model_for_provider(provider)).strip()

    if provider == "groq":
        return _generate_with_groq(prompt, selected_model)
    if provider == "gemini":
        return _generate_with_gemini(prompt, selected_model)

    raise ValueError(
        f"Unsupported AI_PROVIDER='{settings.AI_PROVIDER}'. Use 'gemini' or 'groq'."
    )
