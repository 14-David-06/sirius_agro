"""Registro de asistencia: el audio y la firma de una persona, y lo que dijo.

En el campo el telefono solo guarda la nota de voz —donde la persona dice sus
datos siguiendo un guion— y la firma. Todo el procesamiento pasa aqui, cuando
hay red:

  1. la firma, la nota y la foto al bucket: es lo que no se puede volver a
     capturar;
  2. el registro en Airtable con Estado «Por procesar», el audio y la firma.
     Si lo que sigue falla, la asistencia ya existe y nadie la pierde;
  3. la transcripcion de la nota (una sola vez: un reintento reusa la que ya
     quedo guardada y no vuelve a pagarle al motor);
  4. Claude saca nombre, cedula, telefono, correo y vereda, y el codigo
     valida lo que devuelve;
  5. el registro se completa con esos datos y queda «Procesado».

Si 3 o 4 fallan el registro queda «Error al procesar» con el motivo y la
peticion falla: el telefono deja el item en la cola y reintenta solo. Un
registro ya «Procesado» no se vuelve a procesar, asi que si un coordinador
corrigio la cedula a mano en Airtable, un reintento no se la pisa.

El upsert es por `Codigo de registro`, el UUID que genero el telefono.
"""

import logging
from datetime import datetime, timezone

import httpx
from fastapi import HTTPException

from ..config import Settings
from ..schemas_asistencia import (
    AsistenciaPayload,
    AsistenciaSyncResult,
    DatosAsistencia,
)
from . import almacenamiento, extraccion_asistencia, transcription
from .sincronizacion import (
    TBL_PRODUCTORES,
    TBL_VEREDAS,
    TBL_VISITADORES,
    Airtable,
    _escapar,
    _id_por_nombre,
)

logger = logging.getLogger(__name__)

TBL_ASISTENCIAS = "tbl5WgavTPiRHyu8W"

CAMPO_CODIGO = "Codigo de registro"
CAMPO_TRANSCRIPCION = "Transcripcion nota de voz"

POR_PROCESAR = "Por procesar"
PROCESADO = "Procesado"
CON_ERROR = "Error al procesar"


def campos_base(
    p: AsistenciaPayload,
    *,
    visitador_id: str | None,
    enlace_firma: str | None,
    enlace_nota: str | None,
    enlace_foto: str | None = None,
) -> dict:
    """Lo que se sabe sin escuchar la nota: contexto, audio, firma y foto."""
    fields: dict = {
        CAMPO_CODIGO: p.codigo_registro,
        "Registrado en": p.registrado_en.isoformat(),
        "Acepta terminos": p.acepta_terminos,
        "Sincronizado en": datetime.now(timezone.utc).isoformat(),
    }
    if p.evento:
        fields["Evento o actividad"] = p.evento.strip()
    if p.terminos_url:
        fields["Terminos aceptados"] = p.terminos_url
    if p.latitud is not None:
        fields["Latitud"] = p.latitud
    if p.longitud is not None:
        fields["Longitud"] = p.longitud
    if visitador_id:
        fields["Visitador"] = [visitador_id]
    if enlace_firma:
        fields["Enlace firma"] = enlace_firma
        fields["Firma"] = [{"url": enlace_firma, "filename": "firma.png"}]
    if enlace_nota:
        fields["Enlace nota de voz"] = enlace_nota
        fields["Nota de voz"] = [{"url": enlace_nota, "filename": "nota-voz.m4a"}]
        if p.duracion_nota_seg is not None:
            fields["Duracion nota de voz (seg)"] = p.duracion_nota_seg
    if enlace_foto:
        fields["Enlace foto"] = enlace_foto
        fields["Foto"] = [{"url": enlace_foto, "filename": "foto.jpg"}]
    return fields


