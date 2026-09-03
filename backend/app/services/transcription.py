"""Transcripcion diarizada con ElevenLabs Scribe.

Whisper quedo fuera por una razon concreta, no por preferencia: devuelve un
bloque de texto sin saber quien habla. Todo el modelo de datos depende de lo
contrario - `Hallazgos.Hablante` existe para poder aplicar la regla de que lo
dicho por el visitador nunca queda Confirmado, y esa regla no es verificable
si la transcripcion no separa las voces.

Se usa httpx directo en vez del SDK de ElevenLabs: la peticion es un POST
multipart con cinco campos, y una dependencia menos es una version menos que
mantener alineada.
"""

import httpx
from fastapi import HTTPException

from ..config import Settings
from ..schemas import HablanteStats, TranscriptionResult, Turno
from .errors import upstream_error
from . import vocabulario

_MB = 1024 * 1024
_URL = "https://api.elevenlabs.io/v1/speech-to-text"

# Una visita de 30 min pesa ~7 MB en AAC mono a 32 kbps. El limite de
# ElevenLabs para audio pregrabado es de 3 GB, asi que aca el tope solo
# protege contra una subida absurda por error.
_TIMEOUT = httpx.Timeout(connect=10.0, read=300.0, write=300.0, pool=10.0)

# Topes del proveedor para el refuerzo de vocabulario.
_MAX_KEYTERMS = 1000
_MAX_LARGO_KEYTERM = 50

# Silencio a partir del cual se abre un turno nuevo aunque siga hablando la
# misma voz. Deepgram cerraba los turnos solo; ElevenLabs entrega palabras
# sueltas, asi que si no se corta aca, una respuesta dada media hora despues
# queda pegada a la anterior y la cita apunta al segundo equivocado.
_PAUSA_NUEVO_TURNO = 2.0


def _form(settings: Settings, terminos: list[str], diarizar: bool) -> dict[str, object]:
    """Arma los campos del multipart.

    `keyterms` va como valor de lista: httpx lo emite como campo repetido, que
    es como el proveedor espera una lista en multipart.
    """
    form: dict[str, object] = {
        "model_id": settings.elevenlabs_model,
        "language_code": settings.elevenlabs_language,
        # Sin marcas por palabra no hay con que reconstruir los turnos:
        # ElevenLabs devuelve palabras sueltas, no turnos ya cerrados.
        "timestamps_granularity": "word",
        # Los eventos de audio ("(risas)") no traen hablante y ensucian las
        # citas que se le muestran al visitador para que las confirme.
        "tag_audio_events": "false",
        "diarize": "true" if diarizar else "false",
    }

    # `vocabulario` ya pone lo de la visita primero, asi que recortar por el
    # final descarta lo generico, que es lo que menos duele perder.
    utiles = [t for t in terminos if len(t) < _MAX_LARGO_KEYTERM]
    if utiles:
        form["keyterms"] = utiles[:_MAX_KEYTERMS]

    # Maximo de voces esperadas. Sin valor lo decide el proveedor, que es lo
    # que conviene: fijar 2 fusionaria dos personas en una sola voz si en la
    # visita habla un tercero (un hijo, un vecino), y una voz fusionada le
    # atribuye al agricultor cosas que dijo el visitador.
    if settings.elevenlabs_num_speakers:
        form["num_speakers"] = str(settings.elevenlabs_num_speakers)

    return form


def _cerrar(actual: dict) -> Turno:
    return Turno(
        hablante=actual["hablante"],
        inicio=actual["inicio"],
        fin=actual["fin"],
        texto=" ".join(actual["palabras"]).strip(),
    )


