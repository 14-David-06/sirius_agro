"""Pruebas de la sincronizacion a Airtable, sin red ni credenciales reales.

Lo que se verifica aca no es que Airtable responda: es que un dato que llega
sin procedencia no se guarde como si la tuviera. Las tres reglas duras son la
razon de ser del modelo de datos, y son lo unico que impide que el informe que
se le entrega firmado al productor contenga un valor que nadie dijo.
"""

from datetime import datetime

import json

import httpx
import pytest
import respx

from app.config import Settings
from app.schemas_visita import (
    InformePayload,
    EvidenciaPayload,
    FincaPayload,
    GrabacionPayload,
    HallazgoPayload,
    ProductorPayload,
    VisitaPayload,
)
from app.services import sincronizacion as sync

BASE = "appTEST"
API = f"https://api.airtable.com/v0/{BASE}"


def _hallazgo(**kwargs) -> HallazgoPayload:
    base = {
        "id": "h1",
        "clave_tecnica": "fuente_agua",
        "valor_texto": "Quebrada al lado del lote",
        "cita_textual": "...cogemos el agua de la quebradita...",
        "segundo_audio": 412,
        "hablante": "agricultor",
        "certeza": "Confirmado",
        "confianza": 0.86,
    }
    base.update(kwargs)
    return HallazgoPayload(**base)


class TestReglasDuras:
    def test_lo_que_dijo_el_visitador_nunca_queda_confirmado(self):
        """El visitador sugiriendo un dato no es el agricultor afirmandolo."""
        h, motivo = sync.aplicar_reglas(
            _hallazgo(hablante="visitador", certeza="Confirmado")
        )

        assert h.certeza == "Estimado"
        assert "visitador" in motivo

    def test_sin_cita_baja_a_pendiente(self):
        """Sin cita no hay a donde volver en el audio."""
        h, motivo = sync.aplicar_reglas(_hallazgo(cita_textual=None, confianza=0.99))

        assert h.certeza == "Pendiente"
        assert "cita" in motivo

    def test_una_cita_en_blanco_no_cuenta_como_cita(self):
        h, _ = sync.aplicar_reglas(_hallazgo(cita_textual="   "))
        assert h.certeza == "Pendiente"

    def test_inferido_sin_razonamiento_baja_a_pendiente(self):
        """Un inferido sin razonamiento es un valor plausible sin defensa."""
        h, motivo = sync.aplicar_reglas(_hallazgo(certeza="Inferido", razonamiento=None))

        assert h.certeza == "Pendiente"
        assert "azonamiento" in motivo

    def test_inferido_con_razonamiento_se_respeta(self):
        h, motivo = sync.aplicar_reglas(
            _hallazgo(certeza="Inferido", razonamiento="Dijo que riega tres lotes.")
        )

        assert h.certeza == "Inferido"
        assert motivo is None

    def test_un_hallazgo_completo_pasa_intacto(self):
        h, motivo = sync.aplicar_reglas(_hallazgo())

        assert h.certeza == "Confirmado"
        assert motivo is None

    def test_la_confianza_alta_no_evita_la_regla(self):
        """El modelo no puede saltarse la regla reportando confianza alta."""
        h, _ = sync.aplicar_reglas(_hallazgo(cita_textual="", confianza=1.0))
        assert h.certeza == "Pendiente"


class TestCamposDeVisita:
    def _payload(self, **kwargs) -> VisitaPayload:
        base = {
            "codigo_visita": "uuid-1",
            "inicio": datetime(2026, 9, 2, 8, 0),
            "fin": datetime(2026, 9, 2, 9, 30),
            "completitud_pct": 55,
        }
        base.update(kwargs)
        return VisitaPayload(**base)

    def test_la_completitud_va_como_fraccion(self):
        """Airtable guarda un percent como fraccion: 0.55 se muestra 55%."""
        campos = sync._campos_visita(self._payload(), None, None, None, None)
        assert campos["Completitud (%)"] == 0.55

    def test_la_duracion_sale_de_inicio_y_fin(self):
        campos = sync._campos_visita(self._payload(), None, None, None, None)
        assert campos["Duracion (min)"] == 90.0

    def test_sin_fin_no_inventa_duracion(self):
        campos = sync._campos_visita(self._payload(fin=None), None, None, None, None)
        assert "Duracion (min)" not in campos

    def test_los_enlaces_solo_van_si_se_resolvieron(self):
        """Un enlace a un registro que no existe rompe la escritura entera."""
        campos = sync._campos_visita(self._payload(), None, None, None, None)
        for enlace in ("Visitador", "Productor", "Finca", "Vereda"):
            assert enlace not in campos

        campos = sync._campos_visita(self._payload(), "recV", "recP", "recF", "recVe")
        assert campos["Visitador"] == ["recV"]
        assert campos["Finca"] == ["recF"]

    def test_los_tres_consentimientos_siempre_viajan(self):
        """Van en la visita, no en el productor: se piden en cada visita."""
        campos = sync._campos_visita(self._payload(), None, None, None, None)
        assert campos["Consiente audio"] is False
        assert campos["Consiente fotos"] is False
        assert campos["Consiente uso de datos"] is False


