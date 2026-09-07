"""Sincroniza una visita completa a Airtable.

Escribe en seis tablas: Productores, Fincas, Visitas, Grabaciones, Evidencias
y Hallazgos. Todo cuelga de `Visitas.Codigo de visita`, que es el UUID que
genero el telefono antes de tener red — el upsert por ese codigo es lo que
hace que reintentar una sincronizacion desde una vereda con senal intermitente
nunca duplique la visita.

Los hijos tambien se upsertean, cada uno por su llave natural dentro de la
visita (el orden del tramo, el titulo de la foto, la clave del hallazgo). Se
actualizan campos en vez de borrar y recrear a proposito: si un coordinador ya
corrigio un hallazgo en Airtable, volver a sincronizar no puede borrarle el
trabajo.
"""

import asyncio
import logging
from datetime import datetime

import httpx
from fastapi import HTTPException

from ..config import Settings
from ..schemas_visita import (
    EvidenciaPayload,
    GrabacionPayload,
    InformePayload,
    HallazgoPayload,
    ProductorPayload,
    VisitaPayload,
    VisitaSyncResult,
)
from .errors import UPSTREAM_EXCEPTIONS, upstream_error

logger = logging.getLogger(__name__)

API = "https://api.airtable.com/v0"

TBL_VISITADORES = "tblzyISjMzH2JBLin"
TBL_VEREDAS = "tbl8IIpcNFOHsgNOp"
TBL_PRODUCTORES = "tblh727lye1N27Z0b"
TBL_CATALOGO = "tblu6GshimULyLUAo"
TBL_FINCAS = "tblfUSm5SaLT1KV1J"
TBL_VISITAS = "tblv5fzFJiqjuZKwr"
TBL_GRABACIONES = "tblpfHtKhrPNPQAMm"
TBL_EVIDENCIAS = "tblKaxB2PDit0B7qR"
TBL_HALLAZGOS = "tbl73vmrXGHqQxGp5"
TBL_INFORMES = "tblczDOcHeq9taOQ9"

# Airtable topa en 5 req/s. Se escribe en lotes de 10 registros y se espera
# entre lotes: pasarse no da un error claro, da 429 a mitad de una visita y
# deja los hallazgos partidos.
LOTE = 10
_ESPERA_ENTRE_LOTES = 0.25


def _escapar(valor: str) -> str:
    """Escapa un valor para meterlo en un filterByFormula.

    Sin esto, un apellido con apostrofe (D'Angelo) rompe la formula y la
    busqueda devuelve la visita equivocada o ninguna.
    """
    return valor.replace("\\", "\\\\").replace("'", "\\'")


class Airtable:
    """Cliente minimo sobre la REST de Airtable.

    Se usa httpx directo en vez del SDK porque son cuatro verbos sobre una API
    estable, y una dependencia menos es una version menos que mantener.
    """

    def __init__(self, settings: Settings, cliente: httpx.AsyncClient):
        self._base = settings.airtable_base_id
        self._cliente = cliente
        self._headers = {
            "Authorization": f"Bearer {settings.airtable_token}",
            "Content-Type": "application/json",
        }

    async def _pedir(self, metodo: str, tabla: str, **kwargs) -> dict:
        url = f"{API}/{self._base}/{tabla}"
        try:
            r = await self._cliente.request(
                metodo, url, headers=self._headers, **kwargs
            )
        except UPSTREAM_EXCEPTIONS as exc:
            raise upstream_error("Airtable", exc) from exc

        if r.status_code >= 400:
            raise HTTPException(
                status_code=502,
                detail=f"Airtable respondio {r.status_code} en {tabla}: {r.text[:400]}",
            )
        return r.json()

    async def buscar(self, tabla: str, formula: str) -> dict | None:
        data = await self._pedir(
            "GET",
            tabla,
            params={"filterByFormula": formula, "maxRecords": 1},
        )
        registros = data.get("records", [])
        return registros[0] if registros else None

    async def listar(self, tabla: str, formula: str) -> list[dict]:
        """Todas las paginas. Una visita larga pasa de 100 hallazgos."""
        registros: list[dict] = []
        offset: str | None = None
        while True:
            params = {"filterByFormula": formula, "pageSize": 100}
            if offset:
                params["offset"] = offset
            data = await self._pedir("GET", tabla, params=params)
            registros.extend(data.get("records", []))
            offset = data.get("offset")
            if not offset:
                return registros

    async def crear(self, tabla: str, fields: dict) -> dict:
        data = await self._pedir(
            "POST", tabla, json={"fields": fields, "typecast": True}
        )
        return data

    async def actualizar(self, tabla: str, record_id: str, fields: dict) -> dict:
        return await self._pedir(
            "PATCH",
            tabla,
            json={
                "records": [{"id": record_id, "fields": fields}],
                "typecast": True,
            },
        )

    async def escribir_lote(self, tabla: str, registros: list[dict]) -> None:
        """Crea o actualiza hasta `LOTE` registros por llamada.

        Cada entrada lleva `fields` y, si es actualizacion, `id`. Se separan
        porque Airtable no acepta creaciones y actualizaciones en la misma
        peticion.
        """
        nuevos = [r for r in registros if not r.get("id")]
        existentes = [r for r in registros if r.get("id")]

        for metodo, grupo in (("POST", nuevos), ("PATCH", existentes)):
            for i in range(0, len(grupo), LOTE):
                trozo = grupo[i : i + LOTE]
                await self._pedir(
                    metodo,
                    tabla,
                    json={"records": trozo, "typecast": True},
                )
                if i + LOTE < len(grupo):
                    await asyncio.sleep(_ESPERA_ENTRE_LOTES)


