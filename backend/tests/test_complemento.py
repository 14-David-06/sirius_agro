"""El chat de la visita: el unico lugar donde el modelo ESCRIBE datos.

Lo que se protege aca es la procedencia. Un dato que teclea el visitador de
memoria y despues no vale lo mismo que uno que dijo el agricultor frente a una
grabadora, y el sistema entero depende de que esa diferencia quede marcada en
el registro: la marca es lo que dispara la regla dura de que lo dicho por el
visitador nunca es `Confirmado`.

Si el modelo pudiera elegir esa marca, bastaria una alucinacion para
desactivarla.
"""

from types import SimpleNamespace

import pytest

from app.config import Settings
from app.schemas import CampoCatalogo
from app.schemas_complemento import ComplementoRequest, MensajeComplemento
from app.services import complemento


@pytest.fixture
def settings() -> Settings:
    return Settings(app_api_key="test-key", anthropic_api_key="sk-test")


CAMPOS = [
    CampoCatalogo(
        clave_tecnica="area_total_ha",
        campo="Area total",
        modulo="La finca",
        tipo_dato="Numero",
        unidad="ha",
    ),
    CampoCatalogo(
        clave_tecnica="fuente_agua",
        campo="Fuente de agua",
        modulo="Agua",
        tipo_dato="Texto",
    ),
]


def _peticion(**extra) -> ComplementoRequest:
    base = {
        "codigo_visita": "uuid-1",
        "mensajes": [
            MensajeComplemento(
                rol="user", contenido="El arriendo son 600 mil al mes"
            )
        ],
        "campos": CAMPOS,
        "visitador": "Persona De Prueba",
    }
    base.update(extra)
    return ComplementoRequest(**base)


def _respuesta_falsa(entrada: dict):
    """Como responde Anthropic cuando se le fuerza una herramienta."""
    return SimpleNamespace(
        content=[SimpleNamespace(type="tool_use", input=entrada)]
    )


class TestProcedencia:
    @pytest.mark.asyncio
    async def test_todo_lo_que_sale_de_aqui_es_manual_y_del_visitador(
        self, settings, monkeypatch
    ):
        """La marca la pone el servicio, no el modelo. Es lo que hace que la
        app y Airtable apliquen la regla dura al escribir."""
        await _con_respuesta(
            monkeypatch,
            {
                "respuesta": "Anotado.",
                "hallazgos": [
                    {
                        "clave": "area_total_ha",
                        "entidad_destino": "Finca",
                        "valor_numerico": 0.75,
                        "certeza": "Confirmado",
                        "cita": "El arriendo son 600 mil al mes",
                    }
                ],
                "temas_pendientes": [],
            },
        )

        r = await complemento.responder(settings, _peticion())

        assert r.hallazgos[0]["fuente"] == "Manual"
        assert r.hallazgos[0]["hablante"] == "visitador"

    @pytest.mark.asyncio
    async def test_el_modelo_no_puede_cambiar_la_procedencia(
        self, settings, monkeypatch
    ):
        """Aunque devuelva otra cosa —alucinacion o esquema futuro— la marca se
        reescribe. Si el modelo pudiera decir 'Audio' y 'agricultor', un dato
        tecleado entraria al registro como si lo hubiera afirmado el productor
        frente a una grabadora."""
        await _con_respuesta(
            monkeypatch,
            {
                "respuesta": "Anotado.",
                "hallazgos": [
                    {
                        "clave": "fuente_agua",
                        "entidad_destino": "Finca",
                        "valor_texto": "quebrada",
                        "certeza": "Confirmado",
                        "cita": "tiene una quebrada",
                        "fuente": "Audio",
                        "hablante": "agricultor",
                        "segundo": 120,
                    }
                ],
                "temas_pendientes": [],
            },
        )

        r = await complemento.responder(settings, _peticion())

        assert r.hallazgos[0]["fuente"] == "Manual"
        assert r.hallazgos[0]["hablante"] == "visitador"
        # Y sin segundo inventado: mandaria al visitador a escuchar un minuto
        # del audio donde nadie dijo nada.
        assert r.hallazgos[0]["segundo"] is None

    @pytest.mark.asyncio
    async def test_la_cita_del_visitador_se_conserva(self, settings, monkeypatch):
        """Es la procedencia del dato: dentro de seis meses tiene que poder
        verse de donde salio un valor que no vino del audio."""
        await _con_respuesta(
            monkeypatch,
            {
                "respuesta": "Anotado.",
                "hallazgos": [
                    {
                        "clave": "area_total_ha",
                        "entidad_destino": "Finca",
                        "valor_numerico": 0.75,
                        "certeza": "Estimado",
                        "cita": "son como tres cuartos de hectarea",
                    }
                ],
                "temas_pendientes": [],
            },
        )

        r = await complemento.responder(settings, _peticion())
        assert r.hallazgos[0]["cita"] == "son como tres cuartos de hectarea"


