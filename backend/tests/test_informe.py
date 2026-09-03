"""El informe que se le entrega al agricultor.

Lo que se protege: que no invente, que no presente un estimado como un hecho, y
que no produzca un documento de relleno cuando no hay con que hacerlo. Un
informe con el membrete de Sirius que el productor no reconoce cuesta mas que
no entregar nada.
"""

from types import SimpleNamespace

import pytest

from app.schemas_informe import TIPO_AGRICULTOR
from app.services import informe as informe_service


class _FakeAnthropic:
    """Captura el prompt y devuelve un markdown fijo."""

    def __init__(self, texto="# Informe de su visita\n\nContenido."):
        self.texto = texto
        self.visto = {}
        self.messages = SimpleNamespace(create=self._create)

    async def _create(self, **kwargs):
        self.visto.update(kwargs)
        return SimpleNamespace(
            content=[SimpleNamespace(type="text", text=self.texto)]
        )


@pytest.fixture
def anthropic(monkeypatch):
    def instalar(texto=None):
        fake = _FakeAnthropic(texto) if texto else _FakeAnthropic()
        monkeypatch.setattr(
            informe_service, "AsyncAnthropic", lambda **_: fake
        )
        return fake

    return instalar


def _payload(**cambios):
    base = {
        "codigo_visita": "254d9edc-a0a8-4529-bd56-c8881e688ddf",
        "productor": "Senor Rumi",
        "finca": "La Soledad",
        "vereda": "Barranca",
        "visitador": "Persona De Prueba",
        "transcripcion": "[00:13] Hablante 0: Tengo tres pozos y recojo lluvia.",
        "completitud_pct": 33,
        "hallazgos": [
            {
                "campo": "Fuente de agua",
                "clave_tecnica": "fuente_agua",
                "valor": "Pozo",
                "certeza": "Confirmado",
                "modulo": "Agua",
            }
        ],
    }
    base.update(cambios)
    return base


def test_genera_el_informe_y_lo_titula_con_la_finca(client, auth, anthropic):
    anthropic()

    r = client.post("/v1/informes", headers=auth, json=_payload())

    assert r.status_code == 200, r.text
    cuerpo = r.json()
    assert cuerpo["tipo"] == TIPO_AGRICULTOR
    assert "La Soledad" in cuerpo["titulo"]
    assert cuerpo["contenido"].startswith("# Informe de su visita")
    assert cuerpo["modelo"]


def test_sin_transcripcion_ni_hallazgos_NO_se_genera_nada(client, auth, anthropic):
    """Es la diferencia entre no tener informe y tener uno de relleno."""
    fake = anthropic()

    r = client.post(
        "/v1/informes",
        headers=auth,
        json=_payload(transcripcion=None, hallazgos=[]),
    )

    assert r.status_code == 400
    assert "procesa" in r.json()["detail"].lower()
    # Ni siquiera se le pidio al modelo: no se gasta un llamado en eso.
    assert fake.visto == {}


def test_sin_transcripcion_pero_con_datos_se_arma_y_se_avisa(client, auth, anthropic):
    fake = anthropic()

    r = client.post("/v1/informes", headers=auth, json=_payload(transcripcion=None))

    assert r.status_code == 200
    prompt = fake.visto["messages"][0]["content"]
    # El modelo tiene que saber que no hubo grabacion, para decirlo.
    assert "NO HAY TRANSCRIPCION" in prompt


def test_un_hallazgo_pendiente_no_llega_al_prompt_como_dato(client, auth, anthropic):
    """Pendiente significa que no salio en la conversacion. Si se cuela en la
    lista de datos, el modelo lo escribe como si el agricultor lo hubiera
    dicho."""
    fake = anthropic()

    client.post(
        "/v1/informes",
        headers=auth,
        json=_payload(
            hallazgos=[
                {
                    "campo": "Area total",
                    "clave_tecnica": "area_total_ha",
                    "valor": "12",
                    "unidad": "ha",
                    "certeza": "Pendiente",
                    "modulo": "Tierra",
                },
                {
                    "campo": "Fuente de agua",
                    "clave_tecnica": "fuente_agua",
                    "valor": "Pozo",
                    "certeza": "Confirmado",
                    "modulo": "Agua",
                },
            ]
        ),
    )

    prompt = fake.visto["messages"][0]["content"]
    assert "Pozo" in prompt
    assert "Area total" not in prompt


def test_la_certeza_viaja_al_modelo(client, auth, anthropic):
    fake = anthropic()

    client.post(
        "/v1/informes",
        headers=auth,
        json=_payload(
            hallazgos=[
                {
                    "campo": "Anios en el territorio",
                    "clave_tecnica": "anios_en_territorio",
                    "valor": "9",
                    "unidad": "anios",
                    "certeza": "Estimado",
                    "modulo": "Productor",
                }
            ]
        ),
    )

    prompt = fake.visto["messages"][0]["content"]
    assert "[certeza: Estimado]" in prompt
    # Y la regla de como escribir cada certeza va en el system, no en el user.
    assert "Estimado" in fake.visto["system"]


def test_todo_pendiente_se_le_dice_al_modelo_en_vez_de_mandarlo_vacio(
    client, auth, anthropic
):
    fake = anthropic()

    client.post(
        "/v1/informes",
        headers=auth,
        json=_payload(
            hallazgos=[
                {
                    "campo": "Area total",
                    "clave_tecnica": "area_total_ha",
                    "valor": "12",
                    "certeza": "Pendiente",
                }
            ]
        ),
    )

    prompt = fake.visto["messages"][0]["content"]
    assert "Todos los datos quedaron en Pendiente" in prompt


def test_un_informe_vacio_del_modelo_es_un_error_no_un_informe(
    client, auth, anthropic
):
    anthropic(texto="   ")

    r = client.post("/v1/informes", headers=auth, json=_payload())

    assert r.status_code == 502


def test_el_informe_exige_la_api_key(client, anthropic):
    anthropic()
    assert client.post("/v1/informes", json=_payload()).status_code == 401