def _turnos_desde_palabras(data: dict) -> list[Turno]:
    """Junta las palabras consecutivas de una misma voz en un turno.

    ElevenLabs no agrupa: devuelve la lista de palabras con su hablante. Hay
    que cerrar los turnos aca porque perder los turnos significa perder las
    citas, y perder las citas deja todos los hallazgos en Pendiente.

    `speaker_id` llega como texto ("speaker_0", a veces "agent"). Se traduce a
    entero por orden de aparicion en vez de sacarle el numero al nombre: asi
    no depende de como el proveedor bautice las voces, y el resto del sistema
    sigue numerando desde 0.
    """
    palabras = data.get("words", []) or []

    # Sin diarizacion el proveedor manda `speaker_id` en null. Se devuelve
    # vacio en vez de meterlo todo en un turno unico: eso aparentaria un turno
    # medido que nadie midio, y las citas colgarian de una marca inventada.
    if not any(w.get("speaker_id") for w in palabras):
        return []

    indice: dict[str, int] = {}
    turnos: list[Turno] = []
    actual: dict | None = None

    for w in palabras:
        # `spacing` son los espacios entre palabras y `audio_event` el ruido
        # de fondo: ninguno de los dos es habla de nadie.
        if (w.get("type") or "word") != "word":
            continue
        texto = (w.get("text") or "").strip()
        if not texto:
            continue

        hablante = indice.setdefault(w.get("speaker_id") or "speaker_0", len(indice))
        inicio = float(w.get("start") or 0.0)
        fin = float(w["end"]) if w.get("end") is not None else inicio

        corta = (
            actual is None
            or actual["hablante"] != hablante
            or inicio - actual["fin"] > _PAUSA_NUEVO_TURNO
        )
        if corta:
            if actual is not None:
                turnos.append(_cerrar(actual))
            actual = {
                "hablante": hablante,
                "inicio": inicio,
                "fin": fin,
                "palabras": [texto],
            }
        else:
            actual["fin"] = fin
            actual["palabras"].append(texto)

    if actual is not None:
        turnos.append(_cerrar(actual))
    return turnos


def _duracion(data: dict) -> float | None:
    """ElevenLabs no devuelve la duracion del audio.

    El fin de la ultima palabra es lo mas cercano que hay. Queda corto por el
    silencio del final, y para lo que se usa (mostrarle al visitador cuanto
    duro el tramo) eso no cambia nada.
    """
    fines = [
        float(w["end"]) for w in data.get("words", []) or [] if w.get("end") is not None
    ]
    return round(max(fines), 1) if fines else None


def _mmss(segundos: float) -> str:
    total = int(segundos)
    return f"{total // 60:02d}:{total % 60:02d}"


def formatear_con_marcas(turnos: list[Turno]) -> str:
    """Transcripcion legible, un turno por linea, con el segundo al frente.

    El formato es el contrato con el Dia 5: el modelo de extraccion lee esto y
    tiene que poder devolver el segundo exacto de la cita. Cambiar el formato
    aqui obliga a revisar el prompt.
    """
    return "\n".join(
        f"[{_mmss(t.inicio)}] Hablante {t.hablante + 1}: {t.texto}" for t in turnos
    )


def estadisticas(turnos: list[Turno]) -> list[HablanteStats]:
    acumulado: dict[int, dict[str, float]] = {}
    for t in turnos:
        d = acumulado.setdefault(t.hablante, {"segundos": 0.0, "turnos": 0})
        d["segundos"] += max(0.0, t.fin - t.inicio)
        d["turnos"] += 1

    return [
        HablanteStats(hablante=h, segundos=round(d["segundos"], 1), turnos=int(d["turnos"]))
        for h, d in sorted(acumulado.items())
    ]


