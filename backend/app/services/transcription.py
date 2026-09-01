import io

from fastapi import HTTPException
from openai import AsyncOpenAI

from ..config import Settings
from ..schemas import TranscriptionResult


async def transcribe(
    settings: Settings,
    filename: str,
    audio: bytes,
    language: str | None = "es",
) -> TranscriptionResult:
    if not audio:
        raise HTTPException(status_code=400, detail="El audio llego vacio.")
    if len(audio) > settings.max_audio_bytes:
        raise HTTPException(
            status_code=413,
            detail=(
                f"El audio pesa {len(audio) / 1e6:.1f} MB y el limite de Whisper es "
                f"{settings.max_audio_bytes / 1e6:.0f} MB. Graba en AAC mono a 32 kbps "
                "o parte la reunion en tramos."
            ),
        )
    if not settings.openai_api_key:
        raise HTTPException(status_code=500, detail="Falta OPENAI_API_KEY en el backend.")

    client = AsyncOpenAI(api_key=settings.openai_api_key)
    buffer = io.BytesIO(audio)
    buffer.name = filename or "reunion.m4a"

    result = await client.audio.transcriptions.create(
        model=settings.whisper_model,
        file=buffer,
        language=language or None,
        response_format="verbose_json",
    )

    return TranscriptionResult(
        text=result.text,
        language=getattr(result, "language", None),
        duration_seconds=getattr(result, "duration", None),
    )
