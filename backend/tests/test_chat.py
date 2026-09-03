"""El chat de campo.

Lo que se protege: que el hilo llegue completo y en el orden correcto, que el
contexto de las visitas entre por el system y no como un turno mas, y que un
hilo invalido falle aca con un mensaje util en vez de rebotar en Anthropic.
"""

from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.config import Settings
from app.schemas_chat import ChatRequest
from app.services import chat as chat_service


class _FakeAnthropic:
    def __init__(self, texto="Sembra una cobertura antes de la lluvia."):
        self.texto = texto
        self.visto = {}
        self.messages = SimpleNamespace(create=self._create)

    async def _create(self, **kwargs):
        self.visto.update(kwargs)
        return SimpleNamespace(content=[SimpleNamespace(type="text", text=self.texto)])


@pytest.fixture
def anthropic(monkeypatch):
    def instalar(texto=None):
        fake = _FakeAnthropic(texto) if texto else _FakeAnthropic()
        monkeypatch.setattr(chat_service, "AsyncAnthropic", lambda **_: fake)
        return fake

    return instalar


def _settings():
    return Settings(anthropic_api_key="sk-test", claude_model="claude-opus-5")


def _req(**cambios):
    base = {
        "mensajes": [
            {"rol": "user", "contenido": "El lote esta compactado, que hago?"},
        ]
    }
    base.update(cambios)
    return ChatRequest(**base)


@pytest.mark.asyncio
async def test_responde_y_reporta_el_modelo(anthropic):
    fake = anthropic()
    res = await chat_service.responder(_settings(), _req())

    assert res.respuesta.startswith("Sembra")
    assert res.modelo == "claude-opus-5"
    assert fake.visto["messages"] == [
        {"role": "user", "content": "El lote esta compactado, que hago?"}
    ]


@pytest.mark.asyncio
async def test_el_hilo_viaja_completo_y_en_orden(anthropic):
    fake = anthropic()
    await chat_service.responder(
        _settings(),
        _req(
            mensajes=[
                {"rol": "user", "contenido": "Primera"},
                {"rol": "assistant", "contenido": "Respuesta"},
                {"rol": "user", "contenido": "Segunda"},
            ]
        ),
    )

    assert [m["role"] for m in fake.visto["messages"]] == [
        "user",
        "assistant",
        "user",
    ]
    assert fake.visto["messages"][-1]["content"] == "Segunda"


@pytest.mark.asyncio
async def test_el_contexto_de_visitas_va_en_el_system(anthropic):
    fake = anthropic()
    await chat_service.responder(
        _settings(),
        _req(visitador="Persona De Prueba", contexto="Finca La Soledad: 3 pozos."),
    )

    system = fake.visto["system"]
    assert "La Soledad" in system
    assert "Persona De Prueba" in system
    # Como contexto y no como turno: si entrara al hilo, el modelo lo leeria
    # como algo que el visitador acaba de afirmar en esta conversacion.
    assert len(fake.visto["messages"]) == 1


@pytest.mark.asyncio
async def test_hilo_vacio_falla_antes_de_llamar_al_modelo(anthropic):
    anthropic()
    with pytest.raises(HTTPException) as exc:
        await chat_service.responder(_settings(), _req(mensajes=[]))
    assert exc.value.status_code == 400


@pytest.mark.asyncio
async def test_hilo_que_arranca_con_el_modelo_se_rechaza(anthropic):
    anthropic()
    with pytest.raises(HTTPException) as exc:
        await chat_service.responder(
            _settings(),
            _req(mensajes=[{"rol": "assistant", "contenido": "Hola"}]),
        )
    assert exc.value.status_code == 400


@pytest.mark.asyncio
async def test_sin_llave_no_intenta_llamar(anthropic):
    anthropic()
    with pytest.raises(HTTPException) as exc:
        await chat_service.responder(Settings(anthropic_api_key=""), _req())
    assert exc.value.status_code == 500


@pytest.mark.asyncio
async def test_respuesta_vacia_no_se_devuelve_como_valida(anthropic):
    anthropic("   ")
    with pytest.raises(HTTPException) as exc:
        await chat_service.responder(_settings(), _req())
    assert exc.value.status_code == 502
