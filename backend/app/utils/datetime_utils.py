from datetime import UTC, datetime


def utc_now_naive() -> datetime:
    """Return the current UTC instant as a naive datetime.

    The project still stores naive UTC timestamps in the database. Centralizing
    this conversion lets us avoid deprecated ``datetime.utcnow()`` calls while
    keeping backward-compatible persisted values.
    """

    return datetime.now(UTC).replace(tzinfo=None)
