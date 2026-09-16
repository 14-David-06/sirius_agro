"""El historial de visitas de un agricultor, leido de Airtable.

Lo que se protege aca es lo que no se ve fallar. Un historial que casa mal los
hijos no da error: devuelve visitas sin un solo hallazgo y sin una sola foto,
que en la pantalla se leen como visitas donde no se registro nada. Por eso la
mitad de estas pruebas son sobre el emparejamiento.
"""

import httpx
import pytest
import respx

from app.config import Settings
from app.services import historial

BASE = "appTEST"
API = f"https://api.airtable.com/v0/{BASE}"

REC_PRODUCTOR = "recPEDRO"
REC_VISITA = "recVIS1"
CODIGO = "7f3c1a9e-0000-4000-8000-000000000001"


@pytest.fixture
def settings() -> Settings:
    return Settings(
        app_api_key="test-key",
        airtable_token="pat-test",
        airtable_base_id=BASE,
    )


def _respuesta(registros: list[dict]) -> httpx.Response:
    return httpx.Response(200, json={"records": registros})


def _montar(
    *,
    productor: dict | None = None,
    visitas: list[dict] | None = None,
    hallazgos: list[dict] | None = None,
    evidencias: list[dict] | None = None,
    grabaciones: list[dict] | None = None,
    informes: list[dict] | None = None,
    catalogo: list[dict] | None = None,
) -> None:
    """Cada tabla en su ruta, como responde Airtable de verdad."""
    ficha = productor if productor is not None else {
        "id": REC_PRODUCTOR,
        "fields": {
            "Nombre completo": "Pedro Gomez",
            "Documento": "1090123456",
            "Codigo productor": "BU-0007",
            "Visitas": [REC_VISITA],
        },
    }

    respx.get(f"{API}/{historial.TBL_PRODUCTORES}").mock(
        return_value=_respuesta([ficha])
    )
    respx.get(f"{API}/{historial.TBL_VISITAS}").mock(
        return_value=_respuesta(visitas if visitas is not None else [_visita()])
    )
    respx.get(f"{API}/{historial.TBL_VISITADORES}").mock(
        return_value=_respuesta(
            [{"id": "recVISITADOR", "fields": {"Nombre": "Persona De Prueba"}}]
        )
    )
    respx.get(f"{API}/{historial.TBL_FINCAS}").mock(
        return_value=_respuesta(
            [{"id": "recFINCA", "fields": {"Nombre de la finca": "La Soledad"}}]
        )
    )
    respx.get(f"{API}/{historial.TBL_VEREDAS}").mock(
        return_value=_respuesta(
            [{"id": "recVEREDA", "fields": {"Vereda": "Las Moras"}}]
        )
    )
    respx.get(f"{API}/{historial.TBL_HALLAZGOS}").mock(
        return_value=_respuesta(hallazgos or [])
    )
    respx.get(f"{API}/{historial.TBL_EVIDENCIAS}").mock(
        return_value=_respuesta(evidencias or [])
    )
    respx.get(f"{API}/{historial.TBL_GRABACIONES}").mock(
        return_value=_respuesta(grabaciones or [])
    )
    respx.get(f"{API}/{historial.TBL_INFORMES}").mock(
        return_value=_respuesta(informes or [])
    )
    respx.get(f"{API}/{historial.TBL_CATALOGO}").mock(
        return_value=_respuesta(
            catalogo
            if catalogo is not None
            else [{"id": "recCAMPO", "fields": {"Clave tecnica": "pozos_cantidad"}}]
        )
    )


def _visita(**fields) -> dict:
    base = {
        "Codigo de visita": CODIGO,
        "Inicio": "2026-09-14T09:30:00.000Z",
        "Fin": "2026-09-14T11:15:00.000Z",
        "Estado": "Cerrada",
        "Completitud (%)": 0.48,
        "Latitud": 4.57321,
        "Longitud": -72.819044,
        "Consiente audio": True,
        "Visitador": ["recVISITADOR"],
        "Productor": [REC_PRODUCTOR],
        "Finca": ["recFINCA"],
        "Vereda": ["recVEREDA"],
    }
    base.update(fields)
    return {"id": REC_VISITA, "fields": base}