class TestCamposDeGrabacion:
    def _g(self, **kwargs) -> GrabacionPayload:
        base = {
            "id": "g1",
            "orden": 1,
            "duracion_seg": 300,
            "tamano_bytes": 1258291,
            "transcripcion": "Buenos dias.",
            "transcripcion_marcas": "[00:04] Hablante 1: Buenos dias.",
        }
        base.update(kwargs)
        return GrabacionPayload(**base)

    def test_la_transcripcion_literal_y_la_de_marcas_van_separadas(self):
        """La de marcas es el contrato con la extraccion; la literal es lectura."""
        campos = sync._campos_grabacion(self._g(), "recV")

        assert campos["Transcripcion"] == "Buenos dias."
        assert campos["Transcripcion con marcas de tiempo"].startswith("[00:04]")

    def test_convierte_a_minutos_y_megas(self):
        campos = sync._campos_grabacion(self._g(), "recV")

        assert campos["Duracion (min)"] == 5.0
        assert campos["Tamano (MB)"] == 1.2

    def test_sin_enlace_no_manda_adjunto(self):
        """Airtable va a buscar la URL: mandarla vacia da un 422 sin sentido."""
        campos = sync._campos_grabacion(self._g(), "recV")

        assert "Audio" not in campos
        assert "Enlace de audio" not in campos

    def test_con_enlace_manda_url_y_adjunto(self):
        campos = sync._campos_grabacion(
            self._g(enlace_audio="https://cdn/x/tramo-1.m4a"), "recV"
        )

        assert campos["Enlace de audio"] == "https://cdn/x/tramo-1.m4a"
        assert campos["Audio"] == [{"url": "https://cdn/x/tramo-1.m4a"}]


class TestCamposDeEvidencia:
    def test_el_segundo_del_audio_no_se_pierde(self):
        """Evidencias no tiene columna para el segundo, y es como se vuelve
        a lo que se estaba hablando mientras se fotografiaba."""
        campos = sync._campos_evidencia(
            EvidenciaPayload(id="e1", segundo_audio=237, descripcion_visitador="Etiqueta"),
            "recV",
            1,
        )

        assert campos["Descripcion del visitador"] == "[03:57] Etiqueta"


class TestEscapado:
    def test_un_apostrofe_no_rompe_la_formula(self):
        """Sin esto, D'Angelo devuelve la visita equivocada o ninguna."""
        assert sync._escapar("D'Angelo") == "D\\'Angelo"


# --------------------------------------------------------- de punta a punta


def _ruta(path: str, respuesta: dict, metodo: str = "GET"):
    return respx.request(metodo, f"{API}/{path}").mock(
        return_value=httpx.Response(200, json=respuesta)
    )


@pytest.fixture
def settings():
    return Settings(airtable_token="pat-test", airtable_base_id=BASE)


def _mockear_airtable(visita_existente: dict | None = None):
    """Deja lista una base vacia salvo el catalogo y, opcionalmente, la visita."""
    respx.get(f"{API}/{sync.TBL_VEREDAS}").mock(
        return_value=httpx.Response(200, json={"records": []})
    )
    respx.get(f"{API}/{sync.TBL_VISITADORES}").mock(
        return_value=httpx.Response(200, json={"records": []})
    )
    respx.get(f"{API}/{sync.TBL_PRODUCTORES}").mock(
        return_value=httpx.Response(200, json={"records": []})
    )
    respx.post(f"{API}/{sync.TBL_PRODUCTORES}").mock(
        return_value=httpx.Response(200, json={"id": "recProd"})
    )
    respx.get(f"{API}/{sync.TBL_FINCAS}").mock(
        return_value=httpx.Response(200, json={"records": []})
    )
    respx.post(f"{API}/{sync.TBL_FINCAS}").mock(
        return_value=httpx.Response(200, json={"id": "recFinca"})
    )
    respx.get(f"{API}/{sync.TBL_CATALOGO}").mock(
        return_value=httpx.Response(
            200,
            json={
                "records": [
                    {"id": "recCampo1", "fields": {"Clave tecnica": "fuente_agua"}},
                ]
            },
        )
    )
    respx.get(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(
            200, json={"records": [visita_existente] if visita_existente else []}
        )
    )
    for tabla in (
        sync.TBL_GRABACIONES,
        sync.TBL_EVIDENCIAS,
        sync.TBL_HALLAZGOS,
        sync.TBL_INFORMES,
    ):
        respx.get(f"{API}/{tabla}").mock(
            return_value=httpx.Response(200, json={"records": []})
        )
        respx.post(f"{API}/{tabla}").mock(
            return_value=httpx.Response(200, json={"records": []})
        )
        respx.patch(f"{API}/{tabla}").mock(
            return_value=httpx.Response(200, json={"records": []})
        )


