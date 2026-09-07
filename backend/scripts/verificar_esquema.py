"""Compara los campos que el backend ESCRIBE contra los que Airtable TIENE.

Existe por un fallo de campo: la sincronizacion de una visita entera se caia con

    422 UNKNOWN_FIELD_NAME: Unknown field name: "Enlace del PDF"

porque el codigo escribia un nombre de campo que en la base no existe — se
llamaba `Enlace`. Airtable no ignora el campo desconocido: **rechaza el
registro completo**, y como el audio, las fotos y los hallazgos viajan en la
misma sincronizacion, un nombre mal escrito se lleva la visita entera.

Ese error solo aparecia con un telefono conectado y una visita real que tuviera
justo ese dato lleno. Este script lo encuentra sin telefono y sin visita: arma
un payload con TODOS los campos opcionales puestos, llama a las mismas
funciones que arman los registros, y compara las llaves contra el esquema real.

    python scripts/verificar_esquema.py

Sale con codigo 1 si encuentra algo, para poder colgarlo de CI.

Solo lee: pide el esquema y no escribe nada en la base.
"""

from __future__ import annotations

import sys
from datetime import datetime
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.config import get_settings  # noqa: E402
from app.schemas_visita import (  # noqa: E402
    EvidenciaPayload,
    FincaPayload,
    GrabacionPayload,
    HallazgoPayload,
    InformePayload,
    ProductorPayload,
    VisitaPayload,
)
from app.services import sincronizacion as sync  # noqa: E402

META = "https://api.airtable.com/v0/meta/bases"


def esquema(token: str, base: str) -> dict[str, dict]:
    """{table_id: {"nombre": ..., "campos": {nombre: tipo}}}"""
    r = httpx.get(
        f"{META}/{base}/tables",
        headers={"Authorization": f"Bearer {token}"},
        timeout=30,
    )
    r.raise_for_status()
    return {
        t["id"]: {
            "nombre": t["name"],
            "campos": {f["name"]: f["type"] for f in t["fields"]},
        }
        for t in r.json()["tables"]
    }


def _payload_con_todo() -> VisitaPayload:
    """Una visita con cada campo opcional lleno.

    Los `if` de los `_campos_*` solo escriben lo que tiene valor, asi que un
    payload a medias deja campos sin revisar — y el que falta es justo el que
    rompe en campo seis meses despues.
    """
    ahora = datetime(2026, 9, 7, 9, 30)
    return VisitaPayload(
        codigo_visita="uuid-de-prueba",
        inicio=ahora,
        fin=ahora,
        tipo_visita="Primera visita",
        estado="En validacion",
        visitador_id_empleado="SIRIUS-PER-0001",
        visitador_nombre="Quien sea",
        productor=ProductorPayload(
            nombre_completo="Productor de prueba",
            documento="1234",
            telefono="3000000000",
            codigo_productor="BU-0001",
        ),
        finca=FincaPayload(
            nombre="Finca de prueba",
            vereda="Guaicaramo",
            latitud=4.5,
            longitud=-72.9,
            area_total_ha=12.0,
        ),
        vereda="Guaicaramo",
        latitud=4.5,
        longitud=-72.9,
        consiente_audio=True,
        consiente_fotos=True,
        consiente_uso_datos=True,
        segundo_consentimiento=42,
        objetivo="Probar el esquema",
        observaciones="—",
        resumen="—",
        temas_pendientes="—",
        notas_prueba_campo="—",
        completitud_pct=55,
        grabaciones=[
            GrabacionPayload(
                id="g1",
                orden=1,
                inicio=ahora,
                duracion_seg=600,
                tamano_bytes=1024,
                enlace_audio="https://ejemplo/audio.m4a",
                transcripcion="texto",
                transcripcion_marcas="[00:04] Hablante 1: texto",
                motor_transcripcion="scribe",
                idioma="es",
                estado="Subida",
            )
        ],
        evidencias=[
            EvidenciaPayload(
                id="e1",
                tipo="Cultivo",
                tomada_en=ahora,
                latitud=4.5,
                longitud=-72.9,
                segundo_audio=12,
                descripcion_visitador="—",
                descripcion_ia="—",
                texto_ocr="—",
                enlace_archivo="https://ejemplo/foto.jpg",
                estado_validacion="Sin revisar",
            )
        ],
        hallazgos=[
            HallazgoPayload(
                id="h1",
                clave_tecnica="fuente_agua",
                entidad_destino="Finca",
                entidad_local_id="cultivo_1",
                valor_texto="Quebrada",
                valor_numerico=3.0,
                unidad="ha",
                fuente="Audio",
                cita_textual="el agua viene de la quebrada",
                segundo_audio=30,
                hablante="agricultor",
                certeza="Confirmado",
                razonamiento="—",
                confianza=0.9,
                estado="Propuesto por IA",
                valor_corregido="Quebrada",
            )
        ],
        informes=[
            InformePayload(
                id="i1",
                titulo="Resumen para el agricultor",
                tipo="Resumen para el agricultor",
                contenido="—",
                version=1,
                generado_en=ahora,
                entregado=True,
                medio_entrega="WhatsApp",
                enlace_pdf="https://ejemplo/informe.pdf",
            )
        ],
    )