# --------------------------------------------------------- reglas duras


def aplicar_reglas(h: HallazgoPayload) -> tuple[HallazgoPayload, str | None]:
    """Baja la certeza de un hallazgo cuando su procedencia no la sostiene.

    Se re-aplican en el backend aunque la app ya las haya aplicado. No es
    desconfianza del cliente: un APK viejo en el campo puede no tener la regla,
    y estas reglas son justamente lo que hace que el dato sea auditable.

    Devuelve el hallazgo (posiblemente degradado) y el motivo, o None si paso.
    """
    # 1. El visitador sugiriendo un dato no es el agricultor afirmandolo.
    if h.hablante == "visitador" and h.certeza == "Confirmado":
        return h.model_copy(update={"certeza": "Estimado"}), (
            f"{h.clave_tecnica}: lo dijo el visitador, baja de Confirmado a Estimado"
        )

    # 2. Sin cita no hay a donde volver en el audio, cualquiera sea la
    #    confianza que el modelo haya reportado.
    if not (h.cita_textual or "").strip() and h.certeza != "Pendiente":
        return h.model_copy(update={"certeza": "Pendiente"}), (
            f"{h.clave_tecnica}: sin cita textual, baja a Pendiente"
        )

    # 3. Un inferido sin razonamiento es un valor plausible sin defensa.
    if h.certeza == "Inferido" and not (h.razonamiento or "").strip():
        return h.model_copy(update={"certeza": "Pendiente"}), (
            f"{h.clave_tecnica}: Inferido sin razonamiento, baja a Pendiente"
        )

    return h, None


# --------------------------------------------------------- resolucion de enlaces


async def _id_por_nombre(at: Airtable, tabla: str, campo: str, valor: str) -> str | None:
    if not valor:
        return None
    reg = await at.buscar(tabla, f"{{{campo}}} = '{_escapar(valor)}'")
    return reg["id"] if reg else None


async def _resolver_visitador(at: Airtable, p: VisitaPayload) -> str | None:
    """Busca al visitador por `ID Empleado` y si no por nombre.

    Nunca lo crea: `Visitadores` es un espejo de solo lectura de la nomina. Si
    alguien no esta, la respuesta correcta es sembrar de nuevo desde nomina, no
    inventar una persona aca — dos bases que se separan sin que nadie se
    entere es peor que un enlace vacio.
    """
    if p.visitador_id_empleado:
        rid = await _id_por_nombre(
            at, TBL_VISITADORES, "ID Empleado", p.visitador_id_empleado
        )
        if rid:
            return rid
    if p.visitador_nombre:
        return await _id_por_nombre(
            at, TBL_VISITADORES, "Nombre", p.visitador_nombre
        )
    return None