def campos_datos(
    d: DatosAsistencia, *, vereda_id: str | None, productor_id: str | None
) -> dict:
    """Lo que se saco de la nota. Viaja todo, tambien lo vacio: es el primer
    llenado del registro, no una correccion."""
    fields: dict = {
        "Nombre completo": d.nombre_completo or "",
        "Cedula": d.cedula or "",
        "Datos por confirmar": "\n".join(f"- {x}" for x in d.por_confirmar),
        "Estado": PROCESADO,
        "Error de procesamiento": "",
    }
    if d.telefono:
        fields["Telefono"] = d.telefono
    if d.correo:
        fields["Correo electronico"] = d.correo
    if vereda_id:
        fields["Vereda"] = [vereda_id]
    if productor_id:
        fields["Productor"] = [productor_id]
    return fields


def datos_de_registro(fields: dict, veredas: dict[str, str]) -> DatosAsistencia:
    """Lo que ya esta en Airtable, para devolverselo al telefono sin procesar
    de nuevo. [veredas] va de record id a nombre."""
    vereda_ids = fields.get("Vereda") or []
    area = fields.get("Area sembrada (ha)")
    return DatosAsistencia(
        nombre_completo=fields.get("Nombre completo") or None,
        cedula=fields.get("Cedula") or None,
        telefono=fields.get("Telefono") or None,
        correo=fields.get("Correo electronico") or None,
        vereda=veredas.get(vereda_ids[0]) if vereda_ids else None,
        cultivos=fields.get("Cultivos sembrados") or [],
        area_sembrada_ha=float(area) if area is not None else None,
        quiere_visita=bool(fields.get("Quiere visita tecnica")),
    )


async def _resolver_visitador(at: Airtable, p: AsistenciaPayload) -> str | None:
    """Mismo criterio que la visita: `ID Empleado` y si no el nombre. Nunca crea."""
    if p.visitador_id_empleado:
        rid = await _id_por_nombre(
            at, TBL_VISITADORES, "ID Empleado", p.visitador_id_empleado
        )
        if rid:
            return rid
    if p.visitador_nombre:
        return await _id_por_nombre(at, TBL_VISITADORES, "Nombre", p.visitador_nombre)
    return None


async def _veredas(at: Airtable) -> dict[str, str]:
    """Record id -> nombre, de toda la tabla Veredas. Son decenas de filas."""
    registros = await at.listar(TBL_VEREDAS, "TRUE()")
    return {
        r["id"]: r["fields"]["Vereda"]
        for r in registros
        if (r.get("fields") or {}).get("Vereda")
    }


async def _transcribir(settings: Settings, audio: bytes) -> str:
    r = await transcription.transcribe(settings, "nota-voz.m4a", audio, diarizar=False)
    texto = (r.text or "").strip()
    if not texto:
        raise HTTPException(
            status_code=422,
            detail="La nota de voz no tiene nada que se entienda. Hay que escucharla.",
        )
    return texto


def _motivo(exc: Exception) -> str:
    if isinstance(exc, HTTPException):
        return str(exc.detail)
    return f"{type(exc).__name__}: {exc}"