class TestFormato:
    @pytest.mark.asyncio
    async def test_un_hallazgo_sin_clave_no_entra(self, settings, monkeypatch):
        """Sin clave no hay donde guardarlo, y la app lo rechazaria igual. Se
        descarta aca en vez de viajar para morir alla."""
        await _con_respuesta(
            monkeypatch,
            {
                "respuesta": "Listo.",
                "hallazgos": [{"valor_texto": "algo", "cita": "x"}],
                "temas_pendientes": [],
            },
        )

        r = await complemento.responder(settings, _peticion())
        assert r.hallazgos == []

    @pytest.mark.asyncio
    async def test_los_pendientes_vacios_se_limpian(self, settings, monkeypatch):
        await _con_respuesta(
            monkeypatch,
            {
                "respuesta": "Listo.",
                "hallazgos": [],
                "temas_pendientes": ["Falta el riego", "  ", ""],
            },
        )

        r = await complemento.responder(settings, _peticion())
        assert r.temas_pendientes == ["Falta el riego"]

    @pytest.mark.asyncio
    async def test_una_respuesta_vacia_es_un_error(self, settings, monkeypatch):
        """Una burbuja en blanco en el chat parece que la app se colgo."""
        await _con_respuesta(
            monkeypatch,
            {"respuesta": "   ", "hallazgos": [], "temas_pendientes": []},
        )

        with pytest.raises(Exception) as exc:
            await complemento.responder(settings, _peticion())
        assert "vacia" in str(exc.value)

    @pytest.mark.asyncio
    async def test_el_esquema_cierra_las_claves_al_catalogo(self):
        """Con el enum, una clave inventada es un error de validacion del
        proveedor y no un hallazgo que apunta a un campo que no existe."""
        e = complemento.esquema(["area_total_ha", "fuente_agua"])
        propiedades = e["properties"]["hallazgos"]["items"]["properties"]
        assert propiedades["clave"]["enum"] == ["area_total_ha", "fuente_agua"]
        # Ni segundo ni hablante: no hay audio detras, y el hablante lo fija el
        # codigo.
        assert "segundo" not in propiedades
        assert "hablante" not in propiedades


class TestGuardas:
    @pytest.mark.asyncio
    async def test_sin_catalogo_no_se_puede_armar_el_esquema(self, settings):
        with pytest.raises(Exception) as exc:
            await complemento.responder(settings, _peticion(campos=[]))
        assert "catalogo" in str(exc.value)

    @pytest.mark.asyncio
    async def test_el_hilo_tiene_que_empezar_por_el_visitador(self, settings):
        """La API lo rechaza con un 400 que no le dice nada a nadie."""
        with pytest.raises(Exception) as exc:
            await complemento.responder(
                settings,
                _peticion(
                    mensajes=[
                        MensajeComplemento(rol="assistant", contenido="Hola")
                    ]
                ),
            )
        assert "visitador" in str(exc.value)

    @pytest.mark.asyncio
    async def test_sin_llave_de_anthropic_lo_dice(self):
        vacio = Settings(app_api_key="test-key", anthropic_api_key="")
        with pytest.raises(Exception) as exc:
            await complemento.responder(vacio, _peticion())
        assert "ANTHROPIC_API_KEY" in str(exc.value)


async def _con_respuesta(monkeypatch, entrada: dict) -> None:
    """Sustituye la llamada a Anthropic por una respuesta fija."""

    class _Mensajes:
        async def create(self, **kwargs):
            return _respuesta_falsa(entrada)

    class _Cliente:
        def __init__(self, **kwargs):
            self.messages = _Mensajes()

    monkeypatch.setattr(complemento, "AsyncAnthropic", _Cliente)