def _campos_productor(prod: ProductorPayload) -> dict:
    """La ficha del agricultor, en campos de Airtable.

    Solo se escribe lo que vino con algo. Un campo que la app manda vacio se
    omite en vez de mandarse en blanco: la ficha se completa de a poco y a lo
    largo de varias visitas, y una segunda sincronizacion desde un telefono
    que todavia no tiene el telefono del productor no puede borrar el que un
    coordinador ya escribio en Airtable.
    """
    fields: dict = {"Nombre completo": prod.nombre_completo}

    if prod.documento:
        fields["Documento"] = prod.documento
        # Un numero sin tipo no se sabe leer. Si la app no lo manda se asume
        # cedula, que es lo que tiene casi todo el mundo en una vereda.
        fields["Tipo de documento"] = prod.tipo_documento or "CC"
    elif prod.tipo_documento:
        fields["Tipo de documento"] = prod.tipo_documento

    if prod.telefono:
        fields["Telefono"] = prod.telefono
    if prod.telefono_alterno:
        fields["Telefono alterno"] = prod.telefono_alterno
    if prod.genero:
        fields["Genero"] = prod.genero
    if prod.fecha_nacimiento:
        fields["Fecha de nacimiento"] = prod.fecha_nacimiento.isoformat()
    if prod.nivel_educativo:
        fields["Nivel educativo"] = prod.nivel_educativo
    if prod.anios_experiencia is not None:
        fields["Anios de experiencia"] = prod.anios_experiencia
    if prod.personas_hogar is not None:
        fields["Personas en el hogar"] = prod.personas_hogar
    if prod.organizacion:
        # Se deriva de la organizacion en vez de pedirla aparte: una casilla
        # marcada sin nombre de asociacion no le sirve a nadie.
        fields["Organizacion o asociacion"] = prod.organizacion
        fields["Pertenece a organizacion"] = True
    if prod.notas:
        fields["Notas"] = prod.notas
    if prod.consentimiento_datos:
        # Solo se escribe el si. Una visita en la que el productor no autorizo
        # no puede borrar la autorizacion que dio en otra: eso ya paso y es
        # justamente lo que hay que poder demostrar.
        fields["Consentimiento de datos"] = True
        if prod.fecha_consentimiento:
            fields["Fecha de consentimiento"] = prod.fecha_consentimiento.isoformat()
    if prod.enlace_foto:
        # Airtable va a buscar la imagen a esta URL, asi que tiene que ser
        # alcanzable desde internet. El adjunto es una copia: la foto vive en
        # el bucket, bajo el prefijo de la visita donde se tomo.
        fields["Foto"] = [{"url": prod.enlace_foto}]
    if prod.codigo_productor:
        fields["Codigo productor"] = prod.codigo_productor

    return fields


async def _resolver_productor(at: Airtable, p: VisitaPayload) -> str | None:
    """Upsert del productor. Documento primero, luego codigo, luego nombre.

    El documento es la unica llave de verdad: dos personas pueden llamarse
    igual en la misma vereda, y fusionarlas mezclaria las fincas de ambas.

    Cuando ya existe se ACTUALIZA, no se devuelve tal cual. La ficha del
    agricultor se completa desde la visita y casi nunca en la primera: si
    encontrarlo bastara para no escribir, el documento y el telefono que el
    visitador acaba de teclear en la finca no llegarian nunca a Airtable.
    """
    prod = p.productor
    if prod is None:
        return None

    fields = _campos_productor(prod)

    for campo, valor in (
        ("Documento", prod.documento),
        ("Codigo productor", prod.codigo_productor),
        ("Nombre completo", prod.nombre_completo),
    ):
        if not valor:
            continue
        reg = await at.buscar(TBL_PRODUCTORES, f"{{{campo}}} = '{_escapar(valor)}'")
        if reg:
            await at.actualizar(TBL_PRODUCTORES, reg["id"], fields)
            return reg["id"]

    creado = await at.crear(TBL_PRODUCTORES, fields)
    return creado["id"]


