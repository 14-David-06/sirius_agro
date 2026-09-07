"""El directorio de agricultores ya registrados.

Lo que se prueba aca no es que Airtable conteste: es que la ayuda se comporte
como ayuda. Un directorio que devuelve una fila sin nombre, que se recorta en
silencio o que tumba el endpoint porque alguien escribio "mas de 20" en un
campo numerico termina creando el duplicado que vino a evitar.
"""

import httpx
import pytest
import respx

from app.config import Settings
from app.services import directorio

BASE = "appTEST"
API = f"https://api.airtable.com/v0/{BASE}"
TBL = directorio.TBL_PRODUCTORES


@pytest.fixture
def settings() -> Settings:
    return Settings(
        app_api_key="test-key",
        airtable_token="pat-test",
        airtable_base_id=BASE,
    )


def _registro(**fields) -> dict:
    base = {"Nombre completo": "Pedro Gomez"}
    base.update(fields)
    return {"id": "recPEDRO", "fields": base}


class TestLectura:
    @respx.mock
    @pytest.mark.asyncio
    async def test_trae_la_ficha_entera_no_solo_el_nombre(self, settings):
        """Si el agricultor ya existe, la segunda visita no vuelve a preguntar."""
        respx.get(f"{API}/{TBL}").mock(
            return_value=httpx.Response(
                200,
                json={
                    "records": [
                        _registro(
                            **{
                                "Documento": "1090123456",
                                "Tipo de documento": "CC",
                                "Telefono": "3001234567",
                                "Codigo productor": "BU-0007",
                                "Organizacion o asociacion": "ASOPLATANO",
                                "Consentimiento de datos": True,
                                "Anios de experiencia": 22,
                            }
                        )
                    ]
                },
            )
        )

        d = await directorio.listar_productores(settings)

        assert len(d.productores) == 1
        p = d.productores[0]
        assert p.id == "recPEDRO"
        assert p.documento == "1090123456"
        assert p.tipo_documento == "CC"
        assert p.telefono == "3001234567"
        assert p.codigo_productor == "BU-0007"
        assert p.organizacion == "ASOPLATANO"
        assert p.consentimiento_datos is True
        assert p.anios_experiencia == 22

    @respx.mock
    @pytest.mark.asyncio
    async def test_una_fila_sin_nombre_no_se_ofrece(self, settings):
        """Seria una linea en blanco que al tocarla adopta una identidad."""
        respx.get(f"{API}/{TBL}").mock(
            return_value=httpx.Response(
                200,
                json={
                    "records": [
                        {"id": "recVACIO", "fields": {"Documento": "123"}},
                        {"id": "recBLANCO", "fields": {"Nombre completo": "   "}},
                        _registro(),
                    ]
                },
            )
        )

        d = await directorio.listar_productores(settings)

        assert [p.nombre_completo for p in d.productores] == ["Pedro Gomez"]

    @respx.mock
    @pytest.mark.asyncio
    async def test_un_numero_escrito_a_mano_no_tumba_el_directorio(self, settings):
        """"mas de 20" en un campo numerico se ignora; el resto sigue sirviendo."""
        respx.get(f"{API}/{TBL}").mock(
            return_value=httpx.Response(
                200,
                json={
                    "records": [
                        _registro(**{"Anios de experiencia": "mas de 20"}),
                    ]
                },
            )
        )

        d = await directorio.listar_productores(settings)

        assert d.productores[0].anios_experiencia is None
        assert d.productores[0].nombre_completo == "Pedro Gomez"

    @respx.mock
    @pytest.mark.asyncio
    async def test_la_foto_es_la_miniatura_no_el_original(self, settings):
        """Es una cara en un listado, no un archivo que haya que bajar."""
        respx.get(f"{API}/{TBL}").mock(
            return_value=httpx.Response(
                200,
                json={
                    "records": [
                        _registro(
                            Foto=[
                                {
                                    "url": "https://airtable/original.jpg",
                                    "thumbnails": {
                                        "large": {"url": "https://airtable/grande.jpg"}
                                    },
                                }
                            ]
                        )
                    ]
                },
            )
        )

        d = await directorio.listar_productores(settings)

        assert d.productores[0].foto_url == "https://airtable/grande.jpg"

    @respx.mock
    @pytest.mark.asyncio
    async def test_va_alfabetico_sin_distinguir_mayusculas(self, settings):
        """Es una lista para leer con el pulgar, no un ranking de relevancia."""
        respx.get(f"{API}/{TBL}").mock(
            return_value=httpx.Response(
                200,
                json={
                    "records": [
                        {"id": "r1", "fields": {"Nombre completo": "ana perez"}},
                        {"id": "r2", "fields": {"Nombre completo": "Zulma Diaz"}},
                        {"id": "r3", "fields": {"Nombre completo": "Bernardo Ruiz"}},
                    ]
                },
            )
        )

        d = await directorio.listar_productores(settings)

        assert [p.nombre_completo for p in d.productores] == [
            "ana perez",
            "Bernardo Ruiz",
            "Zulma Diaz",
        ]

    @respx.mock
    @pytest.mark.asyncio
    async def test_recortar_se_avisa(self, settings):
        """Un directorio recortado en silencio se ve igual que uno sin el agricultor."""
        respx.get(f"{API}/{TBL}").mock(
            return_value=httpx.Response(
                200,
                json={
                    "records": [
                        {"id": f"r{i}", "fields": {"Nombre completo": f"Productor {i}"}}
                        for i in range(5)
                    ]
                },
            )
        )

        d = await directorio.listar_productores(settings, limite=2)

        assert len(d.productores) == 2
        assert d.truncado is True


class TestFormula:
    def test_sin_termino_trae_todo(self):
        assert directorio._formula(None) == "TRUE()"
        assert directorio._formula("   ") == "TRUE()"

    def test_busca_por_nombre_documento_o_codigo(self):
        f = directorio._formula("Gomez")

        assert "SEARCH('gomez'" in f
        assert "{Nombre completo}" in f
        assert "{Documento}" in f
        assert "{Codigo productor}" in f

    def test_un_apellido_con_apostrofe_no_rompe_la_formula(self):
        """D'Angelo cerraba la comilla y la busqueda devolvia cualquier cosa."""
        assert "\'" in directorio._formula("D'Angelo")


class TestEndpoint:
    def test_exige_la_llave(self, client):
        assert client.get("/v1/productores").status_code == 401

    @respx.mock
    def test_devuelve_el_directorio(self, client, auth):
        respx.get(f"{API}/{TBL}").mock(
            return_value=httpx.Response(200, json={"records": [_registro()]})
        )

        r = client.get("/v1/productores", headers=auth)

        assert r.status_code == 200
        cuerpo = r.json()
        assert cuerpo["truncado"] is False
        assert cuerpo["productores"][0]["nombre_completo"] == "Pedro Gomez"