def sugerir_visitador(stats: list[HablanteStats]) -> tuple[int | None, str]:
    """Propone cual de las voces es el visitador, con su razon en una linea.

    Heuristica: en una visita que salio bien, el agricultor habla mas que el
    visitador. Eso es justamente lo que el producto busca — una conversacion,
    no un interrogatorio. Asi que la voz con menos tiempo de habla es
    probablemente la del visitador.

    Es una sugerencia y se dice que lo es. Si la visita salio mal y el
    visitador hablo mas, la heuristica se equivoca; por eso el visitador la
    confirma de un toque en la pantalla de validacion en vez de que el sistema
    decida solo. Equivocarse aca invierte la regla dura: degradaria el dato del
    agricultor y avalaria el del visitador.
    """
    if len(stats) < 2:
        return None, (
            "Solo se detecto una voz: no se puede distinguir al visitador del agricultor."
        )

    ordenados = sorted(stats, key=lambda s: s.segundos)
    menor, siguiente = ordenados[0], ordenados[1]

    total = sum(s.segundos for s in stats) or 1.0
    pct_menor = 100 * menor.segundos / total

    # Si las dos voces hablaron practicamente lo mismo, la heuristica no
    # distingue nada y decir un numero seria fingir precision.
    if siguiente.segundos > 0 and menor.segundos / siguiente.segundos > 0.85:
        return None, (
            f"Las dos voces hablaron parecido ({pct_menor:.0f}% y "
            f"{100 - pct_menor:.0f}%): hay que indicar a mano quien es el visitador."
        )

    return menor.hablante, (
        f"Hablante {menor.hablante + 1} hablo el {pct_menor:.0f}% del tiempo. "
        "En una visita que sale bien, el agricultor habla mas que el visitador."
    )



async def transcribe(
    settings: Settings,
    filename: str,
    audio: bytes,
    language: str | None = None,
    diarizar: bool = True,
    terminos_extra: list[str] | None = None,
) -> TranscriptionResult:
    if not audio:
        raise HTTPException(status_code=400, detail="El audio llego vacio.")
    if len(audio) > settings.max_audio_bytes:
        raise HTTPException(
            status_code=413,
            detail=(
                f"El audio pesa {len(audio) / _MB:.1f} MB y el limite configurado es "
                f"{settings.max_audio_bytes / _MB:.0f} MB. La app graba en tramos de "
                "5 minutos (~1,2 MB), asi que un archivo mas grande que esto es "
                "un tramo que no se cerro cuando debia."
            ),
        )
    if not settings.elevenlabs_api_key:
        raise HTTPException(
            status_code=500, detail="Falta ELEVENLABS_API_KEY en el backend."
        )

    terminos = vocabulario.construir(terminos_extra)
    form = _form(settings, terminos, diarizar)
    if language:
        form["language_code"] = language

    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            response = await client.post(
                _URL,
                headers={"xi-api-key": settings.elevenlabs_api_key},
                data=form,
                files={"file": (filename, audio, "audio/mp4")},
            )
            response.raise_for_status()
            data = response.json()
    except httpx.HTTPStatusError as exc:
        detalle = exc.response.text[:400]
        raise HTTPException(
            status_code=502,
            detail=f"ElevenLabs respondio {exc.response.status_code}: {detalle}",
        ) from exc
    except httpx.HTTPError as exc:
        raise upstream_error("ElevenLabs", exc) from exc

    return construir_resultado(data, settings.elevenlabs_model)


def construir_resultado(data: dict, motor: str) -> TranscriptionResult:
    """Convierte la respuesta cruda de ElevenLabs en el resultado del backend.

    Separado del POST a proposito: asi se puede probar contra una respuesta
    guardada, sin red ni credenciales.
    """
    texto = (data.get("text") or "").strip()

    turnos = _turnos_desde_palabras(data)
    stats = estadisticas(turnos)
    sugerido, razon = sugerir_visitador(stats)

    # Si no hubo diarizacion no hay turnos, y entonces el texto plano es todo
    # lo que hay. Se devuelve vacio en vez de fabricar un turno unico que
    # aparentaria una marca de tiempo que nadie midio.
    con_marcas = formatear_con_marcas(turnos) if turnos else ""

    return TranscriptionResult(
        text=texto or " ".join(t.texto for t in turnos).strip(),
        language=data.get("language_code") or None,
        duration_seconds=_duracion(data),
        motor=motor,
        turnos=turnos,
        text_with_timestamps=con_marcas,
        hablantes=stats,
        hablante_visitador_sugerido=sugerido,
        razon_sugerencia=razon,
    )
