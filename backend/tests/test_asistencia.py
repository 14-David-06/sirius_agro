"""Registro de asistencia: se guarda el audio y la firma, y despues se procesa."""

import json
from datetime import datetime

import httpx
import pytest
import respx
from fastapi import HTTPException

from app.config import Settings
from app.schemas import TranscriptionResult
from app.schemas_asistencia import AsistenciaPayload, DatosAsistencia
from app.schemas_visita import ArchivoSubido
from app.services import almacenamiento, extraccion_asistencia, transcription
from app.services import asistencia as servicio
from app.services.sincronizacion import (
    TBL_PRODUCTORES,
    TBL_VEREDAS,
    TBL_VISITADORES,
)

BASE = "appTEST"
API = f"https://api.airtable.com/v0/{BASE}"
TABLA = f"{API}/{servicio.TBL_ASISTENCIAS}"

VEREDAS = ["Guaicaramo", "San Isidro"]


def _payload(**kwargs) -> AsistenciaPayload:
    base = {
        "codigo_registro": "uuid-asis-1",
        "registrado_en": datetime(2026, 10, 2, 9, 30),
        "acepta_terminos": True,
        "terminos_url": "https://www.siriusregenerative.co/privacypolicy",
        "evento": "Taller de bioinsumos",
        "duracion_nota_seg": 40,
        "visitador_id_empleado": "SIRIUS-PER-0001",
    }
    base.update(kwargs)
    return AsistenciaPayload(**base)


@pytest.fixture
def settings():
    return Settings(airtable_token="pat-test", airtable_base_id=BASE)


@pytest.fixture
def bucket(monkeypatch):
    subidas: list[str] = []

    def subir(settings, contenido, clave, nombre):
        subidas.append(clave)
        return ArchivoSubido(
            url=f"https://cdn.test/{clave}", clave=clave, bytes=len(contenido)
        )

    monkeypatch.setattr(almacenamiento, "subir_a_clave", subir)
    return subidas


@pytest.fixture
def motor(monkeypatch):
    llamadas: list[bytes] = []

    async def transcribir(settings, filename, audio, **kwargs):
        llamadas.append(audio)
        return TranscriptionResult(text="Me llamo Maria Lopez, cedula 1234567.")

    monkeypatch.setattr(transcription, "transcribe", transcribir)
    return llamadas


@pytest.fixture
def claude(monkeypatch):
    llamadas: list[str] = []

    async def extraer(settings, texto, veredas):
        llamadas.append(texto)
        return DatosAsistencia(
            nombre_completo="Maria Lopez",
            cedula="1234567",
            telefono="3001234567",
            correo="maria@gmail.com",
            vereda="Guaicaramo",
        )

    monkeypatch.setattr(extraccion_asistencia, "extraer", extraer)
    return llamadas


def _airtable(*, existente: dict | None = None, productor: bool = False):
    respx.get(f"{API}/{TBL_VISITADORES}").mock(
        return_value=httpx.Response(200, json={"records": [{"id": "recVis"}]})
    )
    respx.get(f"{API}/{TBL_VEREDAS}").mock(
        return_value=httpx.Response(
            200,
            json={
                "records": [
                    {"id": "recGua", "fields": {"Vereda": "Guaicaramo"}},
                    {"id": "recSan", "fields": {"Vereda": "San Isidro"}},
                ]
            },
        )
    )
    respx.get(f"{API}/{TBL_PRODUCTORES}").mock(
        return_value=httpx.Response(
            200, json={"records": [{"id": "recProd"}] if productor else []}
        )
    )
    respx.get(TABLA).mock(
        return_value=httpx.Response(
            200, json={"records": [existente] if existente else []}
        )
    )
    crear = respx.post(TABLA).mock(
        return_value=httpx.Response(200, json={"id": "recAsis"})
    )
    actualizar = respx.patch(TABLA).mock(
        return_value=httpx.Response(200, json={"records": []})
    )
    return crear, actualizar


def _campos_patch(actualizar) -> list[dict]:
    return [
        json.loads(c.request.content)["records"][0]["fields"]
        for c in actualizar.calls
    ]


# ------------------------------------------------------------ flujo completo


