from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings, get_settings
from .schemas import (
    PublishRequest,
    PublishResult,
    Report,
    ReportRequest,
    TranscriptionResult,
)
from .services import airtable, report as report_service, transcription

app = FastAPI(title="Sirius Reuniones API", version="0.1.0")

# La app corre tambien en web, asi que el navegador hace preflight.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def require_api_key(
    x_api_key: str = Header(default=""),
    settings: Settings = Depends(get_settings),
) -> Settings:
    if not settings.app_api_key:
        raise HTTPException(status_code=500, detail="APP_API_KEY no esta configurada.")
    if x_api_key != settings.app_api_key:
        raise HTTPException(status_code=401, detail="X-API-Key invalida.")
    return settings


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/transcriptions", response_model=TranscriptionResult)
async def create_transcription(
    file: UploadFile = File(...),
    language: str = Form("es"),
    settings: Settings = Depends(require_api_key),
) -> TranscriptionResult:
    audio = await file.read()
    return await transcription.transcribe(
        settings, file.filename or "reunion.m4a", audio, language
    )


@app.post("/v1/reports", response_model=Report)
async def create_report(
    req: ReportRequest,
    settings: Settings = Depends(require_api_key),
) -> Report:
    return await report_service.build_report(settings, req)


@app.post("/v1/meetings", response_model=PublishResult)
async def publish_meeting(
    req: PublishRequest,
    settings: Settings = Depends(require_api_key),
) -> PublishResult:
    return await airtable.publish(settings, req)
