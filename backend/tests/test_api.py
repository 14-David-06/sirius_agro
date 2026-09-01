import json
from types import SimpleNamespace

import anthropic
import httpx
import openai
import pytest
import respx
from fastapi.testclient import TestClient

from app.main import app
from app.services import report as report_service
from app.services import transcription as transcription_service

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
    def __init__(self, **_):
        self.audio = SimpleNamespace(
            transcriptions=SimpleNamespace(create=self._create)
        )

    async def _create(self, **kwargs):
        return SimpleNamespace(
            text="Ana propuso revisar el lote 4.",
            language="spanish",
            duration=1830.0,
        )


# --- autenticacion ---------------------------------------------------------


def test_health_no_pide_llave(client):
    assert client.get("/health").json() == {"status": "ok"}


@pytest.mark.parametrize(
    "path", ["/v1/transcriptions", "/v1/reports", "/v1/meetings"]
)
def test_sin_api_key_devuelve_401(client, path):
    assert client.post(path, json={}).status_code == 401


def test_api_key_incorrecta_devuelve_401(client, meeting_payload):
    response = client.post(
        "/v1/reports", headers={"X-API-Key": "otra"}, json=meeting_payload
    )
    assert response.status_code == 401


# --- transcripcion ---------------------------------------------------------


def test_transcribe_devuelve_texto(client, auth, monkeypatch):
    monkeypatch.setattr(transcription_service, "AsyncOpenAI", _FakeOpenAI)

    response = client.post(
        "/v1/transcriptions",
        headers=auth,
        files={"file": ("reunion.m4a", b"audio-falso", "audio/m4a")},
        data={"language": "es"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["text"].startswith("Ana propuso")
    assert body["duration_seconds"] == 1830.0


def test_audio_vacio_devuelve_400(client, auth):
    response = client.post(
        "/v1/transcriptions",
        headers=auth,
        files={"file": ("reunion.m4a", b"", "audio/m4a")},
    )
    assert response.status_code == 400


def test_audio_gigante_devuelve_413(client, auth):
    response = client.post(
        "/v1/transcriptions",
        headers=auth,
        files={"file": ("reunion.m4a", b"x" * (26 * 1024 * 1024), "audio/m4a")},
    )
    assert response.status_code == 413
    assert "25 MB" in response.json()["detail"]


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


def _raising_openai(exc):
    async def create(**_):
        raise exc

    return lambda **_: SimpleNamespace(
        audio=SimpleNamespace(transcriptions=SimpleNamespace(create=create))
    )


def _raising_anthropic(exc):
    async def create(**_):
        raise exc

    return lambda **_: SimpleNamespace(
        beta=SimpleNamespace(messages=SimpleNamespace(create=create))
    )


def test_llave_de_whisper_invalida_devuelve_500_explicado(client, auth, monkeypatch):
    exc = _status_error(
        openai.AuthenticationError, 401, "API key is invalid.", "https://api.openai.com/v1"
    )
    monkeypatch.setattr(transcription_service, "AsyncOpenAI", _raising_openai(exc))

    response = client.post(
        "/v1/transcriptions",
        headers=auth,
        files={"file": ("reunion.m4a", b"audio", "audio/m4a")},
        data={"language": "es"},
    )

    assert response.status_code == 500
    detail = response.json()["detail"]
    assert "Whisper" in detail and "credenciales" in detail


def test_timeout_de_whisper_devuelve_504(client, auth, monkeypatch):
    exc = openai.APITimeoutError(request=httpx.Request("POST", "https://api.openai.com/v1"))
    monkeypatch.setattr(transcription_service, "AsyncOpenAI", _raising_openai(exc))

    response = client.post(
        "/v1/transcriptions",
        headers=auth,
        files={"file": ("reunion.m4a", b"audio", "audio/m4a")},
        data={"language": "es"},
    )

    assert response.status_code == 504
    assert "Whisper" in response.json()["detail"]


def test_rate_limit_de_claude_devuelve_429(client, auth, meeting_payload, monkeypatch):
    exc = _status_error(
        anthropic.RateLimitError, 429, "rate limited", "https://api.anthropic.com/v1/messages"
    )
    monkeypatch.setattr(report_service, "AsyncAnthropic", _raising_anthropic(exc))

    response = client.post("/v1/reports", headers=auth, json=meeting_payload)

    assert response.status_code == 429
    assert "Claude" in response.json()["detail"]


def test_claude_sin_conexion_devuelve_502(client, auth, meeting_payload, monkeypatch):
    exc = anthropic.APIConnectionError(
        request=httpx.Request("POST", "https://api.anthropic.com/v1/messages")
    )
    monkeypatch.setattr(report_service, "AsyncAnthropic", _raising_anthropic(exc))

    response = client.post("/v1/reports", headers=auth, json=meeting_payload)

    assert response.status_code == 502
    assert "No se pudo conectar" in response.json()["detail"]


def test_error_500_de_claude_devuelve_502_con_el_codigo(
    client, auth, meeting_payload, monkeypatch
):
    exc = _status_error(
        anthropic.APIStatusError, 529, "overloaded", "https://api.anthropic.com/v1/messages"
    )
    monkeypatch.setattr(report_service, "AsyncAnthropic", _raising_anthropic(exc))

    response = client.post("/v1/reports", headers=auth, json=meeting_payload)

    assert response.status_code == 502
    assert "529" in response.json()["detail"]


def test_informe_con_json_roto_devuelve_502(client, auth, meeting_payload, monkeypatch):
    fake = _FakeAnthropic(text="{esto no es json")
    monkeypatch.setattr(report_service, "AsyncAnthropic", lambda **_: fake)

    response = client.post("/v1/reports", headers=auth, json=meeting_payload)

    assert response.status_code == 502
    assert "formato esperado" in response.json()["detail"]


def test_informe_sin_los_campos_del_schema_devuelve_502(
    client, auth, meeting_payload, monkeypatch
):
    fake = _FakeAnthropic(text=json.dumps({"acuerdos": ["algo"]}))
    monkeypatch.setattr(report_service, "AsyncAnthropic", lambda **_: fake)

    response = client.post("/v1/reports", headers=auth, json=meeting_payload)

    assert response.status_code == 502
    assert "formato esperado" in response.json()["detail"]


@respx.mock
def test_airtable_sin_conexion_devuelve_502(client, auth, meeting_payload):
    respx.post("https://api.airtable.com/v0/appTEST/Reuniones").mock(
        side_effect=httpx.ConnectError("no route to host")
    )

    payload = {**meeting_payload, "report": REPORT_JSON}
    response = client.post("/v1/meetings", headers=auth, json=payload)

    assert response.status_code == 502
    assert "Airtable" in response.json()["detail"]


@respx.mock
def test_airtable_lento_devuelve_504(client, auth, meeting_payload):
    respx.post("https://api.airtable.com/v0/appTEST/Reuniones").mock(
        side_effect=httpx.ReadTimeout("timeout")
    )

    payload = {**meeting_payload, "report": REPORT_JSON}
    response = client.post("/v1/meetings", headers=auth, json=payload)

    assert response.status_code == 504
    assert "Airtable" in response.json()["detail"]


@respx.mock
def test_airtable_ok_pero_sin_id_devuelve_502(client, auth, meeting_payload):
    respx.post("https://api.airtable.com/v0/appTEST/Reuniones").mock(
        return_value=httpx.Response(200, json={"createdTime": "2026-09-01T10:00:00Z"})
    )

    payload = {**meeting_payload, "report": REPORT_JSON}
    response = client.post("/v1/meetings", headers=auth, json=payload)

    assert response.status_code == 502
    assert "sin el id" in response.json()["detail"]


def test_error_inesperado_devuelve_json_y_no_texto_pelado(auth, meeting_payload, monkeypatch):
    """La red de seguridad de main.py: la app siempre recibe un `detail` legible."""

    def _explota(**_):
        raise RuntimeError("algo que nadie previo")

    monkeypatch.setattr(report_service, "AsyncAnthropic", _explota)
    quiet_client = TestClient(app, raise_server_exceptions=False)

    response = quiet_client.post("/v1/reports", headers=auth, json=meeting_payload)

    assert response.status_code == 500
    assert "RuntimeError" in response.json()["detail"]
