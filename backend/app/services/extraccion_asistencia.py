"""Saca los datos del registro de asistencia de la nota de voz.

La persona dijo, siguiendo un guion que le mostro la app, su nombre, cedula,
telefono, vereda, cultivos, area y si quiere visita. Aqui Claude lo lee de la
transcripcion y el codigo valida lo que devuelve: una cedula con letras o una
vereda que no existe no entran al registro, se anotan en `por_confirmar` para
que alguien escuche el audio.
"""

import re
import unicodedata

from anthropic import AsyncAnthropic
from fastapi import HTTPException

from ..config import Settings
from ..schemas_asistencia import DatosAsistencia
from .errors import UPSTREAM_EXCEPTIONS, upstream_error

# Las opciones del multiselect `Asistencias.Cultivos sembrados`.
CULTIVOS = [
    "Cafe", "Cacao", "Platano", "Banano", "Aguacate", "Maiz", "Frijol",
    "Yuca", "Papa", "Cana panelera", "Citricos", "Hortalizas", "Frutales",
    "Pastos", "Arroz", "Palma",
]

SYSTEM = """Lees la transcripcion de una nota de voz grabada en un taller de
Sirius Regenerative en el campo colombiano. En ella una persona dice sus datos
para el registro de asistencia, siguiendo este guion: nombre completo, numero
de cedula, telefono, vereda donde vive, cultivos que tiene sembrados, cuantas
hectareas tiene sembradas y si quiere que la visite un tecnico.

REGLA ABSOLUTA: no inventes nada. Si un dato no se dijo, o se dijo de forma que
no se entiende, dejalo en null y explica en `por_confirmar` que falta o que es
dudoso. Un dato vacio es correcto; uno inventado arruina el registro.

- `nombre_completo`: como lo dijo, con mayusculas de nombre propio y tildes.
- `cedula` y `telefono`: SOLO digitos. Los numeros dichos en palabras se
  convierten ("tres cero cero" -> "300", "un millon doscientos mil" ->
  "1200000"). Si se dijo un digito de mas o de menos, o hay dos versiones, no
  elijas: deja lo que se dijo y anotalo en `por_confirmar`.
- `vereda`: EXACTAMENTE uno de los nombres de la lista de veredas, aunque el
  motor de transcripcion lo haya escrito mal ("Waicaramo" es "Guaicaramo"). Si
  no corresponde a ninguna, null, y anota en `por_confirmar` la vereda tal
  como se dijo.
- `cultivos`: usa los nombres de la lista de cultivos cuando correspondan
  (naranja o limon -> "Citricos", tomate o cebolla -> "Hortalizas", mango o
  guayaba -> "Frutales", potrero -> "Pastos", cana -> "Cana panelera"). Un
  cultivo que no encaje en ninguno va con su nombre, en singular y con
  mayuscula inicial. Solo lo que tiene sembrado HOY.
- `area_sembrada_ha`: en hectareas. Una cuadra o una fanegada son 0.64 ha.
  "Dos y media" es 2.5.
- `quiere_visita`: true si pidio o acepto la visita del tecnico, false si dijo
  que no, null si no lo menciono.
- `por_confirmar`: frases cortas en espanol, una por dato dudoso o faltante.
"""

_ESQUEMA = {
    "type": "object",
    "properties": {
        "nombre_completo": {"type": ["string", "null"]},
        "cedula": {"type": ["string", "null"]},
        "telefono": {"type": ["string", "null"]},
        "vereda": {"type": ["string", "null"]},
        "cultivos": {"type": "array", "items": {"type": "string"}},
        "area_sembrada_ha": {"type": ["number", "null"]},
        "quiere_visita": {"type": ["boolean", "null"]},
        "por_confirmar": {"type": "array", "items": {"type": "string"}},
    },
    "required": [
        "nombre_completo", "cedula", "telefono", "vereda", "cultivos",
        "area_sembrada_ha", "quiere_visita", "por_confirmar",
    ],
}


