"""Arma el informe que el visitador le entrega al agricultor.

Es la promesa del guion de consentimiento: "con eso le armo un informe de su
finca y se lo entrego". No es un documento interno de Sirius — lo va a leer el
productor, en su casa, y va a corregir lo que no reconozca.

De ahi salen las dos reglas que gobiernan el prompt: nada que no este en la
conversacion, y un estimado no se escribe como si fuera un hecho.
"""

from datetime import datetime, timezone

from anthropic import AsyncAnthropic
from fastapi import HTTPException

from ..config import Settings
from ..schemas_informe import InformeRequest, InformeResult
from .errors import UPSTREAM_EXCEPTIONS, upstream_error

SYSTEM = """Escribis el informe de una visita de campo de Sirius Regenerative para
entregarselo AL AGRICULTOR que acaba de ser visitado.

Quien lo lee: el productor y su familia, en su casa, en papel o por WhatsApp.
Puede tener escolaridad basica. Escribi como le hablarias a el, no como un
informe tecnico: frases cortas, sin jerga, sin siglas sin explicar. Trata al
productor de usted.

REGLAS QUE NO SE NEGOCIAN:

1. Solo escribis lo que esta en la conversacion o en los datos que te paso.
   Nada de conocimiento general de agronomia presentado como si fuera algo que
   se observo en esta finca. Si un dato no esta, no esta.

2. La certeza de cada dato manda como lo escribis:
   - "Confirmado": el agricultor lo dijo. Escribilo directo ("Usted tiene tres
     pozos").
   - "Estimado": dio un aproximado. Escribilo como aproximado ("alrededor de",
     "unas").
   - "Inferido": se dedujo. Marcalo como entendimiento tuyo y pedile que
     confirme ("Entendimos que...; si no es asi, corrijanos").
   - "Pendiente": NO lo escribas como dato. Va en la seccion de lo que falta.

3. Las recomendaciones tienen que seguirse de lo que el mismo conto. Si conto
   que quema el lote antes de sembrar, podes hablar de eso. Si no hablo de
   fertilizacion, no recomiendes fertilizantes. Es mejor un informe corto y
   cierto que uno largo e inventado.

4. No prometas nada en nombre de Sirius: ni precios, ni visitas, ni productos,
   ni plazos. Si algo quedo por definir, decilo asi.

5. Si la conversacion fue corta o quedo a medias, el informe lo dice sin
   disimular. Un informe que aparenta completitud sobre una charla de cinco
   minutos le hace perder la confianza al productor apenas lo lea.

FORMATO: markdown, con esta estructura y en este orden. Omiti una seccion
entera si no tenes con que llenarla — es preferible a rellenarla.

# Informe de su visita

NO repitas debajo del titulo la finca, la vereda, la fecha ni quien visito: el
documento ya trae esos datos en su encabezado y repetirlos se lee como un error
de armado. Arranca directo en la primera seccion.

## Lo que conversamos
Dos o tres parrafos, en pasado, contando la visita.

## Su finca hoy
Lo que quedo registrado, agrupado por tema, en vinetas. Cada vineta una idea.

## Lo que nos llamo la atencion
Solo si se sigue de lo conversado. Sin reganar y sin alarmar.

## Lo que quedo pendiente
Lo que no alcanzamos a conversar y conviene ver en la proxima.

Cerra con una linea agradeciendo el tiempo. Sin firma ni datos de contacto."""


def _bloque_hallazgos(req: InformeRequest) -> str:
    if not req.hallazgos:
        return "(No se extrajo ningun dato estructurado de esta visita.)"

    por_modulo: dict[str, list[str]] = {}
    for h in req.hallazgos:
        # Un pendiente no es un dato: no puede aparecer como si lo fuera.
        if h.certeza == "Pendiente":
            continue
        valor = f"{h.valor} {h.unidad}".strip() if h.unidad else h.valor
        modulo = h.modulo or "Sin modulo"
        por_modulo.setdefault(modulo, []).append(
            f"- {h.campo}: {valor}  [certeza: {h.certeza}]"
        )

    if not por_modulo:
        return "(Todos los datos quedaron en Pendiente: ninguno se puede afirmar.)"

    partes = []
    for modulo, lineas in por_modulo.items():
        partes.append(f"### {modulo}\n" + "\n".join(lineas))
    return "\n\n".join(partes)


def _prompt(req: InformeRequest) -> str:
    fecha = (req.fecha or datetime.now(timezone.utc)).strftime("%d de %B de %Y")
    lugar = " / ".join(x for x in (req.vereda, req.municipio) if x)

    partes = [
        "DATOS DE LA VISITA",
        f"Productor: {req.productor or 'sin registrar'}",
        f"Finca: {req.finca or 'sin registrar'}",
        f"Lugar: {lugar or 'sin registrar'}",
        f"Fecha: {fecha}",
        f"Visito: {req.visitador or 'sin registrar'}",
        f"Cobertura del cuestionario: {req.completitud_pct}%",
        "",
        "DATOS REGISTRADOS",
        _bloque_hallazgos(req),
    ]

    if req.temas_pendientes:
        partes += ["", "TEMAS QUE QUEDARON PENDIENTES", req.temas_pendientes]

    if req.transcripcion:
        partes += [
            "",
            "TRANSCRIPCION DE LA CONVERSACION",
            "(Viene de reconocimiento automatico: puede tener nombres mal "
            "escritos. Si algo no se entiende, no lo adivines.)",
            req.transcripcion,
        ]
    else:
        partes += [
            "",
            "NO HAY TRANSCRIPCION.",
            "Arma el informe solo con los datos registrados y decilo en «Lo que "
            "conversamos»: que este informe se hizo sin la grabacion.",
        ]

    return "\n".join(partes)


async def generar(settings: Settings, req: InformeRequest) -> InformeResult:
    if not settings.anthropic_api_key:
        raise HTTPException(
            status_code=500, detail="Falta ANTHROPIC_API_KEY en el backend."
        )

    # Sin conversacion y sin datos no hay informe que hacer. Generar uno igual
    # produciria un documento de relleno con el membrete de Sirius encima.
    if not req.transcripcion and not req.hallazgos:
        raise HTTPException(
            status_code=400,
            detail=(
                "Esta visita todavia no tiene transcripcion ni datos extraidos. "
                "Procesa la conversacion primero."
            ),
        )

    cliente = AsyncAnthropic(api_key=settings.anthropic_api_key)
    try:
        respuesta = await cliente.messages.create(
            model=settings.claude_model,
            max_tokens=4000,
            system=SYSTEM,
            messages=[{"role": "user", "content": _prompt(req)}],
        )
    except UPSTREAM_EXCEPTIONS as exc:
        raise upstream_error("Anthropic", exc) from exc

    contenido = "".join(
        bloque.text for bloque in respuesta.content if bloque.type == "text"
    ).strip()

    if not contenido:
        raise HTTPException(
            status_code=502, detail="El modelo devolvio un informe vacio."
        )

    finca = req.finca or req.productor or req.codigo_visita[:8]
    fecha = (req.fecha or datetime.now(timezone.utc)).strftime("%Y-%m-%d")

    return InformeResult(
        titulo=f"Informe {finca} - {fecha}",
        contenido=contenido,
        generado_en=datetime.now(timezone.utc),
        modelo=settings.claude_model,
    )
