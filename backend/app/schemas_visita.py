"""Payload de sincronizacion de una visita.

Lo manda la app desde su base local, que es la fuente de verdad mientras no
hay senal. Todo es opcional salvo `codigo_visita` a proposito: una visita se
sincroniza tal como este, aunque este a medias. Esperar a que este completa
significaria que un telefono que se moja en el potrero se lleva la visita.

`codigo_visita` es el UUID que genero el telefono antes de tener red. El
backend hace upsert por ese codigo, asi que reintentar nunca duplica.
"""

from datetime import datetime

from pydantic import BaseModel, Field


class GrabacionPayload(BaseModel):
    """Un tramo de audio con su transcripcion.

    `enlace_audio` es la URL en el bucket y es la fuente de verdad del audio;
    el adjunto de Airtable es solo respaldo, porque sus URLs expiran y una
    conversacion de 30 min no cabe en el limite de 5 MB por archivo.
    """

    id: str
    orden: int
    inicio: datetime | None = None
    duracion_seg: int = 0
    tamano_bytes: int = 0
    enlace_audio: str | None = None
    transcripcion: str | None = None

    # Un turno por linea con el segundo al frente. Es el contrato con la
    # extraccion: de aqui salen la cita textual y el segundo de cada hallazgo.
    transcripcion_marcas: str | None = None
    motor_transcripcion: str | None = None
    idioma: str | None = None
    estado: str = "Subida"


class EvidenciaPayload(BaseModel):
    id: str
    tipo: str | None = None
    tomada_en: datetime | None = None
    latitud: float | None = None
    longitud: float | None = None

    # Segundo de la grabacion en curso cuando se tomo la foto: permite volver
    # a lo que se estaba hablando mientras se fotografiaba.
    segundo_audio: int | None = None
    descripcion_visitador: str | None = None
    descripcion_ia: str | None = None
    texto_ocr: str | None = None
    enlace_archivo: str | None = None
    estado_validacion: str = "Sin revisar"


class HallazgoPayload(BaseModel):
    """Un dato extraido con su procedencia.

    Las tres reglas duras (ver `sincronizacion.aplicar_reglas`) se re-aplican
    en el backend aunque la app ya las haya aplicado. No es desconfianza del
    cliente: un APK viejo en el campo puede no tener la regla, y la regla es
    la que sostiene que el dato sea auditable.
    """

    id: str
    clave_tecnica: str
    entidad_destino: str | None = None
    entidad_local_id: str | None = None
    valor_texto: str | None = None
    valor_numerico: float | None = None
    unidad: str | None = None
    fuente: str = "Audio"
    cita_textual: str | None = None
    segundo_audio: int | None = None
    hablante: str | None = None
    certeza: str = "Pendiente"
    razonamiento: str | None = None
    confianza: float | None = None
    estado: str = "Propuesto por IA"
    valor_corregido: str | None = None


class ProductorPayload(BaseModel):
    nombre_completo: str
    documento: str | None = None
    telefono: str | None = None
    codigo_productor: str | None = None


class FincaPayload(BaseModel):
    nombre: str
    vereda: str | None = None
    latitud: float | None = None
    longitud: float | None = None
    area_total_ha: float | None = None


class VisitaPayload(BaseModel):
    codigo_visita: str

    inicio: datetime | None = None
    fin: datetime | None = None
    tipo_visita: str | None = None
    estado: str = "Pendiente de sincronizar"

    visitador_id_empleado: str | None = None
    visitador_nombre: str | None = None

    productor: ProductorPayload | None = None
    finca: FincaPayload | None = None
    vereda: str | None = None

    latitud: float | None = None
    longitud: float | None = None

    # Los tres consentimientos van en la visita, no en el productor: autorizar
    # una grabacion en marzo no autoriza la de septiembre.
    consiente_audio: bool = False
    consiente_fotos: bool = False
    consiente_uso_datos: bool = False
    segundo_consentimiento: int | None = None
    marcada_para_eliminacion: bool = False

    objetivo: str | None = None
    observaciones: str | None = None
    resumen: str | None = None
    temas_pendientes: str | None = None
    notas_prueba_campo: str | None = None
    completitud_pct: int = 0

    grabaciones: list[GrabacionPayload] = Field(default_factory=list)
    evidencias: list[EvidenciaPayload] = Field(default_factory=list)
    hallazgos: list[HallazgoPayload] = Field(default_factory=list)


class VisitaSyncResult(BaseModel):
    codigo_visita: str
    record_id: str
    url: str

    grabaciones: int = 0
    evidencias: int = 0
    hallazgos: int = 0

    # Claves que el modelo devolvio y no estan en el catalogo. No se inventan
    # campos: el hallazgo se descarta y la clave se reporta para que alguien
    # decida si merece entrar al catalogo.
    claves_desconocidas: list[str] = Field(default_factory=list)

    # Hallazgos que bajaron de certeza al aplicar las reglas duras, con el
    # motivo. Se devuelve para que la app lo refleje sin volver a preguntar.
    degradados: list[str] = Field(default_factory=list)


class ArchivoSubido(BaseModel):
    """Resultado de subir un archivo al bucket."""

    url: str
    clave: str
    bytes: int
