import json
from types import SimpleNamespace

import anthropic
import httpx
import openai
import pytest
import respx
from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import app
from app.services import report as report_service
from app.services import whisper as whisper_service

REPORT_JSON = {
    "resumen_ejecutivo": "Se reviso el avance del lote 4.",
    "temas": [{"titulo": "Lote 4", "detalle": "Avance parcial de siembra."}],
    "acuerdos": ["Revisar el lote 4 la proxima semana"],
    "pendientes": [
        {"tarea": "Enviar el acta", "responsable": "Beto", "fecha_limite": ""}
    ],
    "riesgos": [],
}


class _FakeAnthropic:
    """Devuelve siempre el mismo informe, sin salir a la red."""

    def __init__(self, stop_reason="end_turn", text=None, **_):
        payload = json.dumps(REPORT_JSON) if text is None else text
        self.beta = SimpleNamespace(
            messages=SimpleNamespace(
                create=self._make_create(stop_reason, payload),
            )
        )
        self.calls: list[dict] = []

    def _make_create(self, stop_reason, payload):
        async def create(**kwargs):
            self.calls.append(kwargs)
            return SimpleNamespace(
                stop_reason=stop_reason,
                content=[SimpleNamespace(type="text", text=payload)],
            )

        return create


class _FakeOpenAI:
    """Devuelve siempre la misma respuesta de Whisper, sin salir a la red.

    Se fakea el SDK y no el HTTP como con ElevenLabs porque el cliente de
    OpenAI trae su propio transporte y respx no lo intercepta.
    """

    def __init__(self, payload=None, error=None, **_):
        self.calls: list[dict] = []

        async def create(**kwargs):
            self.calls.append(kwargs)
            if error is not None:
                raise error
            return SimpleNamespace(model_dump=lambda: payload or WHISPER_JSON)

        self.audio = SimpleNamespace(transcriptions=SimpleNamespace(create=create))


def _palabra(texto, inicio, fin, hablante):
    return {
        "text": texto,
        "type": "word",
        "start": inicio,
        "end": fin,
        "speaker_id": f"speaker_{hablante}",
    }


# ElevenLabs devuelve palabras sueltas, no turnos ya cerrados: agruparlas es
# trabajo del backend, y de ahi salen las citas.
STT_JSON = {
    "language_code": "es",
    "language_probability": 0.98,
    "text": "Buenos dias. Mucho gusto, Pedro.",
    "words": [
        _palabra("Buenos", 0.4, 1.2, 0),
        _palabra("dias.", 1.3, 3.0, 0),
        _palabra("Mucho", 3.5, 4.1, 1),
        _palabra("gusto,", 4.2, 5.0, 1),
        _palabra("Pedro.", 5.1, 18.0, 1),
    ],
}

STT_URL = "https://api.elevenlabs.io/v1/speech-to-text"
WHISPER_URL = "https://api.openai.com/v1/audio/transcriptions"

# Respaldo: `verbose_json` de whisper-1, con la duracion real y los segmentos
# con su segundo, y sin nada sobre quien habla.
WHISPER_JSON = {
    "task": "transcribe",
    "language": "spanish",
    "duration": 18.4,
    "text": "Buenos dias. Mucho gusto, Pedro.",
    "segments": [
        {"id": 0, "start": 0.0, "end": 3.0, "text": " Buenos dias."},
        {"id": 1, "start": 3.5, "end": 18.0, "text": " Mucho gusto, Pedro."},
    ],
}


def _campos(request) -> dict[str, list[str]]:
    """Desarma el multipart para poder afirmar sobre los campos enviados.

    Los parametros van en el cuerpo multipart, no en la query, asi que para
    afirmar sobre ellos hay que abrirlo.
    """
    frontera = request.headers["content-type"].split("boundary=")[1]
    campos: dict[str, list[str]] = {}

    for parte in request.content.decode("utf-8", "replace").split("--" + frontera):
        if "\r\n\r\n" not in parte:
            continue
        cabeceras, _, valor = parte.partition("\r\n\r\n")
        if 'name="' not in cabeceras or "filename=" in cabeceras:
            continue
        nombre = cabeceras.split('name="', 1)[1].split('"', 1)[0]
        campos.setdefault(nombre, []).append(valor.rsplit("\r\n", 1)[0])

    return campos