def _sin_tildes(s: str) -> str:
    return "".join(
        c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn"
    ).lower().strip()


def validar(crudo: dict, veredas: list[str]) -> DatosAsistencia:
    """Lo que devolvio el modelo, pasado por reglas que el modelo no decide.

    Se repiten aqui aunque esten en el prompt: una instruccion se puede
    desobedecer, una validacion no.
    """
    dudas = [d.strip() for d in crudo.get("por_confirmar") or [] if str(d).strip()]

    def digitos(campo: str, minimo: int, maximo: int, nombre: str) -> str | None:
        valor = crudo.get(campo)
        if not valor:
            return None
        solo = re.sub(r"\D", "", str(valor))
        if minimo <= len(solo) <= maximo:
            return solo
        dudas.append(f"{nombre} dudoso: se entendio «{valor}».")
        return None

    vereda = None
    if crudo.get("vereda"):
        por_norma = {_sin_tildes(v): v for v in veredas}
        vereda = por_norma.get(_sin_tildes(str(crudo["vereda"])))
        if vereda is None:
            dudas.append(f"La vereda «{crudo['vereda']}» no esta en la tabla Veredas.")

    cultivos: list[str] = []
    por_norma_cultivo = {_sin_tildes(c): c for c in CULTIVOS}
    for c in crudo.get("cultivos") or []:
        texto = str(c).strip()
        if not texto:
            continue
        nombre = por_norma_cultivo.get(_sin_tildes(texto), texto[0].upper() + texto[1:])
        if nombre not in cultivos:
            cultivos.append(nombre)

    area = crudo.get("area_sembrada_ha")
    if area is not None:
        try:
            area = round(float(area), 2)
        except (TypeError, ValueError):
            area = None
        if area is not None and not 0 <= area <= 10000:
            dudas.append(f"Area dudosa: {area} ha.")
            area = None

    nombre = (crudo.get("nombre_completo") or "").strip() or None
    quiere = crudo.get("quiere_visita")

    return DatosAsistencia(
        nombre_completo=nombre,
        cedula=digitos("cedula", 5, 12, "Cedula"),
        telefono=digitos("telefono", 7, 13, "Telefono"),
        vereda=vereda,
        cultivos=cultivos,
        area_sembrada_ha=area,
        quiere_visita=quiere if isinstance(quiere, bool) else None,
        por_confirmar=dudas,
    )


async def extraer(
    settings: Settings, transcripcion: str, veredas: list[str]
) -> DatosAsistencia:
    if not settings.anthropic_api_key:
        raise HTTPException(status_code=500, detail="Falta ANTHROPIC_API_KEY en el backend.")

    prompt = (
        f"VEREDAS ({len(veredas)}): {', '.join(veredas) or '(ninguna)'}\n"
        f"CULTIVOS: {', '.join(CULTIVOS)}\n\n"
        f"TRANSCRIPCION DE LA NOTA DE VOZ:\n{transcripcion}"
    )
    client = AsyncAnthropic(api_key=settings.anthropic_api_key)
    try:
        respuesta = await client.messages.create(
            model=settings.claude_model,
            max_tokens=2000,
            system=SYSTEM,
            tools=[
                {
                    "name": "registrar_asistencia",
                    "description": "Registra los datos que la persona dijo en la nota.",
                    "input_schema": _ESQUEMA,
                }
            ],
            tool_choice={"type": "tool", "name": "registrar_asistencia"},
            messages=[{"role": "user", "content": prompt}],
        )
    except UPSTREAM_EXCEPTIONS as exc:
        raise upstream_error("Claude", exc) from exc

    bloque = next(
        (b for b in respuesta.content if getattr(b, "type", None) == "tool_use"), None
    )
    if bloque is None:
        raise HTTPException(
            status_code=502, detail="Claude no devolvio los datos de la asistencia."
        )
    return validar(bloque.input, veredas)