async def _resolver_finca(
    at: Airtable, p: VisitaPayload, productor_id: str | None, vereda_id: str | None
) -> str | None:
    """Upsert de la finca, identificada por nombre dentro del productor.

    Dos productores pueden tener una finca llamada "La Esperanza"; el mismo
    productor no suele tener dos.
    """
    finca = p.finca
    if finca is None:
        return None

    formula = f"{{Nombre de la finca}} = '{_escapar(finca.nombre)}'"
    if productor_id:
        # El campo enlazado compara contra el campo principal del vinculado.
        nombre_prod = p.productor.nombre_completo if p.productor else ""
        formula = (
            f"AND({formula}, {{Productor}} = '{_escapar(nombre_prod)}')"
            if nombre_prod
            else formula
        )

    reg = await at.buscar(TBL_FINCAS, formula)
    fields: dict = {"Nombre de la finca": finca.nombre}
    if productor_id:
        fields["Productor"] = [productor_id]
    if vereda_id:
        fields["Vereda"] = [vereda_id]
    if finca.latitud is not None:
        fields["Latitud"] = finca.latitud
    if finca.longitud is not None:
        fields["Longitud"] = finca.longitud
    if finca.area_total_ha is not None:
        fields["Area total (ha)"] = finca.area_total_ha

    if reg:
        await at.actualizar(TBL_FINCAS, reg["id"], fields)
        return reg["id"]
    creado = await at.crear(TBL_FINCAS, fields)
    return creado["id"]


async def _catalogo(at: Airtable) -> dict[str, str]:
    """Clave tecnica -> record id, de las variables activas.

    Un hallazgo con una clave que no esta aca se descarta y la clave se
    reporta. No se crea el campo: el catalogo es el contrato, y dejar que el
    modelo lo amplie solo significaria que nadie revisa lo que se esta
    midiendo.
    """
    registros = await at.listar(TBL_CATALOGO, "{Activo} = TRUE()")
    return {
        r["fields"]["Clave tecnica"]: r["id"]
        for r in registros
        if r.get("fields", {}).get("Clave tecnica")
    }


# --------------------------------------------------------- armado de campos


def _campos_visita(
    p: VisitaPayload,
    visitador_id: str | None,
    productor_id: str | None,
    finca_id: str | None,
    vereda_id: str | None,
) -> dict:
    fields: dict = {
        "Codigo de visita": p.codigo_visita,
        "Estado": p.estado,
        "Sincronizada": True,
        "Consiente audio": p.consiente_audio,
        "Consiente fotos": p.consiente_fotos,
        "Consiente uso de datos": p.consiente_uso_datos,
        "Marcada para eliminacion": p.marcada_para_eliminacion,
        # Airtable guarda un percent como fraccion: 0.55 se muestra 55%.
        "Completitud (%)": (p.completitud_pct or 0) / 100,
    }

    if p.inicio:
        fields["Inicio"] = p.inicio.isoformat()
    if p.fin:
        fields["Fin"] = p.fin.isoformat()
    if p.inicio and p.fin:
        fields["Duracion (min)"] = round((p.fin - p.inicio).total_seconds() / 60, 1)
    if p.tipo_visita:
        fields["Tipo de visita"] = p.tipo_visita
    if visitador_id:
        fields["Visitador"] = [visitador_id]
    if productor_id:
        fields["Productor"] = [productor_id]
    if finca_id:
        fields["Finca"] = [finca_id]
    if vereda_id:
        fields["Vereda"] = [vereda_id]
    if p.latitud is not None:
        fields["Latitud"] = p.latitud
    if p.longitud is not None:
        fields["Longitud"] = p.longitud
    if p.segundo_consentimiento is not None:
        fields["Segundo del consentimiento"] = p.segundo_consentimiento
    if p.objetivo:
        fields["Objetivo de la visita"] = p.objetivo
    if p.observaciones:
        fields["Observaciones del visitador"] = p.observaciones
    if p.resumen:
        fields["Resumen de la conversacion"] = p.resumen
    if p.temas_pendientes:
        fields["Temas pendientes"] = p.temas_pendientes
    if p.notas_prueba_campo:
        fields["Notas de prueba de campo"] = p.notas_prueba_campo

    return fields


