"""El chat de una visita: completar lo que falto y preguntar sobre ella.

Existe porque una conversacion de campo nunca queda completa. El esposo que
maneja el cultivo llega a las tres de la tarde, el nombre de la finca quedo a
medias, el valor del arriendo se dijo sin decir si era mensual. Hasta ahora eso
moria en «temas pendientes» y solo se podia arreglar volviendo a la finca.

Aca el visitador lo escribe y el dato entra al registro.

La diferencia con la extraccion —y es la que gobierna este modulo— es de QUIEN
viene el dato. Alla habla el agricultor, grabado. Aca teclea el visitador, de
memoria y despues. Por eso todo lo que sale de este chat lleva
`fuente = Manual` y `hablante = visitador`, y eso no es una etiqueta: dispara
la primera regla dura del sistema —lo que dice el visitador nunca es
`Confirmado`— que la app y el backend aplican al escribir, cada uno por su
lado.

Ese marcado lo pone ESTE codigo, no el modelo. Al modelo se le pide que declare
lo que entendio; que sea un dato de segunda mano es un hecho del canal, no algo
sobre lo que tenga sentido preguntarle.
"""

import json

from anthropic import AsyncAnthropic
from fastapi import HTTPException

from ..config import Settings
from ..schemas_complemento import (
    MAX_MENSAJES,
    ComplementoRequest,
    ComplementoResult,
)
from .errors import UPSTREAM_EXCEPTIONS, upstream_error
from .extraccion import _lista_de_campos

SYSTEM = """Sos el asistente de UNA visita de campo de Sirius Regenerative.
Hablas con el VISITADOR que la hizo, no con el agricultor.

Servis para dos cosas, y las dos en la misma conversacion:

1. RESPONDER lo que el visitador pregunte sobre esta visita. Solo con lo que
   este en el contexto. Si el dato no esta registrado, decilo: "eso no quedo
   registrado". No lo completes con lo que suele pasar en una finca de la zona.

2. CAPTURAR lo que el visitador aporte. Cuando te cuenta algo que faltaba —"el
   esposo se llama Hernan", "el arriendo son 600 mil al mes", "el lote de
   platano tiene cuatro meses"— lo devolves como hallazgo contra el catalogo de
   campos.

COMO CAPTURAR:

- `clave`: exactamente una de las claves de la lista. Si lo que te cuenta no
  cabe en ninguna, NO inventes una clave: mandalo en `temas_pendientes`.
- `cita`: la frase del visitador, copiada TAL CUAL de su mensaje. Es la
  procedencia del dato: dentro de seis meses tiene que poder verse de donde
  salio un valor que no vino del audio.
- `certeza`:
  * "Confirmado": el visitador lo afirma sin dudar.
  * "Estimado": dio un aproximado, o dice que le parece.
  * "Inferido": lo deducis de lo que conto. Exige `razonamiento`.
  Escribi la que corresponda. El sistema aplica sus propias reglas encima y
  puede bajarla: un dato que aporta el visitador nunca vale lo mismo que uno
  que dijo el agricultor grabado, y eso no lo decidis vos.

- Si el visitador corrige un dato que ya estaba registrado, devolvelo igual con
  el valor nuevo. Que sea una correccion lo resuelve la app.

REGLAS QUE NO SE NEGOCIAN:

- No inventes datos. Si el visitador no lo dijo, no existe. Un campo vacio es
  un resultado correcto.
- No captures lo que el visitador pregunte, solo lo que afirme. "Cuanta tierra
  tiene?" es una pregunta, no un dato.
- No confirmes que guardaste algo que no devolviste como hallazgo. Si no cupo
  en ningun campo, decilo asi: "eso no tiene campo en el cuestionario, lo dejo
  anotado como pendiente".
- No prometas nada en nombre de Sirius: ni precios, ni productos, ni plazos.

COMO ESCRIBIS LA RESPUESTA:

En espanol, corto y directo. El visitador te lee de pie, con el telefono en una
mano. Cuando captures datos, decilos en una linea para que pueda ver si
entendiste bien — es su unica oportunidad de notar un error antes de que el
dato quede guardado. Texto plano, sin titulos ni tablas."""