@respx.mock
@pytest.mark.asyncio
async def test_nuevo_se_guarda_por_procesar_y_se_completa(
    settings, bucket, motor, claude
):
    crear, actualizar = _airtable()

    r = await servicio.sincronizar(settings, _payload(), firma=b"png", nota_voz=b"m4a")

    assert r.creado and r.procesado
    assert bucket == [
        "asistencias/uuid-asis-1/firma.png",
        "asistencias/uuid-asis-1/nota-voz.m4a",
    ]
    # Primero existe con el audio y la firma, sin datos todavia.
    creado = json.loads(crear.calls.last.request.content)["fields"]
    assert creado["Estado"] == "Por procesar"
    assert creado["Nota de voz"][0]["url"].endswith("nota-voz.m4a")
    assert creado["Firma"][0]["url"].endswith("firma.png")
    assert "Nombre completo" not in creado

    patches = _campos_patch(actualizar)
    assert patches[0] == {
        "Transcripcion nota de voz": "Me llamo Maria Lopez, cedula 1234567."
    }
    final = patches[-1]
    assert final["Estado"] == "Procesado"
    assert final["Nombre completo"] == "Maria Lopez"
    assert final["Vereda"] == ["recGua"]
    assert final["Correo electronico"] == "maria@gmail.com"
    # Ya no se preguntan: un registro nuevo no los escribe.
    assert "Cultivos sembrados" not in final
    assert "Area sembrada (ha)" not in final
    assert "Quiere visita tecnica" not in final
    assert "Productor" not in final
    assert r.datos.cedula == "1234567"
    # Sin foto el registro vale igual: es opcional.
    assert "Foto" not in creado and "Enlace foto" not in creado
    assert r.enlace_foto is None


@respx.mock
@pytest.mark.asyncio
async def test_la_foto_se_sube_y_queda_en_el_registro(settings, bucket, motor, claude):
    crear, _ = _airtable()

    r = await servicio.sincronizar(
        settings, _payload(), firma=b"png", nota_voz=b"m4a", foto=b"jpg"
    )

    assert "asistencias/uuid-asis-1/foto.jpg" in bucket
    creado = json.loads(crear.calls.last.request.content)["fields"]
    assert creado["Enlace foto"] == "https://cdn.test/asistencias/uuid-asis-1/foto.jpg"
    assert creado["Foto"][0]["filename"] == "foto.jpg"
    assert r.enlace_foto == creado["Enlace foto"]


@respx.mock
@pytest.mark.asyncio
async def test_los_adjuntos_van_firmados_y_el_enlace_queda_publico(
    bucket, motor, claude
):
    """El bucket es privado: con la URL publica Airtable recibe 403 y la firma
    y la nota de voz quedaban vacias. El enlace guardado sigue siendo el
    publico, que no vence."""
    almacenamiento._cliente.cache_clear()
    con_bucket = Settings(
        airtable_token="pat-test",
        airtable_base_id=BASE,
        bucket_name="sirius-agro-test",
        bucket_access_key="AKIA-test",
        bucket_secret_key="secreto",
        bucket_region="us-east-1",
        bucket_public_url="https://cdn.test",
    )
    crear, _ = _airtable()

    await servicio.sincronizar(con_bucket, _payload(), firma=b"png", nota_voz=b"m4a")

    creado = json.loads(crear.calls.last.request.content)["fields"]
    assert creado["Enlace firma"] == "https://cdn.test/asistencias/uuid-asis-1/firma.png"
    assert "X-Amz-Signature" not in creado["Enlace firma"]
    for campo in ("Firma", "Nota de voz"):
        assert "X-Amz-Signature" in creado[campo][0]["url"]
    assert creado["Firma"][0]["filename"] == "firma.png"


@respx.mock
@pytest.mark.asyncio
async def test_la_cedula_de_un_productor_enlaza_su_ficha(
    settings, bucket, motor, claude
):
    crear_productor = respx.post(f"{API}/{TBL_PRODUCTORES}")
    _, actualizar = _airtable(productor=True)

    await servicio.sincronizar(settings, _payload(), firma=b"png", nota_voz=b"m4a")

    assert _campos_patch(actualizar)[-1]["Productor"] == ["recProd"]
    assert not crear_productor.called