def _campos_grabacion(g: GrabacionPayload, visita_id: str) -> dict:
    fields: dict = {
        # Con cero delante: Airtable ordena como texto y sin el
        # `tramo-10` queda antes que `tramo-2`.
        "Archivo": f"tramo-{g.orden:02d}.m4a",
        "Visita": [visita_id],
        "Orden": g.orden,
        "Duracion (min)": round(g.duracion_seg / 60, 1),
        "Tamano (MB)": round(g.tamano_bytes / (1024 * 1024), 2),
        "Estado": g.estado,
    }
    if g.inicio:
        fields["Inicio"] = g.inicio.isoformat()
    if g.enlace_audio:
        fields["Enlace de audio"] = g.enlace_audio
        # El adjunto es respaldo, no la fuente de verdad: sus URLs expiran y
        # topa en 5 MB. Airtable va a buscar el archivo a esta URL, asi que
        # tiene que ser alcanzable desde internet.
        fields["Audio"] = [{"url": g.enlace_audio}]
    if g.transcripcion:
        fields["Transcripcion"] = g.transcripcion
    if g.transcripcion_marcas:
        fields["Transcripcion con marcas de tiempo"] = g.transcripcion_marcas
    if g.motor_transcripcion:
        fields["Motor de transcripcion"] = g.motor_transcripcion
    if g.idioma:
        fields["Idioma"] = g.idioma
    return fields


def _campos_evidencia(e: EvidenciaPayload, visita_id: str, orden: int) -> dict:
    fields: dict = {
        "Titulo": f"Foto {orden:02d}",
        "Visita": [visita_id],
        "Estado de validacion": e.estado_validacion,
    }
    if e.tipo:
        fields["Tipo"] = e.tipo
    if e.tomada_en:
        fields["Tomada en"] = e.tomada_en.isoformat()
    if e.latitud is not None:
        fields["Latitud"] = e.latitud
    if e.longitud is not None:
        fields["Longitud"] = e.longitud
    if e.enlace_archivo:
        fields["Archivo"] = [{"url": e.enlace_archivo}]

    # El segundo del audio no tiene columna propia en Evidencias, y es el dato
    # que permite volver a lo que se estaba hablando mientras se fotografiaba.
    # Va al frente de la descripcion para no perderlo.
    partes = []
    if e.segundo_audio is not None:
        partes.append(f"[{e.segundo_audio // 60:02d}:{e.segundo_audio % 60:02d}]")
    if e.descripcion_visitador:
        partes.append(e.descripcion_visitador)
    if partes:
        fields["Descripcion del visitador"] = " ".join(partes)

    if e.descripcion_ia:
        fields["Descripcion IA"] = e.descripcion_ia
    if e.texto_ocr:
        fields["Texto OCR"] = e.texto_ocr
    return fields


def _campos_informe(
    i: InformePayload, visita_id: str, productor_id: str | None
) -> dict:
    fields: dict = {
        "Nombre": i.titulo,
        "Visita": [visita_id],
        "Tipo": i.tipo,
        # El markdown, no un PDF: desde aca se puede regenerar el documento sin
        # volver a pagarle al modelo.
        "Contenido": i.contenido,
        "Version": i.version,
        "Entregado": i.entregado,
    }
    if productor_id:
        fields["Productor"] = [productor_id]
    if i.generado_en:
        fields["Generado en"] = i.generado_en.isoformat()
    if i.medio_entrega:
        fields["Medio de entrega"] = i.medio_entrega
    if i.enlace_pdf:
        # Los nombres son los que la tabla `Informes` tiene DE VERDAD: `Enlace`
        # y `Archivo`. Antes decian "Enlace del PDF" y "PDF", que no existen, y
        # Airtable no ignora un campo desconocido — rechaza el registro entero
        # con 422. Como el audio, las fotos y los hallazgos suben en la misma
        # sincronizacion, eso dejaba la visita COMPLETA sin subir.
        #
        # `scripts/verificar_esquema.py` compara estos nombres contra la base
        # sin necesidad de un telefono ni una visita real.
        fields["Enlace"] = i.enlace_pdf
        # El adjunto es respaldo: sus URLs expiran y topa en 5 MB, y el informe
        # con fotos puede pasarlo. La fuente de verdad es el enlace al bucket.
        fields["Archivo"] = [{"url": i.enlace_pdf}]
    return fields


