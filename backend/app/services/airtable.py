from urllib.parse import quote

import httpx
from fastapi import HTTPException

from ..config import Settings
from ..schemas import Answer, PublishRequest, PublishResult, Report

API = "https://api.airtable.com/v0"


def report_to_markdown(report: Report) -> str:
    lines = ["## Resumen ejecutivo", report.resumen_ejecutivo, ""]

    if report.temas:
        lines.append("## Temas")
        for t in report.temas:
            lines += [f"### {t.titulo}", t.detalle, ""]

    if report.acuerdos:
        lines.append("## Acuerdos")
        lines += [f"- {a}" for a in report.acuerdos]
        lines.append("")

    if report.pendientes:
        lines.append("## Pendientes")
        for p in report.pendientes:
            extra = " / ".join(x for x in (p.responsable, p.fecha_limite) if x)
            lines.append(f"- {p.tarea}" + (f" ({extra})" if extra else ""))
        lines.append("")

    if report.riesgos:
        lines.append("## Riesgos")
        lines += [f"- {r}" for r in report.riesgos]
        lines.append("")

    return "\n".join(lines).strip()


def answers_to_markdown(answers: list[Answer]) -> str:
    out = []
    for a in answers:
        stamp = ""
        if a.at_second is not None:
            stamp = f" [{a.at_second // 60:02d}:{a.at_second % 60:02d}]"
        out.append(f"**{a.question}**{stamp}\n{a.answer or '(sin responder)'}")
    return "\n\n".join(out)


async def publish(settings: Settings, req: PublishRequest) -> PublishResult:
    if not settings.airtable_token or not settings.airtable_base_id:
        raise HTTPException(status_code=500, detail="Falta configuracion de Airtable.")

    fields = {
        "Titulo": req.meta.title,
        "Fecha": req.meta.started_at.date().isoformat(),
        "Duracion (min)": round(req.meta.duration_seconds / 60, 1),
        "Participantes": ", ".join(req.meta.participants),
        "Transcripcion": req.transcript,
        "Respuestas": answers_to_markdown(req.answers),
        "Informe": report_to_markdown(req.report),
        "Estado": "Procesada",
    }

    table = quote(settings.airtable_table, safe="")
    url = f"{API}/{settings.airtable_base_id}/{table}"
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            url,
            headers={"Authorization": f"Bearer {settings.airtable_token}"},
            json={"fields": fields, "typecast": True},
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=502,
            detail=f"Airtable respondio {response.status_code}: {response.text[:400]}",
        )

    record_id = response.json()["id"]
    return PublishResult(
        record_id=record_id,
        url=f"https://airtable.com/{settings.airtable_base_id}/{record_id}",
    )
