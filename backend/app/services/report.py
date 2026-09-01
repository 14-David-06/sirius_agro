import json

from anthropic import AsyncAnthropic
from fastapi import HTTPException

from ..config import Settings
from ..schemas import Report, ReportRequest

REPORT_SCHEMA = {
    "type": "object",
    "properties": {
        "resumen_ejecutivo": {
            "type": "string",
            "description": "Dos o tres parrafos con lo esencial de la reunion.",
        },
        "temas": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "titulo": {"type": "string"},
                    "detalle": {"type": "string"},
                },
                "required": ["titulo", "detalle"],
                "additionalProperties": False,
            },
        },
        "acuerdos": {"type": "array", "items": {"type": "string"}},
        "pendientes": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "tarea": {"type": "string"},
                    "responsable": {"type": "string"},
                    "fecha_limite": {"type": "string"},
                },
                "required": ["tarea", "responsable", "fecha_limite"],
                "additionalProperties": False,
            },
        },
        "riesgos": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["resumen_ejecutivo", "temas", "acuerdos", "pendientes", "riesgos"],
    "additionalProperties": False,
}

SYSTEM = """Eres analista de reuniones de Sirius Regenerative. Recibes la transcripcion
automatica de una reunion en espanol y las respuestas que un asistente fue anotando
durante la grabacion, y produces un informe estructurado.

Reglas:
- Escribe en espanol neutro y en tercera persona.
- Apoyate solo en lo que aparece en la transcripcion y en las respuestas. Si un dato no
  esta, no lo inventes: deja el campo vacio o escribe "sin definir".
- Las respuestas del cuestionario son la fuente mas confiable; si contradicen a la
  transcripcion, gana la respuesta anotada.
- La transcripcion viene de reconocimiento automatico: puede tener nombres mal escritos
  y frases cortadas. Corrige lo obvio en silencio, no comentes los errores.
- En "pendientes", responsable y fecha_limite quedan vacios si nadie los menciono."""


def _build_prompt(req: ReportRequest) -> str:
    answers = "\n".join(
        f"- {a.question}\n  Respuesta: {a.answer or '(sin responder)'}"
        for a in req.answers
    ) or "(no se registraron respuestas)"

    participants = ", ".join(req.meta.participants) or "no registrados"

    return (
        f"# Reunion\n"
        f"Titulo: {req.meta.title}\n"
        f"Fecha: {req.meta.started_at.isoformat()}\n"
        f"Duracion: {req.meta.duration_seconds // 60} min\n"
        f"Participantes: {participants}\n"
        f"Notas del asistente: {req.meta.notes or '(ninguna)'}\n\n"
        f"# Respuestas del cuestionario\n{answers}\n\n"
        f"# Transcripcion\n{req.transcript}"
    )


async def build_report(settings: Settings, req: ReportRequest) -> Report:
    if not settings.anthropic_api_key:
        raise HTTPException(status_code=500, detail="Falta ANTHROPIC_API_KEY en el backend.")
    if not req.transcript.strip() and not req.answers:
        raise HTTPException(status_code=400, detail="No hay transcripcion ni respuestas.")

    client = AsyncAnthropic(api_key=settings.anthropic_api_key)

    response = await client.beta.messages.create(
        model=settings.claude_model,
        max_tokens=16000,
        system=SYSTEM,
        messages=[{"role": "user", "content": _build_prompt(req)}],
        thinking={"type": "adaptive"},
        output_config={"format": {"type": "json_schema", "schema": REPORT_SCHEMA}},
        # Si un clasificador de seguridad rechaza la peticion, la API reintenta sola
        # en otro modelo en vez de devolvernos una reunion sin informe.
        betas=["server-side-fallback-2026-07-01"],
        fallbacks="default",
    )

    if response.stop_reason == "refusal":
        raise HTTPException(
            status_code=502,
            detail="El modelo rechazo generar el informe para esta transcripcion.",
        )

    text = next((b.text for b in response.content if b.type == "text"), None)
    if not text:
        raise HTTPException(status_code=502, detail="El modelo no devolvio contenido.")

    return Report(**json.loads(text))