def _campos_hallazgo(h: HallazgoPayload, visita_id: str, campo_id: str) -> dict:
    etiqueta = h.valor_texto or (
        f"{h.valor_numerico} {h.unidad or ''}".strip()
        if h.valor_numerico is not None
        else h.clave_tecnica
    )
    fields: dict = {
        "Hallazgo": f"{h.clave_tecnica}: {etiqueta}"[:255],
        "Visita": [visita_id],
        "Campo": [campo_id],
        "Fuente": h.fuente,
        "Certeza": h.certeza,
        "Estado": h.estado,
    }
    if h.entidad_destino:
        fields["Entidad destino"] = h.entidad_destino
    if h.entidad_local_id:
        fields["Entidad local id"] = h.entidad_local_id
    if h.valor_texto:
        fields["Valor texto"] = h.valor_texto
    if h.valor_numerico is not None:
        fields["Valor numerico"] = h.valor_numerico
    if h.unidad:
        fields["Unidad"] = h.unidad
    if h.cita_textual:
        fields["Cita textual"] = h.cita_textual
    if h.segundo_audio is not None:
        fields["Segundo del audio"] = h.segundo_audio
    if h.hablante:
        fields["Hablante"] = h.hablante
    if h.razonamiento:
        fields["Razonamiento"] = h.razonamiento
    if h.confianza is not None:
        fields["Confianza"] = h.confianza
    if h.valor_corregido:
        fields["Valor corregido"] = h.valor_corregido
    return fields


# --------------------------------------------------------- upsert de hijos


def _llave_informe(nombre: str | None, version: object) -> str | None:
    """Identidad de un informe dentro de su visita: el titulo Y la version.

    El titulo solo NO alcanza. La app guarda todas las versiones a proposito
    —si el visitador regenera y el nuevo sale peor, el que ya le mostro al
    productor sigue existiendo— y el modelo les pone el mismo titulo a todas.
    Con el titulo como unica llave, la v1 y la v2 apuntaban al mismo registro:
    Airtable rechazaba el lote entero con 422 y la visita completa se quedaba
    sin sincronizar.

    Sin version se asume la 1: los informes escritos antes de que existiera el
    campo tienen que seguir casando con su registro en vez de duplicarse.
    """
    if not nombre:
        return None
    return f"{nombre}#v{version if version is not None else 1}"


def _llave_natural(tabla: str, fields: dict) -> str | None:
    """Como se reconoce un hijo ya escrito en Airtable.

    Es la contraparte de la llave que arma `sincronizar` para lo que manda el
    telefono: las dos tienen que producir la misma cadena o cada
    sincronizacion crearia registros nuevos en vez de actualizar.
    """
    if tabla == TBL_INFORMES:
        return _llave_informe(fields.get("Nombre"), fields.get("Version"))

    campo = {
        TBL_GRABACIONES: "Archivo",
        TBL_EVIDENCIAS: "Titulo",
        TBL_HALLAZGOS: "Hallazgo",
    }[tabla]
    return fields.get(campo) or None


async def _upsert_hijos(
    at: Airtable,
    tabla: str,
    codigo_visita: str,
    deseados: list[tuple[str, dict]],
) -> int:
    """Escribe los hijos de una visita casando por llave natural.

    `deseados` es una lista de (llave, fields). La llave identifica al hijo
    dentro de la visita: el orden del tramo, el titulo de la foto, la clave del
    hallazgo. Lo que ya existe se actualiza; lo que no, se crea.

    No se borra lo que sobra a proposito. Si un coordinador agrego un hallazgo
    a mano en Airtable, una sincronizacion desde el telefono no puede
    desaparecerlo — el telefono no sabe de ese registro y no le corresponde
    decidir.
    """
    if not deseados:
        return 0

    existentes = await at.listar(
        tabla, f"{{Visita}} = '{_escapar(codigo_visita)}'"
    )

    por_llave: dict[str, str] = {}
    for r in existentes:
        llave = _llave_natural(tabla, r.get("fields", {}))
        if llave:
            por_llave[llave] = r["id"]

    registros: list[dict] = []
    posicion_de: dict[str, int] = {}
    for llave, fields in deseados:
        rid = por_llave.get(llave)
        if rid is None:
            registros.append({"fields": fields})
            continue

        # Airtable rechaza la peticion ENTERA con 422 si el mismo record id
        # aparece dos veces ("You cannot update the same record multiple times
        # in a single request"). O sea: dos hijos que caigan en la misma llave
        # natural no fallan solos, se llevan la sincronizacion de toda la
        # visita — el audio, las fotos y los hallazgos incluidos.
        #
        # Por eso se colapsan aca en vez de confiar en que las llaves siempre
        # sean unicas. Gana el ultimo, que es el estado mas reciente que mando
        # el telefono. Que dos hijos compartan llave significa que en Airtable
        # son indistinguibles de todos modos.
        anterior = posicion_de.get(rid)
        if anterior is None:
            posicion_de[rid] = len(registros)
            registros.append({"id": rid, "fields": fields})
        else:
            registros[anterior] = {"id": rid, "fields": fields}

    await at.escribir_lote(tabla, registros)
    return len(registros)


