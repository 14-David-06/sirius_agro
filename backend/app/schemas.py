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


class Turno(BaseModel):
    """Un turno de habla: quien, desde que segundo y que dijo.

    El `segundo` es lo que permite que un hallazgo apunte al lugar exacto del
    audio donde se dijo. Sin turnos con marca de tiempo no hay citas, y sin
    citas los hallazgos no pueden pasar de Pendiente.
    """

    hablante: int
    inicio: float
    fin: float
    texto: str


class HablanteStats(BaseModel):
    """Cuanto hablo cada voz. Sirve para decidir quien es quien."""

    hablante: int
    segundos: float
    turnos: int


class TranscriptionResult(BaseModel):
    text: str
    language: str | None = None
    duration_seconds: float | None = None
    motor: str | None = None

    turnos: list[Turno] = Field(default_factory=list)

    # Transcripcion legible con marca de tiempo por turno. Es lo que va a
    # `Grabaciones.Transcripcion con marcas de tiempo`.
    text_with_timestamps: str = ""

    hablantes: list[HablanteStats] = Field(default_factory=list)

    # Cual de las voces PARECE ser el visitador, y por que.
    #
    # Es una sugerencia, no un dato: el backend no puede saberlo. Y la
    # diferencia importa porque de esto depende la regla dura de que lo dicho
    # por el visitador nunca queda Confirmado. Si el mapeo se invierte, se
    # degrada el dato del agricultor y se avala el del visitador — justo al
    # reves de lo que la regla busca. Por eso lo confirma el visitador en la
    # pantalla de validacion, de un toque, una vez por visita.
    hablante_visitador_sugerido: int | None = None
    razon_sugerencia: str = ""


class CampoCatalogo(BaseModel):
    """Un campo activo del catalogo, tal como lo tiene la app en su base local.

    Lo manda la app y no lo lee el backend de Airtable a proposito: son los
    mismos campos contra los que la app calcula la completitud, asi que el
    esquema de extraccion y el conteo no pueden desalinearse.
    """

    clave_tecnica: str
    campo: str = ""
    modulo: str = ""
    tipo_dato: str = "Texto"
    unidad: str | None = None
    opciones: str | None = None
    pregunta_guia: str | None = None


class ExtraccionRequest(BaseModel):
    codigo_visita: str
    transcripcion: str
    campos: list[CampoCatalogo] = Field(default_factory=list)

    # Cual de las voces es el visitador, confirmado por el visitador en la app.
    # Si viene null, todos los hablantes quedan "no identificado": adivinarlo
    # invertiria la regla de que lo dicho por el visitador nunca es Confirmado.
    hablante_visitador: int | None = None


class ExtraccionResult(BaseModel):
    hallazgos: list[dict] = Field(default_factory=list)
    resumen: str | None = None
    temas_pendientes: list[str] = Field(default_factory=list)


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