class TestHistorial:
    @respx.mock
    @pytest.mark.asyncio
    async def test_trae_la_visita_con_sus_enlaces_resueltos(self, settings):
        """Los enlaces llegan como record id. Sin resolverlos, el historial
        mostraria `recFINCA` donde deberia decir el nombre de la finca."""
        _montar()

        h = await historial.historial_de_productor(settings, REC_PRODUCTOR)

        assert h.productor == "Pedro Gomez"
        assert h.codigo_productor == "BU-0007"
        assert len(h.visitas) == 1

        v = h.visitas[0]
        assert v.codigo_visita == CODIGO
        assert v.finca == "La Soledad"
        assert v.vereda == "Las Moras"
        assert v.visitador == "Persona De Prueba"
        assert v.productor == "Pedro Gomez"

    @respx.mock
    @pytest.mark.asyncio
    async def test_el_porcentaje_vuelve_a_ser_porcentaje(self, settings):
        """Airtable guarda el percent como fraccion: 0.48 se muestra 48%. Sin
        deshacerlo, el historial diria que la visita cubrio el 0% del
        cuestionario."""
        _montar()
        h = await historial.historial_de_productor(settings, REC_PRODUCTOR)
        assert h.visitas[0].completitud_pct == 48

    @respx.mock
    @pytest.mark.asyncio
    async def test_los_hijos_se_cuelgan_de_su_visita_por_record_id(self, settings):
        """El emparejamiento es por record id porque asi enlaza Airtable. Si se
        hiciera por codigo, la visita llegaria vacia y sin ningun error: se
        leeria como una visita donde no se registro nada."""
        _montar(
            hallazgos=[
                {
                    "id": "recH1",
                    "fields": {
                        "Visita": [REC_VISITA],
                        "Campo": ["recCAMPO"],
                        "Valor numerico": 3,
                        "Unidad": "pozos",
                        "Certeza": "Confirmado",
                        "Fuente": "Audio",
                        "Segundo del audio": 724,
                    },
                }
            ],
            evidencias=[
                {
                    "id": "recE1",
                    "fields": {
                        "Visita": [REC_VISITA],
                        "Titulo": "Foto 01",
                        "Archivo": [{"url": "https://airtable.test/foto.jpg"}],
                        "Latitud": 4.5732,
                    },
                }
            ],
            grabaciones=[
                {
                    "id": "recG1",
                    "fields": {
                        "Visita": [REC_VISITA],
                        "Orden": 1,
                        "Enlace de audio": "https://bucket.test/tramo-01.m4a",
                        "Transcripcion": "Hablamos del agua.",
                    },
                }
            ],
            informes=[
                {
                    "id": "recI1",
                    "fields": {
                        "Visita": [REC_VISITA],
                        "Nombre": "Informe La Soledad",
                        "Version": 1,
                        "Contenido": "## Lo que conversamos",
                        "Enlace": "https://bucket.test/informe-01.pdf",
                    },
                }
            ],
        )

        v = (await historial.historial_de_productor(settings, REC_PRODUCTOR)).visitas[0]

        assert len(v.hallazgos) == 1
        assert v.hallazgos[0].clave_tecnica == "pozos_cantidad"
        assert v.hallazgos[0].valor_numerico == 3
        assert v.hallazgos[0].segundo_audio == 724

        assert v.evidencias[0].url == "https://airtable.test/foto.jpg"
        assert v.grabaciones[0].url == "https://bucket.test/tramo-01.m4a"
        assert v.informes[0].enlace_pdf == "https://bucket.test/informe-01.pdf"

    @respx.mock
    @pytest.mark.asyncio
    async def test_un_hijo_de_otra_visita_no_se_cuelga_de_esta(self, settings):
        """Airtable filtra por formula, pero el emparejamiento no puede confiar
        en eso: un hijo que llegue de mas no puede aterrizar en la visita
        equivocada."""
        _montar(
            hallazgos=[
                {
                    "id": "recH9",
                    "fields": {"Visita": ["recOTRA"], "Campo": ["recCAMPO"]},
                }
            ]
        )
        v = (await historial.historial_de_productor(settings, REC_PRODUCTOR)).visitas[0]
        assert v.hallazgos == []

    @respx.mock
    @pytest.mark.asyncio
    async def test_una_visita_sin_codigo_no_entra(self, settings):
        """Sin `Codigo de visita` no hay identidad, y la app no podria decidir
        si esa visita ya es suya. Espejarla arriesgaria duplicar la que tiene."""
        _montar(visitas=[{"id": REC_VISITA, "fields": {"Estado": "Cerrada"}}])
        h = await historial.historial_de_productor(settings, REC_PRODUCTOR)
        assert h.visitas == []

    @respx.mock
    @pytest.mark.asyncio
    async def test_un_agricultor_sin_visitas_no_es_un_error(self, settings):
        """Es el caso normal de la primera visita: la ficha existe y no tiene
        historia. Tiene que responder vacio, no fallar."""
        _montar(
            productor={
                "id": REC_PRODUCTOR,
                "fields": {"Nombre completo": "Pedro Gomez"},
            }
        )
        h = await historial.historial_de_productor(settings, REC_PRODUCTOR)
        assert h.visitas == []
        assert h.truncado is False

    @respx.mock
    @pytest.mark.asyncio
    async def test_un_agricultor_que_no_existe_da_404(self, settings):
        respx.get(f"{API}/{historial.TBL_PRODUCTORES}").mock(
            return_value=_respuesta([])
        )
        with pytest.raises(Exception) as exc:
            await historial.historial_de_productor(settings, "recFANTASMA")
        assert "404" in str(exc.value) or "no esta" in str(exc.value)

    @respx.mock
    @pytest.mark.asyncio
    async def test_se_recorta_por_las_mas_viejas_y_se_avisa(self, settings):
        """El tope existe para que una ficha con dos anios de historia no le
        baje treinta visitas con su audio a un telefono en una vereda."""
        visitas = [
            {
                "id": f"recV{i}",
                "fields": {
                    "Codigo de visita": f"codigo-{i}",
                    "Inicio": f"2026-09-{i + 1:02d}T09:00:00.000Z",
                },
            }
            for i in range(5)
        ]
        _montar(visitas=visitas)

        h = await historial.historial_de_productor(settings, REC_PRODUCTOR, limite=2)

        assert h.truncado is True
        assert len(h.visitas) == 2
        # Las mas recientes: la del 5 y la del 4 de septiembre.
        assert [v.codigo_visita for v in h.visitas] == ["codigo-4", "codigo-3"]

    @respx.mock
    @pytest.mark.asyncio
    async def test_sin_configuracion_de_airtable_lo_dice(self):
        # Explicitamente vacio: `Settings()` toma lo que haya en el entorno, y
        # en la maquina de quien tiene un .env real la prueba pasaria por otra
        # razon que la que dice.
        vacio = Settings(app_api_key="test-key", airtable_token="", airtable_base_id="")
        with pytest.raises(Exception) as exc:
            await historial.historial_de_productor(vacio, REC_PRODUCTOR)
        assert "Airtable" in str(exc.value)