# --------------------------------------------------------- entrada publica


async def sincronizar(settings: Settings, p: VisitaPayload) -> VisitaSyncResult:
    if not settings.airtable_token or not settings.airtable_base_id:
        raise HTTPException(status_code=500, detail="Falta configuracion de Airtable.")

    async with httpx.AsyncClient(timeout=60) as cliente:
        at = Airtable(settings, cliente)

        vereda_id = await _id_por_nombre(at, TBL_VEREDAS, "Vereda", p.vereda or "")
        visitador_id = await _resolver_visitador(at, p)
        productor_id = await _resolver_productor(at, p)
        finca_id = await _resolver_finca(at, p, productor_id, vereda_id)

        # Upsert de la visita por el UUID del telefono. Es lo que hace que
        # reintentar desde una vereda con senal intermitente no duplique.
        fields = _campos_visita(p, visitador_id, productor_id, finca_id, vereda_id)
        existente = await at.buscar(
            TBL_VISITAS, f"{{Codigo de visita}} = '{_escapar(p.codigo_visita)}'"
        )
        if existente:
            visita_id = existente["id"]
            await at.actualizar(TBL_VISITAS, visita_id, fields)
        else:
            visita_id = (await at.crear(TBL_VISITAS, fields))["id"]

        grabaciones = await _upsert_hijos(
            at,
            TBL_GRABACIONES,
            p.codigo_visita,
            [
                (f"tramo-{g.orden:02d}.m4a", _campos_grabacion(g, visita_id))
                for g in sorted(p.grabaciones, key=lambda g: g.orden)
            ],
        )

        evidencias = await _upsert_hijos(
            at,
            TBL_EVIDENCIAS,
            p.codigo_visita,
            [
                (f"Foto {i:02d}", _campos_evidencia(e, visita_id, i))
                # Ordenadas por hora de toma: el numero de la foto en Airtable
                # tiene que ser el mismo que el del archivo en el bucket.
                for i, e in enumerate(
                    sorted(
                        p.evidencias,
                        key=lambda e: e.tomada_en or datetime.min,
                    ),
                    start=1,
                )
            ],
        )

        catalogo = await _catalogo(at)
        desconocidas: list[str] = []
        degradados: list[str] = []
        deseados_hallazgos: list[tuple[str, dict]] = []

        for h in p.hallazgos:
            campo_id = catalogo.get(h.clave_tecnica)
            if campo_id is None:
                # No se inventa un campo: la clave se reporta y alguien decide
                # si merece entrar al catalogo.
                desconocidas.append(h.clave_tecnica)
                continue

            aplicado, motivo = aplicar_reglas(h)
            if motivo:
                degradados.append(motivo)

            fields_h = _campos_hallazgo(aplicado, visita_id, campo_id)
            deseados_hallazgos.append((fields_h["Hallazgo"], fields_h))

        hallazgos = await _upsert_hijos(
            at, TBL_HALLAZGOS, p.codigo_visita, deseados_hallazgos
        )

        informes = await _upsert_hijos(
            at,
            TBL_INFORMES,
            p.codigo_visita,
            [
                (
                    _llave_informe(i.titulo, i.version),
                    _campos_informe(i, visita_id, productor_id),
                )
                for i in p.informes
            ],
        )

    if desconocidas:
        logger.warning(
            "Visita %s: %d hallazgos descartados por clave fuera del catalogo: %s",
            p.codigo_visita,
            len(desconocidas),
            ", ".join(sorted(set(desconocidas))),
        )

    return VisitaSyncResult(
        codigo_visita=p.codigo_visita,
        record_id=visita_id,
        url=f"https://airtable.com/{settings.airtable_base_id}/{TBL_VISITAS}/{visita_id}",
        grabaciones=grabaciones,
        evidencias=evidencias,
        hallazgos=hallazgos,
        informes=informes,
        claves_desconocidas=sorted(set(desconocidas)),
        degradados=degradados,
    )