# --- autenticacion ---------------------------------------------------------


def test_health_no_pide_llave(client):
    assert client.get("/health").json() == {"status": "ok"}


@pytest.mark.parametrize(
    "path", ["/v1/transcripciones", "/v1/reports", "/v1/meetings"]
)
def test_sin_api_key_devuelve_401(client, path):
    assert client.post(path, json={}).status_code == 401


def test_api_key_incorrecta_devuelve_401(client, meeting_payload):
    response = client.post(
        "/v1/reports", headers={"X-API-Key": "otra"}, json=meeting_payload
    )
    assert response.status_code == 401


# --- transcripcion diarizada -----------------------------------------------


@respx.mock
def test_transcribe_devuelve_turnos_con_hablante_y_segundo(client, auth):
    ruta = respx.post(STT_URL).mock(
        return_value=httpx.Response(200, json=STT_JSON)
    )

    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"audio-falso", "audio/m4a")},
        data={"terminos": "Pedro Rodriguez,Guaicaramo"},
    )

    assert response.status_code == 200
    body = response.json()
    # ElevenLabs no devuelve la duracion: sale del fin de la ultima palabra.
    assert body["duration_seconds"] == 18.0
    assert body["motor"] == "scribe_v2"
    assert len(body["turnos"]) == 2
    assert body["turnos"][1] == {
        "hablante": 1,
        "inicio": 3.5,
        "fin": 18.0,
        "texto": "Mucho gusto, Pedro.",
    }
    # Es lo que va a `Grabaciones.Transcripcion con marcas de tiempo`.
    assert body["text_with_timestamps"].startswith("[00:00] Hablante 1: Buenos dias.")

    # El que hablo menos se propone como visitador, y se dice por que.
    assert body["hablante_visitador_sugerido"] == 0
    assert body["razon_sugerencia"]

    # Lo especifico de la visita tiene que llegar al proveedor, y primero.
    enviados = _campos(ruta.calls.last.request)["keyterms"]
    assert enviados[:2] == ["Pedro Rodriguez", "Guaicaramo"]
    assert "Guaicaramo" in enviados


@respx.mock
def test_pide_diarizacion_por_defecto(client, auth):
    ruta = respx.post(STT_URL).mock(
        return_value=httpx.Response(200, json=STT_JSON)
    )

    client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"audio", "audio/m4a")},
    )

    campos = _campos(ruta.calls.last.request)
    assert campos["diarize"] == ["true"]
    # Sin marcas por palabra no hay como reconstruir los turnos.
    assert campos["timestamps_granularity"] == ["word"]
    assert campos["language_code"] == ["es"]
    assert campos["model_id"] == ["scribe_v2"]


@respx.mock
def test_la_llave_va_en_el_header_no_en_la_url(client, auth):
    """Una llave en la query queda en los logs del proveedor y del proxy."""
    ruta = respx.post(STT_URL).mock(
        return_value=httpx.Response(200, json=STT_JSON)
    )

    client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"audio", "audio/m4a")},
    )

    peticion = ruta.calls.last.request
    assert peticion.headers["xi-api-key"] == "eleven-test"
    assert "eleven-test" not in str(peticion.url)


def test_audio_vacio_devuelve_400(client, auth):
    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"", "audio/m4a")},
    )
    assert response.status_code == 400


def test_audio_gigante_devuelve_413(client, auth):
    """El tope existe para que un tramo que no se cerro falle con un mensaje
    que se entienda, y no con el 413 pelado del host."""
    tope = get_settings().max_audio_bytes
    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"x" * (tope + 1), "audio/m4a")},
    )
    assert response.status_code == 413
    assert f"{tope / (1024 * 1024):.0f} MB" in response.json()["detail"]


@respx.mock
def test_el_tope_deja_pasar_un_tramo_normal(client, auth):
    """1,2 MB es lo que pesa un tramo real: AAC-LC a 32 kbps por 5 minutos.

    Si alguien baja el tope para caber en algun host, este test avisa antes de
    que la app deje de poder subir audio en el campo.
    """
    respx.post(STT_URL).mock(return_value=httpx.Response(200, json=STT_JSON))

    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"x" * (1300 * 1024), "audio/m4a")},
    )
    assert response.status_code == 200