def _payload_completo(**kwargs) -> VisitaPayload:
    base = {
        "codigo_visita": "uuid-visita-1",
        "inicio": datetime(2026, 9, 2, 8, 0),
        "productor": ProductorPayload(nombre_completo="Pedro Rodriguez"),
        "finca": FincaPayload(nombre="La Esperanza"),
        "vereda": "Guaicaramo",
        "grabaciones": [
            GrabacionPayload(
                id="g1",
                orden=1,
                transcripcion="Buenos dias.",
                transcripcion_marcas="[00:04] Hablante 1: Buenos dias.",
            )
        ],
        "evidencias": [EvidenciaPayload(id="e1", tipo="Cultivo")],
        "hallazgos": [_hallazgo()],
    }
    base.update(kwargs)
    return VisitaPayload(**base)


@respx.mock
@pytest.mark.asyncio
async def test_una_visita_nueva_se_crea_y_cuenta_sus_hijos(settings):
    _mockear_airtable()
    crear_visita = respx.post(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(200, json={"id": "recVisita"})
    )

    r = await sync.sincronizar(settings, _payload_completo())

    assert crear_visita.called
    assert r.record_id == "recVisita"
    assert (r.grabaciones, r.evidencias, r.hallazgos) == (1, 1, 1)


@respx.mock
@pytest.mark.asyncio
async def test_reintentar_no_duplica_la_visita(settings):
    """Es la razon de ser del UUID: en campo la senal va y viene."""
    _mockear_airtable(visita_existente={"id": "recVisita", "fields": {}})
    crear = respx.post(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(200, json={"id": "NO-DEBERIA-CREARSE"})
    )
    actualizar = respx.patch(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(200, json={"records": []})
    )

    r = await sync.sincronizar(settings, _payload_completo())

    assert not crear.called
    assert actualizar.called
    assert r.record_id == "recVisita"


@respx.mock
@pytest.mark.asyncio
async def test_una_clave_fuera_del_catalogo_se_descarta_y_se_reporta(settings):
    """No se inventa un campo: alguien decide si merece entrar al catalogo."""
    _mockear_airtable()
    respx.post(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(200, json={"id": "recVisita"})
    )

    r = await sync.sincronizar(
        settings,
        _payload_completo(
            hallazgos=[_hallazgo(), _hallazgo(clave_tecnica="algo_inventado")]
        ),
    )

    assert r.hallazgos == 1
    assert r.claves_desconocidas == ["algo_inventado"]


@respx.mock
@pytest.mark.asyncio
async def test_los_degradados_se_reportan_a_la_app(settings):
    """La app lo refleja sin tener que volver a preguntar."""
    _mockear_airtable()
    respx.post(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(200, json={"id": "recVisita"})
    )

    r = await sync.sincronizar(
        settings, _payload_completo(hallazgos=[_hallazgo(cita_textual=None)])
    )

    assert len(r.degradados) == 1
    assert "sin cita textual" in r.degradados[0]


@respx.mock
@pytest.mark.asyncio
async def test_un_error_de_airtable_se_explica_con_la_tabla(settings):
    """Un 422 pelado no dice en cual de las seis tablas fallo."""
    _mockear_airtable()
    respx.post(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(422, text='{"error":{"type":"UNKNOWN_FIELD_NAME"}}')
    )

    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc:
        await sync.sincronizar(settings, _payload_completo())

    assert exc.value.status_code == 502
    assert sync.TBL_VISITAS in exc.value.detail
    assert "UNKNOWN_FIELD_NAME" in exc.value.detail


@respx.mock
@pytest.mark.asyncio
async def test_el_informe_llega_a_airtable_con_la_visita(settings):
    """`Informes` era una de las tablas que nadie escribia. El informe se
    genera en la finca y viaja por la misma cola que el resto: si se subiera
    aparte, cerrar la app sin señal lo perderia."""
    _mockear_airtable()
    respx.post(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(200, json={"id": "recVisita"})
    )
    escritura = respx.post(f"{API}/{sync.TBL_INFORMES}").mock(
        return_value=httpx.Response(200, json={"records": []})
    )

    r = await sync.sincronizar(
        settings,
        _payload_completo(
            informes=[
                InformePayload(
                    id="inf-1",
                    titulo="Informe La Esperanza - 2026-09-02",
                    contenido="# Informe de su visita\n\nContenido.",
                    generado_en=datetime(2026, 9, 2, 10, 30),
                )
            ]
        ),
    )

    assert r.informes == 1
    enviado = json.loads(escritura.calls.last.request.content)["records"][0]["fields"]
    assert enviado["Tipo"] == "Resumen para el agricultor"
    assert enviado["Visita"] == ["recVisita"]
    # El markdown va completo: desde ahi se regenera el PDF sin volver a
    # pagarle al modelo.
    assert enviado["Contenido"].startswith("# Informe de su visita")
    assert enviado["Entregado"] is False


@respx.mock
@pytest.mark.asyncio
async def test_una_visita_sin_informe_no_toca_la_tabla(settings):
    _mockear_airtable()
    respx.post(f"{API}/{sync.TBL_VISITAS}").mock(
        return_value=httpx.Response(200, json={"id": "recVisita"})
    )
    escritura = respx.post(f"{API}/{sync.TBL_INFORMES}").mock(
        return_value=httpx.Response(200, json={"records": []})
    )

    r = await sync.sincronizar(settings, _payload_completo())

    assert r.informes == 0
    assert not escritura.called