class TestIndice:
    """El indice que la app refresca sola: todas las visitas, sin sus hijos.

    Lo que se protege es que siga siendo LIVIANO. Si un dia alguien le cuelga
    los hijos, la app pasaria de bajar unos KB por su cuenta a bajar cientos de
    megas sin que nadie lo pida, en el telefono de un visitador que esta en una
    vereda.
    """

    @respx.mock
    @pytest.mark.asyncio
    async def test_trae_las_visitas_con_sus_nombres(self, settings):
        _montar()
        fichas = await historial.indice_de_visitas(settings)

        assert len(fichas) == 1
        assert fichas[0].codigo_visita == CODIGO
        assert fichas[0].productor == "Pedro Gomez"
        assert fichas[0].finca == "La Soledad"
        assert fichas[0].visitador == "Persona De Prueba"

    @respx.mock
    @pytest.mark.asyncio
    async def test_el_indice_NO_trae_hijos(self, settings):
        """Es la propiedad que lo hace automatico."""
        _montar(
            hallazgos=[
                {"id": "recH1", "fields": {"Visita": [REC_VISITA]}},
            ],
            evidencias=[
                {"id": "recE1", "fields": {"Visita": [REC_VISITA]}},
            ],
        )

        fichas = await historial.indice_de_visitas(settings)

        assert fichas[0].hallazgos == []
        assert fichas[0].evidencias == []
        assert fichas[0].grabaciones == []

    @respx.mock
    @pytest.mark.asyncio
    async def test_las_mas_recientes_primero_y_se_recorta(self, settings):
        visitas = [
            {
                "id": f"recV{i}",
                "fields": {
                    "Codigo de visita": f"codigo-{i}",
                    "Inicio": f"2026-09-{i + 1:02d}T09:00:00.000Z",
                },
            }
            for i in range(5)
        ]
        _montar(visitas=visitas)

        fichas = await historial.indice_de_visitas(settings, limite=2)
        assert [f.codigo_visita for f in fichas] == ["codigo-4", "codigo-3"]

    @respx.mock
    @pytest.mark.asyncio
    async def test_el_detalle_de_una_visita_si_trae_sus_hijos(self, settings):
        """Lo pesado se baja cuando alguien abre la visita, no antes."""
        _montar(
            hallazgos=[
                {
                    "id": "recH1",
                    "fields": {
                        "Visita": [REC_VISITA],
                        "Campo": ["recCAMPO"],
                        "Valor texto": "quebrada",
                    },
                }
            ],
        )

        ficha = await historial.visita_por_codigo(settings, CODIGO)

        assert ficha.codigo_visita == CODIGO
        assert len(ficha.hallazgos) == 1
        assert ficha.hallazgos[0].clave_tecnica == "pozos_cantidad"

    @respx.mock
    @pytest.mark.asyncio
    async def test_una_visita_que_no_existe_da_404(self, settings):
        respx.get(f"{API}/{historial.TBL_VISITAS}").mock(
            return_value=_respuesta([])
        )
        with pytest.raises(Exception) as exc:
            await historial.visita_por_codigo(settings, "no-existe")
        assert "404" in str(exc.value) or "no esta" in str(exc.value)