def _registros_que_escribe(p: VisitaPayload) -> list[tuple[str, str, dict]]:
    """(table_id, de donde sale, fields) para cada cosa que el backend escribe."""
    return [
        (
            sync.TBL_VISITAS,
            "_campos_visita",
            sync._campos_visita(p, "recV", "recP", "recF", "recVe"),
        ),
        (
            sync.TBL_GRABACIONES,
            "_campos_grabacion",
            sync._campos_grabacion(p.grabaciones[0], "recVisita"),
        ),
        (
            sync.TBL_EVIDENCIAS,
            "_campos_evidencia",
            sync._campos_evidencia(p.evidencias[0], "recVisita", 1),
        ),
        (
            sync.TBL_INFORMES,
            "_campos_informe",
            sync._campos_informe(p.informes[0], "recVisita", "recProductor"),
        ),
        (
            sync.TBL_HALLAZGOS,
            "_campos_hallazgo",
            sync._campos_hallazgo(p.hallazgos[0], "recVisita", "recCampo"),
        ),
    ]


def main() -> int:
    s = get_settings()
    if not s.airtable_token or not s.airtable_base_id:
        print("Falta AIRTABLE_TOKEN o AIRTABLE_BASE_ID en el .env")
        return 2

    try:
        tablas = esquema(s.airtable_token, s.airtable_base_id)
    except httpx.HTTPStatusError as e:
        print(f"Airtable respondio {e.response.status_code} al pedir el esquema.")
        if e.response.status_code in (401, 403):
            print(
                "El token necesita el permiso `schema.bases:read`. Es de solo "
                "lectura y solo lo usa este script."
            )
        return 2

    problemas = 0
    for tabla_id, origen, fields in _registros_que_escribe(_payload_con_todo()):
        info = tablas.get(tabla_id)
        if info is None:
            print(f"[FALTA LA TABLA] {tabla_id}, que escribe {origen}")
            problemas += 1
            continue

        desconocidos = [c for c in fields if c not in info["campos"]]
        estado = "OK" if not desconocidos else "ROTO"
        print(
            f"{estado:5} {info['nombre']:<14} {len(fields):>2} campos "
            f"({origen})"
        )
        for campo in desconocidos:
            # Sugerir el parecido ahorra el viaje a la interfaz de Airtable:
            # casi siempre es un nombre que cambio, no un campo que falta.
            parecidos = [
                real
                for real in info["campos"]
                if real.lower() in campo.lower() or campo.lower() in real.lower()
            ]
            pista = f"  ¿sera {parecidos}?" if parecidos else ""
            print(f"      falta en Airtable: {campo!r}{pista}")
            problemas += 1

    if problemas:
        print(
            f"\n{problemas} campo(s) que Airtable no conoce. Cada uno hace que "
            "se rechace\nel registro ENTERO, no solo ese campo: la visita "
            "completa se queda sin subir."
        )
        return 1

    print("\nTodos los campos que el backend escribe existen en la base.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