def test_el_tope_cabe_en_el_limite_de_cuerpo_de_vercel():
    """Vercel corta el cuerpo de una peticion en 4,5 MB y no se configura. Si
    el tope de la app lo supera, el visitador recibiria un 413 sin explicacion
    en vez del mensaje de arriba."""
    assert get_settings().max_audio_bytes <= 4.5 * 1024 * 1024


# --- informe ---------------------------------------------------------------


def test_informe_estructurado(client, auth, meeting_payload, monkeypatch):
    fake = _FakeAnthropic()
    monkeypatch.setattr(report_service, "AsyncAnthropic", lambda **_: fake)

    response = client.post("/v1/reports", headers=auth, json=meeting_payload)

    assert response.status_code == 200
    body = response.json()
    assert body["resumen_ejecutivo"] == REPORT_JSON["resumen_ejecutivo"]
    assert body["pendientes"][0]["responsable"] == "Beto"

    # El prompt debe llevar transcripcion y respuestas del cuestionario.
    prompt = fake.calls[0]["messages"][0]["content"]
    assert "lote 4" in prompt
    assert "Objetivo de la reunion" in prompt
    assert fake.calls[0]["output_config"]["format"]["type"] == "json_schema"


def test_informe_sin_material_devuelve_400(client, auth, meeting_payload):
    meeting_payload["transcript"] = ""
    meeting_payload["answers"] = []
    response = client.post("/v1/reports", headers=auth, json=meeting_payload)
    assert response.status_code == 400


def test_rechazo_del_modelo_devuelve_502(client, auth, meeting_payload, monkeypatch):
    fake = _FakeAnthropic(stop_reason="refusal", text="")
    monkeypatch.setattr(report_service, "AsyncAnthropic", lambda **_: fake)

    response = client.post("/v1/reports", headers=auth, json=meeting_payload)
    assert response.status_code == 502


# --- Airtable --------------------------------------------------------------


@respx.mock
def test_publica_en_airtable(client, auth, meeting_payload):
    route = respx.post("https://api.airtable.com/v0/appTEST/Reuniones").mock(
        return_value=httpx.Response(200, json={"id": "recABC123"})
    )

    payload = {**meeting_payload, "report": REPORT_JSON}
    response = client.post("/v1/meetings", headers=auth, json=payload)

    assert response.status_code == 200
    assert response.json()["record_id"] == "recABC123"
    assert "recABC123" in response.json()["url"]

    fields = json.loads(route.calls[0].request.content)["fields"]
    assert fields["Titulo"] == "Comite semanal"
    assert fields["Duracion (min)"] == 30.5
    assert fields["Participantes"] == "Ana, Beto"
    assert "Enviar el acta" in fields["Informe"]
    assert "[00:42]" in fields["Respuestas"]
    assert fields["Estado"] == "Procesada"


@respx.mock
def test_error_de_airtable_se_propaga_como_502(client, auth, meeting_payload):
    respx.post("https://api.airtable.com/v0/appTEST/Reuniones").mock(
        return_value=httpx.Response(422, json={"error": "UNKNOWN_FIELD_NAME"})
    )

    payload = {**meeting_payload, "report": REPORT_JSON}
    response = client.post("/v1/meetings", headers=auth, json=payload)

    assert response.status_code == 502
    assert "UNKNOWN_FIELD_NAME" in response.json()["detail"]


# --- fallas de los proveedores ---------------------------------------------


def _status_error(cls, status: int, message: str, host: str):
    request = httpx.Request("POST", host)
    response = httpx.Response(status, request=request, json={"error": message})
    return cls(message, response=response, body=None)


def _raising_anthropic(exc):
    async def create(**_):
        raise exc

    return lambda **_: SimpleNamespace(
        beta=SimpleNamespace(messages=SimpleNamespace(create=create))
    )