@respx.mock
@pytest.mark.asyncio
async def test_si_claude_falla_queda_guardado_con_error_y_la_peticion_falla(
    settings, bucket, motor, monkeypatch
):
    async def caido(*args, **kwargs):
        raise HTTPException(status_code=502, detail="Claude no responde")

    monkeypatch.setattr(extraccion_asistencia, "extraer", caido)
    crear, actualizar = _airtable()

    with pytest.raises(HTTPException) as exc:
        await servicio.sincronizar(settings, _payload(), firma=b"png", nota_voz=b"m4a")

    assert exc.value.status_code == 502
    assert crear.called
    ultimo = _campos_patch(actualizar)[-1]
    assert ultimo["Estado"] == "Error al procesar"
    assert "Claude no responde" in ultimo["Error de procesamiento"]


@respx.mock
@pytest.mark.asyncio
async def test_el_reintento_reusa_la_transcripcion_guardada(
    settings, bucket, motor, claude
):
    crear, _ = _airtable(
        existente={
            "id": "recAsis",
            "fields": {
                "Estado": "Error al procesar",
                "Transcripcion nota de voz": "ya transcrita",
            },
        }
    )

    r = await servicio.sincronizar(settings, _payload(), firma=b"png", nota_voz=b"m4a")

    assert not crear.called and not r.creado
    assert motor == []
    assert claude == ["ya transcrita"]


@respx.mock
@pytest.mark.asyncio
async def test_lo_ya_procesado_no_se_vuelve_a_procesar(
    settings, bucket, motor, claude
):
    _, actualizar = _airtable(
        existente={
            "id": "recAsis",
            "fields": {
                "Estado": "Procesado",
                "Nombre completo": "Maria Lopez (corregido)",
                "Vereda": ["recSan"],
                "Cultivos sembrados": ["Cacao"],
            },
        }
    )

    r = await servicio.sincronizar(settings, _payload(), firma=b"png", nota_voz=b"m4a")

    assert motor == [] and claude == []
    # La correccion del coordinador no se toca.
    assert "Nombre completo" not in _campos_patch(actualizar)[-1]
    assert r.datos.nombre_completo == "Maria Lopez (corregido)"
    assert r.datos.vereda == "San Isidro"


@pytest.mark.asyncio
async def test_sin_aceptar_terminos_se_rechaza(settings, bucket):
    with pytest.raises(HTTPException) as exc:
        await servicio.sincronizar(
            settings, _payload(acepta_terminos=False), firma=b"png", nota_voz=b"m4a"
        )
    assert exc.value.status_code == 400
    assert bucket == []


@pytest.mark.asyncio
async def test_sin_nota_de_voz_se_rechaza(settings, bucket):
    with pytest.raises(HTTPException) as exc:
        await servicio.sincronizar(settings, _payload(), firma=b"png", nota_voz=None)
    assert exc.value.status_code == 400


# ------------------------------------------------------- validacion de Claude


class TestValidar:
    def test_limpia_cifras_y_reconoce_vereda_sin_tildes(self):
        d = extraccion_asistencia.validar(
            {
                "nombre_completo": " Maria Lopez ",
                "cedula": "1.234.567",
                "telefono": "300 123 4567",
                "correo": "Maria.Lopez @Gmail.com",
                "vereda": "guaicaramo",
                "por_confirmar": [],
            },
            VEREDAS,
        )
        assert d.nombre_completo == "Maria Lopez"
        assert d.cedula == "1234567"
        assert d.telefono == "3001234567"
        assert d.vereda == "Guaicaramo"
        assert d.correo == "maria.lopez@gmail.com"
        assert d.por_confirmar == []

    def test_lo_dudoso_no_entra_y_queda_anotado(self):
        d = extraccion_asistencia.validar(
            {
                "nombre_completo": None,
                "cedula": "123",
                "telefono": None,
                "correo": "maria arroba gmail",
                "vereda": "El Porvenir",
                "por_confirmar": ["No dijo el nombre."],
            },
            VEREDAS,
        )
        assert d.cedula is None and d.vereda is None and d.correo is None
        assert len(d.por_confirmar) == 4
        assert any("El Porvenir" in x for x in d.por_confirmar)


def test_el_endpoint_pide_api_key(client):
    r = client.post("/v1/asistencias", data={"datos": "{}"})
    assert r.status_code == 401


def test_el_endpoint_valida_el_json(client, auth):
    r = client.post("/v1/asistencias", data={"datos": "{}"}, headers=auth)
    assert r.status_code == 422
