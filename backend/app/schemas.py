from datetime import datetime

from pydantic import BaseModel, Field


class Answer(BaseModel):
    """Respuesta a una de las preguntas del cuestionario, tomada durante la reunion."""

    question_id: str
    question: str
    answer: str = ""
    # Segundo de la grabacion en que se respondio, para poder saltar al audio.
    at_second: int | None = None


class MeetingMeta(BaseModel):
    title: str
    started_at: datetime
    duration_seconds: int = 0
    participants: list[str] = Field(default_factory=list)
    questionnaire_id: str = "default"
    notes: str = ""


class TranscriptionResult(BaseModel):
    text: str
    language: str | None = None
    duration_seconds: float | None = None


class ReportRequest(BaseModel):
    meta: MeetingMeta
    transcript: str
    answers: list[Answer] = Field(default_factory=list)


class ActionItem(BaseModel):
    tarea: str
    responsable: str = ""
    fecha_limite: str = ""


class Topic(BaseModel):
    titulo: str
    detalle: str


class Report(BaseModel):
    resumen_ejecutivo: str
    temas: list[Topic] = Field(default_factory=list)
    acuerdos: list[str] = Field(default_factory=list)
    pendientes: list[ActionItem] = Field(default_factory=list)
    riesgos: list[str] = Field(default_factory=list)


class PublishRequest(BaseModel):
    meta: MeetingMeta
    transcript: str
    answers: list[Answer] = Field(default_factory=list)
    report: Report


class PublishResult(BaseModel):
    record_id: str
    url: str