async def sincronizar(
    settings: Settings,
    p: AsistenciaPayload,
    *,
    firma: bytes | None,
    nota_voz: bytes | None,
    foto: bytes | None = None,
) -> AsistenciaSyncResult:
    if not settings.airtable_token or not settings.airtable_base_id:
        raise HTTPException(status_code=500, detail="Falta configuracion de Airtable.")
    if not p.acepta_terminos:
        # El aviso dice que enviar es aceptar. Un registro que llega sin la
        # aceptacion es un cliente roto, no una persona que dijo que no.
        raise HTTPException(
            status_code=400,
            detail="El registro llego sin la aceptacion de terminos y condiciones.",
        )
    if not nota_voz:
        raise HTTPException(
            status_code=400,
            detail="Falta la nota de voz: los datos de la persona estan en ella.",
        )

    enlace_firma = None
    if firma:
        enlace_firma = almacenamiento.subir_a_clave(
            settings,
            firma,
            almacenamiento.clave_de_asistencia(p.codigo_registro, "firma.png"),
            "firma.png",
        ).url
    enlace_nota = almacenamiento.subir_a_clave(
        settings,
        nota_voz,
        almacenamiento.clave_de_asistencia(p.codigo_registro, "nota-voz.m4a"),
        "nota-voz.m4a",
    ).url
    # Opcional: la persona puede no querer foto, y el registro vale igual.
    enlace_foto = None
    if foto:
        enlace_foto = almacenamiento.subir_a_clave(
            settings,
            foto,
            almacenamiento.clave_de_asistencia(p.codigo_registro, "foto.jpg"),
            "foto.jpg",
        ).url

    async with httpx.AsyncClient(timeout=60) as cliente:
        at = Airtable(settings, cliente)

        existente = await at.buscar(
            TBL_ASISTENCIAS, f"{{{CAMPO_CODIGO}}} = '{_escapar(p.codigo_registro)}'"
        )
        previos = (existente or {}).get("fields") or {}

        base = campos_base(
            p,
            visitador_id=await _resolver_visitador(at, p),
            enlace_firma=enlace_firma,
            enlace_nota=enlace_nota,
            enlace_foto=enlace_foto,
        )
        veredas = await _veredas(at)

        # Ya procesado: se refresca lo que vino del telefono y nada mas.
        if previos.get("Estado") == PROCESADO:
            await at.actualizar(TBL_ASISTENCIAS, existente["id"], base)
            return AsistenciaSyncResult(
                record_id=existente["id"],
                creado=False,
                procesado=True,
                enlace_firma=enlace_firma,
                enlace_nota_voz=enlace_nota,
                enlace_foto=enlace_foto,
                transcripcion=previos.get(CAMPO_TRANSCRIPCION),
                datos=datos_de_registro(previos, veredas),
            )

        # Primero queda guardado, despues se procesa.
        if existente:
            record_id, creado = existente["id"], False
            await at.actualizar(TBL_ASISTENCIAS, record_id, base)
        else:
            record_id = (
                await at.crear(TBL_ASISTENCIAS, {**base, "Estado": POR_PROCESAR})
            )["id"]
            creado = True

        try:
            transcripcion = previos.get(CAMPO_TRANSCRIPCION) or None
            if not transcripcion:
                transcripcion = await _transcribir(settings, nota_voz)
                # Se guarda apenas existe: si Claude falla, el reintento no
                # vuelve a transcribir.
                await at.actualizar(
                    TBL_ASISTENCIAS, record_id, {CAMPO_TRANSCRIPCION: transcripcion}
                )

            datos = await extraccion_asistencia.extraer(
                settings, transcripcion, sorted(veredas.values())
            )
        except Exception as exc:  # noqa: BLE001 — se registra y se relanza
            motivo = _motivo(exc)
            logger.warning(
                "No se pudo procesar la asistencia %s: %s", p.codigo_registro, motivo
            )
            await at.actualizar(
                TBL_ASISTENCIAS,
                record_id,
                {"Estado": CON_ERROR, "Error de procesamiento": motivo[:2000]},
            )
            raise HTTPException(
                status_code=502,
                detail=f"La asistencia quedo guardada pero sin procesar: {motivo}",
            ) from exc

        vereda_id = next((k for k, v in veredas.items() if v == datos.vereda), None)
        # Solo se enlaza, nunca se crea: quien asiste a un taller no es
        # todavia un productor con ficha.
        productor_id = (
            await _id_por_nombre(at, TBL_PRODUCTORES, "Documento", datos.cedula)
            if datos.cedula
            else None
        )
        await at.actualizar(
            TBL_ASISTENCIAS,
            record_id,
            campos_datos(datos, vereda_id=vereda_id, productor_id=productor_id),
        )

    return AsistenciaSyncResult(
        record_id=record_id,
        creado=creado,
        procesado=True,
        enlace_firma=enlace_firma,
        enlace_nota_voz=enlace_nota,
        enlace_foto=enlace_foto,
        transcripcion=transcripcion,
        datos=datos,
    )
