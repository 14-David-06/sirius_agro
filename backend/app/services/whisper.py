"""Respaldo de transcripcion con Whisper (OpenAI) cuando ElevenLabs no responde.

Whisper no es el motor elegido y no lo es por una razon concreta: devuelve el
texto sin saber quien habla. `Hallazgos.Hablante` existe para poder aplicar la
regla de que lo dicho por el visitador nunca queda Confirmado, y esa regla no
es verificable sin voces separadas.

Pero una visita ya hecha no se puede repetir. El visitador manejo dos horas
hasta la finca, el audio ya esta grabado y si el unico motor esta caido el
tramo se queda sin transcribir hasta que alguien se acuerde de reintentarlo.
Frente a eso, un texto con marcas de tiempo reales y sin hablante es mucho
mejor que nada: las citas siguen apuntando al segundo exacto del audio, que es
lo que permite que un hallazgo se pueda verificar escuchandolo.

Lo que NO hace este respaldo es fingir la diarizacion. Los turnos salen todos
como una sola voz, `hablante_visitador_sugerido` queda en None y por eso
`extraccion._hablante_a_texto` marca cada hallazgo como "no identificado". La
regla 1 no se aplica porque no hay con que aplicarla, y eso queda dicho en
`razon_sugerencia` y en `motor` en vez de quedar escondido.
"""

from openai import AsyncOpenAI

from ..config import Settings
from ..schemas import Turno
from .errors import UPSTREAM_EXCEPTIONS, upstream_error

# `verbose_json` es lo unico que trae los segmentos con su segundo, y de los
# modelos de audio de OpenAI solo whisper-1 lo soporta: los `gpt-4o-transcribe`
# devuelven texto plano. Cambiar WHISPER_MODEL por uno de esos deja el respaldo
# sin marcas de tiempo, que es justamente lo que lo hace util.
_FORMATO = "verbose_json"

_TIMEOUT = 300.0

# El prompt de Whisper es la unica via para reforzar vocabulario (no hay
# `keyterms`) y el proveedor lo corta a 224 tokens. Se recorta por caracteres
# porque es lo que se puede medir sin tokenizar; el vocabulario ya viene con lo
# especifico de la visita primero, asi que lo que se pierde es lo generico.
_MAX_PROMPT = 600

# Se dice en el resultado, no solo en los logs: es lo que la app guarda en
# `Grabaciones.Motor` y lo que explica por que ningun hallazgo tiene hablante.
MOTOR_SUFIJO = " (respaldo, sin diarizacion)"

RAZON = (
    "Se transcribio con Whisper porque ElevenLabs no respondio. Whisper no "
    "separa voces: no se puede saber que dijo el visitador y que el agricultor, "
    "asi que ningun hallazgo queda atribuido a nadie."
)


def _pista(terminos: list[str]) -> str:
    """Arma el prompt de refuerzo sin pasarse del tope del proveedor."""
    pista = ""
    for termino in terminos:
        candidato = f"{pista}, {termino}" if pista else termino
        if len(candidato) > _MAX_PROMPT:
            break
        pista = candidato
    return pista


def turnos(data: dict) -> list[Turno]:
    """Un turno por segmento de Whisper, todos como una sola voz.

    Los segmentos NO se fusionan aunque vengan pegados, al contrario de lo que
    hace `transcription._turnos_desde_palabras` con las palabras de ElevenLabs.
    Ahi la fusion es lo correcto: hay hablante, y cortar por voz reconstruye
    los turnos reales. Aca no hay voz que cambie, asi que fusionar por
    proximidad juntaria todo el tramo en un turno unico con una sola marca al
    frente — y una marca cada cinco minutos no sirve para saltar al audio.

    El hablante fijo en 0 es lo que deja `hablante_visitador_sugerido` en None,
    y eso es lo que hace que la extraccion marque cada hallazgo como
    "no identificado" en vez de atribuirselo al agricultor.

    Separado del POST a proposito: se puede probar contra una respuesta
    guardada, sin red ni credenciales.
    """
    salida: list[Turno] = []
    for segmento in data.get("segments") or []:
        texto = (segmento.get("text") or "").strip()
        if not texto:
            continue
        inicio = float(segmento.get("start") or 0.0)
        fin = segmento.get("end")
        salida.append(
            Turno(
                hablante=0,
                inicio=inicio,
                fin=float(fin) if fin is not None else inicio,
                texto=texto,
            )
        )
    return salida


def normalizar(data: dict) -> dict:
    """Deja la respuesta de Whisper con las llaves del formato interno.

    Los turnos van aparte (ver `turnos`): aca solo queda lo que
    `transcription.construir_resultado` lee del diccionario.
    """
    return {
        "text": (data.get("text") or "").strip(),
        # Whisper devuelve el nombre del idioma ("spanish"), no el codigo ISO
        # que espera el resto del sistema. Se deja que lo ponga quien llama,
        # que es el que sabe con que codigo se pidio.
        "language_code": None,
        # Whisper si mide la duracion del audio completo, incluido el silencio
        # del final que el fin de la ultima palabra se come.
        "duration": data.get("duration"),
    }


async def transcribir(
    settings: Settings,
    filename: str,
    audio: bytes,
    language: str | None,
    terminos: list[str],
) -> tuple[dict, list[Turno], str]:
    """Devuelve la respuesta normalizada, sus turnos y el motor que los produjo."""
    if not settings.openai_api_key:
        raise RuntimeError("falta OPENAI_API_KEY en el backend")

    cliente = AsyncOpenAI(api_key=settings.openai_api_key, timeout=_TIMEOUT)

    # `language` y `prompt` se pasan solo si hay algo que pasar: el SDK
    # distingue "no lo mandes" de "mandalo vacio", y un idioma vacio le dice a
    # Whisper que lo detecte solo, que con ruido de campo es peor que decirselo.
    opciones: dict[str, object] = {}
    if language:
        opciones["language"] = language
    pista = _pista(terminos)
    if pista:
        opciones["prompt"] = pista

    try:
        respuesta = await cliente.audio.transcriptions.create(
            model=settings.whisper_model,
            file=(filename, audio, "audio/mp4"),
            response_format=_FORMATO,
            # Sin esto Whisper improvisa cuando el audio esta sucio, y en una
            # grabacion de campo eso son frases que nadie dijo entrando como
            # citas textuales.
            temperature=0.0,
            **opciones,
        )
    except UPSTREAM_EXCEPTIONS as exc:
        raise upstream_error("Whisper", exc) from exc

    data = respuesta.model_dump() if hasattr(respuesta, "model_dump") else dict(respuesta)
    normalizada = normalizar(data)
    if language:
        normalizada["language_code"] = language

    return normalizada, turnos(data), f"{settings.whisper_model}{MOTOR_SUFIJO}"
