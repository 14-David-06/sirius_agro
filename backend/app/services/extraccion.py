"""Estructura la conversacion contra el catalogo de campos.

El esquema NO esta escrito a mano: se genera desde los campos activos que manda
la app. La app los tiene en su base local y son los mismos contra los que
calcula la completitud, asi que las dos cosas no pueden desalinearse. Si el
backend leyera el catalogo de Airtable por su cuenta, un telefono con la
semilla vieja pediria un esquema distinto del que usa para contar.

Las reglas duras NO viven aqui: el modelo puede desobedecer una instruccion,
asi que la app las vuelve a aplicar al escribir cada hallazgo
(`resolverProcedencia`). Lo que se le pide al modelo es que declare lo que
observo; lo que se hace con esa declaracion es decision del codigo.
"""

import json

from anthropic import AsyncAnthropic
from fastapi import HTTPException

from ..config import Settings
from ..schemas import ExtraccionRequest, ExtraccionResult
from .errors import UPSTREAM_EXCEPTIONS, upstream_error

SYSTEM = """Eres un asistente que estructura conversaciones de campo de Sirius
Regenerative. Recibes la transcripcion diarizada de una visita a una finca en el
piedemonte llanero colombiano y devuelves los datos que APARECEN en ella.

La transcripcion viene en lineas con este formato:
[mm:ss] Hablante N: lo que dijo

REGLA ABSOLUTA: no inventes nada.
Si un dato no aparece en la conversacion, NO lo incluyas. Nunca completes con lo
que "suele ser" ni con lo que seria razonable en una finca de la zona. Un dato
faltante es un resultado correcto; un dato plausible pero no dicho arruina el
diagnostico y hace que el agricultor pierda la confianza cuando lea el informe y
vea algo que no dijo.

Para cada dato que si aparece, devuelve:

- `clave`: exactamente una de las claves tecnicas de la lista de campos. Si lo que
  se hablo no corresponde a ninguna, NO inventes una clave: mandalo en
  `temas_pendientes`.
- `cita`: la frase de la transcripcion que respalda el dato, copiada TAL CUAL.
  No la parafrasees ni la corrijas. Sin cita el dato se descarta.
- `segundo`: los segundos del [mm:ss] de la linea de donde salio la cita.
- `hablante`: el numero N del "Hablante N" que lo dijo, empezando en 1.
- `certeza`:
  * "Confirmado": lo afirmo con claridad. "Son doce hectareas".
  * "Estimado": dio un aproximado o un rango. "Seran unas doce", "como doce".
    Las muletillas de aproximacion importan: si dijo "unos veinte anios", es
    Estimado, no Confirmado.
  * "Inferido": no lo dijo, se deduce de otra cosa que si dijo. Exige
    `razonamiento` en una linea. Si no podes escribir el razonamiento, no es
    Inferido: es un dato que no esta.
- `razonamiento`: obligatorio y solo cuando certeza es "Inferido".

Sobre las entidades, y esto importa mucho:
Una finca tiene varios cultivos y la conversacion salta entre ellos. Usa
`entidad_destino` ("Productor", "Finca", "Lote", "Cultivo", "Animal", "Insumo",
"Visita") y `entidad_local_id` para distinguirlos: "cultivo_1", "cultivo_2". Si
dice que tiene platano, yuca y maiz, y que del platano tiene cuatro hectareas,
esas cuatro hectareas van con el `entidad_local_id` del platano y NO con los
otros. Mezclarlos es peor que no tener el dato.

Distingue lo que tiene de lo que tuvo. Un cultivo que abandono, un producto que
usaba antes o un comprador que ya no le compra NO son datos actuales. Si la
conversacion habla en pasado, no lo registres como presente.

Distingue quien habla. Cuando el visitador sugiere un dato ("usted usa DAP,
cierto?") y el agricultor solo asiente, el `hablante` es el visitador. Reportalo
igual con el hablante correcto: el sistema decide que hacer con eso.

Si un producto se menciona sin nombre ("el que me recomendaron en el almacen"),
registralo como esta dicho. No adivines la marca.

`resumen`: dos o tres parrafos de lo que paso en la visita, en tercera persona.
`temas_pendientes`: lo que se hablo y no cupo en ningun campo, y lo que quedo a
medias y conviene preguntar en la proxima visita."""

_TIPOS = {
    "Numero": "un numero, sin unidad en el texto",
    "Si/No": 'la palabra "si" o "no"',
    "Lista": "uno de los valores permitidos",
    "Fecha": "una fecha o una epoca como la dijo",
    "Ubicacion": "el lugar como lo describio",
    "Texto": "el valor como lo dijo",
}


def _lista_de_campos(campos) -> str:
    """La lista que ve el modelo, generada desde el catalogo que mando la app."""
    lineas = []
    for c in campos:
        partes = [f"- {c.clave_tecnica} ({c.modulo})"]
        if c.campo:
            partes.append(f": {c.campo}")
        detalle = [_TIPOS.get(c.tipo_dato, _TIPOS["Texto"])]
        if c.unidad:
            detalle.append(f"unidad esperada: {c.unidad}")
        if c.opciones:
            valores = " | ".join(o.strip() for o in c.opciones.splitlines() if o.strip())
            detalle.append(f"valores: {valores}")
        partes.append(f" [{'; '.join(detalle)}]")
        lineas.append("".join(partes))
    return "\n".join(lineas)