@respx.mock
def test_si_elevenlabs_falla_se_transcribe_con_whisper(client, auth, monkeypatch):
    """Una visita ya hecha no se puede repetir.

    Si el motor diarizado esta caido, el tramo no se queda sin transcribir: se
    manda a Whisper, que devuelve el texto con marcas de tiempo reales. Lo que
    no devuelve es el hablante, y eso queda dicho en vez de fingido.
    """
    respx.post(STT_URL).mock(
        return_value=httpx.Response(500, json={"detail": "server error"})
    )
    whisper = _FakeOpenAI()
    monkeypatch.setattr(whisper_service, "AsyncOpenAI", lambda **_: whisper)

    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"audio", "audio/m4a")},
        data={"terminos": "Pedro Rodriguez"},
    )

    assert response.status_code == 200
    body = response.json()

    # El motor dice que fue el respaldo: es lo que la app guarda en
    # `Grabaciones.Motor` y lo que explica por que no hay hablante.
    assert body["motor"].startswith("whisper-1")
    assert "sin diarizacion" in body["motor"]

    # Las citas siguen teniendo a que segundo apuntar.
    assert body["turnos"][1]["inicio"] == 3.5
    assert body["turnos"][1]["texto"] == "Mucho gusto, Pedro."
    assert body["text_with_timestamps"].startswith("[00:00] Hablante 1: Buenos dias.")

    # Whisper si mide la duracion del audio completo.
    assert body["duration_seconds"] == 18.4

    # Una sola voz, ningun visitador propuesto, y el motivo dicho: asi la
    # extraccion marca cada hallazgo como "no identificado" en vez de
    # atribuirselo al agricultor.
    assert len(body["hablantes"]) == 1
    assert body["hablante_visitador_sugerido"] is None
    assert "Whisper" in body["razon_sugerencia"]

    # El vocabulario de la visita tambien va al respaldo: es el unico refuerzo
    # que Whisper acepta, y va primero lo especifico.
    assert whisper.calls[0]["prompt"].startswith("Pedro Rodriguez")
    # Sin `verbose_json` no hay segmentos con su segundo, y el respaldo pierde
    # justo lo que lo hace util.
    assert whisper.calls[0]["response_format"] == "verbose_json"


@respx.mock
def test_una_llave_invalida_de_elevenlabs_tambien_cae_al_respaldo(
    client, auth, monkeypatch
):
    """Un 401 es configuracion nuestra, pero el visitador no puede arreglarla
    desde el campo: primero se salva la transcripcion, el 401 queda en el log."""
    respx.post(STT_URL).mock(
        return_value=httpx.Response(401, json={"detail": {"message": "Invalid API key."}})
    )
    monkeypatch.setattr(whisper_service, "AsyncOpenAI", lambda **_: _FakeOpenAI())

    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"audio", "audio/m4a")},
    )

    assert response.status_code == 200
    assert response.json()["motor"].startswith("whisper-1")


@respx.mock
def test_timeout_de_elevenlabs_cae_al_respaldo(client, auth, monkeypatch):
    respx.post(STT_URL).mock(side_effect=httpx.ReadTimeout("tardo demasiado"))
    monkeypatch.setattr(whisper_service, "AsyncOpenAI", lambda **_: _FakeOpenAI())

    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"audio", "audio/m4a")},
    )

    assert response.status_code == 200
    assert response.json()["turnos"]


@respx.mock
def test_si_los_dos_motores_fallan_el_error_nombra_a_los_dos(
    client, auth, monkeypatch
):
    """El error tiene que dejar ver la falla de ElevenLabs.

    El respaldo tapa el hueco; lo que hay que arreglar es el motor principal, y
    si el mensaje solo hablara de Whisper nadie iria a mirar ahi.
    """
    respx.post(STT_URL).mock(side_effect=httpx.ConnectError("sin red"))
    caido = _FakeOpenAI(
        error=openai.RateLimitError(
            "slow down",
            response=httpx.Response(429, request=httpx.Request("POST", WHISPER_URL)),
            body=None,
        )
    )
    monkeypatch.setattr(whisper_service, "AsyncOpenAI", lambda **_: caido)

    response = client.post(
        "/v1/transcripciones",
        headers=auth,
        files={"file": ("tramo-1.m4a", b"audio", "audio/m4a")},
    )

    assert response.status_code == 502
    detalle = response.json()["detail"]
    assert "ElevenLabs" in detalle
    assert "Whisper" in detalle