def esquema(claves: list[str]) -> dict:
    """La herramienta que devuelve el modelo: respuesta mas hallazgos.

    `clave` es un enum cerrado, igual que en la extraccion: una clave inventada
    tiene que ser un error de validacion del proveedor y no un hallazgo que
    entra a la base apuntando a un campo que no existe.

    No lleva `segundo` ni `hablante`, al contrario de la extraccion: no hay
    audio de donde sacar un segundo, y el hablante es siempre el visitador —
    lo fija el codigo, no el modelo.
    """
    return {
        "type": "object",
        "properties": {
            "respuesta": {
                "type": "string",
                "description": "Lo que se le muestra al visitador en el chat.",
            },
            "hallazgos": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "clave": {"type": "string", "enum": claves},
                        "entidad_destino": {
                            "type": "string",
                            "enum": [
                                "Productor",
                                "Finca",
                                "Lote",
                                "Cultivo",
                                "Animal",
                                "Insumo",
                                "Visita",
                            ],
                        },
                        "entidad_local_id": {"type": ["string", "null"]},
                        "valor_texto": {"type": ["string", "null"]},
                        "valor_numerico": {"type": ["number", "null"]},
                        "unidad": {"type": ["string", "null"]},
                        "certeza": {
                            "type": "string",
                            "enum": ["Confirmado", "Estimado", "Inferido"],
                        },
                        "cita": {
                            "type": "string",
                            "description": (
                                "La frase del visitador, copiada tal cual."
                            ),
                        },
                        "razonamiento": {"type": ["string", "null"]},
                    },
                    "required": [
                        "clave",
                        "entidad_destino",
                        "certeza",
                        "cita",
                    ],
                    "additionalProperties": False,
                },
            },
            "temas_pendientes": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["respuesta", "hallazgos", "temas_pendientes"],
        "additionalProperties": False,
    }


def _system(req: ComplementoRequest) -> str:
    partes = [SYSTEM]
    if req.visitador:
        partes.append(f"Estas hablando con {req.visitador}.")

    partes.append(
        "CAMPOS DEL CUESTIONARIO\n"
        "(Son los unicos donde se puede guardar un dato.)\n"
        + _lista_de_campos(req.campos)
    )

    if req.contexto:
        partes.append(
            "LO QUE YA TIENE ESTA VISITA\n"
            "(Es todo lo que sabes de ella. Lo que no este aca, no se "
            "registro.)\n" + req.contexto
        )
    else:
        partes.append(
            "ESTA VISITA NO TIENE NADA REGISTRADO TODAVIA. Decilo si te "
            "preguntan por ella; lo que el visitador aporte ahora es lo "
            "primero que va a quedar."
        )

    return "\n\n".join(partes)


def _marcar_procedencia(hallazgos: list[dict]) -> list[dict]:
    """Le pone a cada hallazgo de donde vino, y no se lo pregunta al modelo.

    `Manual` + `visitador` es lo que hace que la app y Airtable apliquen la
    regla dura al escribir. Si el modelo pudiera elegir estos dos campos,
    bastaria una alucinacion para que un dato tecleado por el visitador
    entrara al registro como si lo hubiera afirmado el agricultor frente a una
    grabadora.
    """
    marcados = []
    for h in hallazgos:
        if not isinstance(h, dict) or not h.get("clave"):
            continue
        marcados.append(
            {
                **h,
                "fuente": "Manual",
                "hablante": "visitador",
                # No hay audio detras de esto. Un segundo inventado mandaria al
                # visitador a escuchar un minuto donde nadie dijo nada.
                "segundo": None,
            }
        )
    return marcados


async def responder(
    settings: Settings, req: ComplementoRequest
) -> ComplementoResult:
    if not settings.anthropic_api_key:
        raise HTTPException(
            status_code=500, detail="Falta ANTHROPIC_API_KEY en el backend."
        )
    if not req.campos:
        raise HTTPException(
            status_code=400,
            detail="No llego el catalogo de campos, asi que no se puede armar el esquema.",
        )

    mensajes = [
        {"role": m.rol, "content": m.contenido}
        for m in req.mensajes[-MAX_MENSAJES:]
        if m.contenido.strip()
    ]
    if not mensajes or mensajes[0]["role"] != "user":
        raise HTTPException(
            status_code=400,
            detail="La conversacion empieza con un mensaje del visitador.",
        )

    claves = [c.clave_tecnica for c in req.campos]
    herramienta = {
        "name": "complementar_visita",
        "description": (
            "Responde al visitador y devuelve los datos que aporto en su "
            "mensaje."
        ),
        "input_schema": esquema(claves),
    }

    cliente = AsyncAnthropic(api_key=settings.anthropic_api_key)
    try:
        respuesta = await cliente.messages.create(
            model=settings.claude_model,
            max_tokens=2000,
            system=_system(req),
            messages=mensajes,
            tools=[herramienta],
            tool_choice={"type": "tool", "name": "complementar_visita"},
        )
    except UPSTREAM_EXCEPTIONS as exc:
        raise upstream_error("Anthropic", exc) from exc

    datos = None
    for bloque in respuesta.content:
        if bloque.type == "tool_use":
            datos = bloque.input
            break

    if datos is None:
        raise HTTPException(
            status_code=502,
            detail="El modelo no devolvio la respuesta en el formato esperado.",
        )

    if isinstance(datos, str):
        datos = json.loads(datos)

    texto = (datos.get("respuesta") or "").strip()
    if not texto:
        raise HTTPException(
            status_code=502, detail="El modelo devolvio una respuesta vacia."
        )

    return ComplementoResult(
        respuesta=texto,
        hallazgos=_marcar_procedencia(datos.get("hallazgos") or []),
        temas_pendientes=[
            t for t in (datos.get("temas_pendientes") or []) if str(t).strip()
        ],
        modelo=settings.claude_model,
    )