def esquema(claves: list[str]) -> dict:
    """Esquema de la herramienta. `clave` es un enum cerrado a proposito.

    Con el enum, una clave inventada es un error de validacion del proveedor y
    no un hallazgo que entra a la base apuntando a un campo que no existe.
    """
    return {
        "type": "object",
        "properties": {
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
                        "entidad_local_id": {
                            "type": ["string", "null"],
                            "description": "cultivo_1, cultivo_2, lote_1. null si no aplica.",
                        },
                        "valor_texto": {"type": ["string", "null"]},
                        "valor_numerico": {"type": ["number", "null"]},
                        "unidad": {"type": ["string", "null"]},
                        "certeza": {
                            "type": "string",
                            "enum": ["Confirmado", "Estimado", "Inferido"],
                        },
                        "hablante": {
                            "type": "integer",
                            "description": "El N de 'Hablante N', empezando en 1.",
                        },
                        "cita": {
                            "type": "string",
                            "description": "Copiada tal cual de la transcripcion.",
                        },
                        "segundo": {"type": "integer"},
                        "razonamiento": {"type": ["string", "null"]},
                    },
                    "required": [
                        "clave",
                        "entidad_destino",
                        "certeza",
                        "hablante",
                        "cita",
                        "segundo",
                    ],
                    "additionalProperties": False,
                },
            },
            "resumen": {"type": "string"},
            "temas_pendientes": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["hallazgos", "resumen", "temas_pendientes"],
        "additionalProperties": False,
    }


def _hablante_a_texto(numero: int | None, visitador: int | None) -> str:
    """Traduce el numero de voz a agricultor / visitador.

    El mapeo lo confirma el visitador en la app; si no lo confirmo, todo queda
    como "no identificado" en vez de adivinar. Equivocarse aca invierte la
    regla dura: degradaria el dato del agricultor y avalaria el del visitador.
    """
    if numero is None or visitador is None:
        return "no identificado"
    return "visitador" if numero == visitador else "agricultor"


async def extraer(settings: Settings, req: ExtraccionRequest) -> ExtraccionResult:
    if not req.transcripcion.strip():
        raise HTTPException(
            status_code=400,
            detail="La transcripcion llego vacia: primero hay que transcribir el audio.",
        )
    if not req.campos:
        raise HTTPException(
            status_code=400,
            detail="No llego el catalogo de campos, asi que no se puede armar el esquema.",
        )
    if not settings.anthropic_api_key:
        raise HTTPException(
            status_code=500, detail="Falta ANTHROPIC_API_KEY en el backend."
        )

    claves = [c.clave_tecnica for c in req.campos]
    client = AsyncAnthropic(api_key=settings.anthropic_api_key)

    prompt = (
        f"CAMPOS QUE SE PUEDEN LLENAR ({len(claves)}):\n"
        f"{_lista_de_campos(req.campos)}\n\n"
        f"TRANSCRIPCION DE LA VISITA:\n{req.transcripcion}"
    )

    try:
        respuesta = await client.messages.create(
            model=settings.claude_model,
            max_tokens=16000,
            system=SYSTEM,
            tools=[
                {
                    "name": "registrar_hallazgos",
                    "description": "Registra los datos que aparecen en la conversacion.",
                    "input_schema": esquema(claves),
                }
            ],
            tool_choice={"type": "tool", "name": "registrar_hallazgos"},
            messages=[{"role": "user", "content": prompt}],
        )
    except UPSTREAM_EXCEPTIONS as exc:
        raise upstream_error("Claude", exc) from exc

    bloque = next(
        (b for b in respuesta.content if getattr(b, "type", None) == "tool_use"), None
    )
    if bloque is None:
        raise HTTPException(
            status_code=502,
            detail="Claude no devolvio la herramienta de extraccion. Reintenta.",
        )

    return construir_resultado(
        bloque.input,
        hablante_visitador=req.hablante_visitador,
        claves_validas=set(claves),
    )


def construir_resultado(
    crudo: dict,
    hablante_visitador: int | None = None,
    claves_validas: set[str] | None = None,
) -> ExtraccionResult:
    """Normaliza lo que devolvio el modelo. Separado del POST para poder probarlo."""
    if isinstance(crudo, str):
        crudo = json.loads(crudo)

    hallazgos: list[dict] = []
    descartados: list[str] = []

    for h in crudo.get("hallazgos", []) or []:
        clave = h.get("clave")
        # Cinturon sobre el enum: si el proveedor deja pasar una clave que no
        # existe, el hallazgo no entra a la base apuntando a la nada.
        if claves_validas is not None and clave not in claves_validas:
            descartados.append(f"Clave desconocida del modelo: {clave}")
            continue

        hallazgos.append(
            {
                "clave": clave,
                "entidad_destino": h.get("entidad_destino"),
                "entidad_local_id": h.get("entidad_local_id"),
                "valor_texto": h.get("valor_texto"),
                "valor_numerico": h.get("valor_numerico"),
                "unidad": h.get("unidad"),
                "certeza": h.get("certeza"),
                "hablante": _hablante_a_texto(h.get("hablante"), hablante_visitador),
                "cita": h.get("cita"),
                "segundo": h.get("segundo"),
                "razonamiento": h.get("razonamiento"),
                "fuente": "Audio",
            }
        )

    pendientes = [str(t) for t in (crudo.get("temas_pendientes") or [])]

    return ExtraccionResult(
        hallazgos=hallazgos,
        resumen=crudo.get("resumen") or None,
        temas_pendientes=pendientes + descartados,
    )
