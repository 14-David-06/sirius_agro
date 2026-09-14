"""El historial de un agricultor, leido de Airtable.

Es el segundo servicio que LEE y no escribe, despues del directorio. Existe
porque el visitador llega a una finca que ya fue visitada —por el o por un
companero— y hasta ahora el telefono no tenia forma de saber que se hablo la
vez pasada: la sincronizacion era de una sola via.

Estas visitas bajan como ESPEJO DE CONSULTA. No se editan ni se vuelven a
subir, y esa restriccion no es una limitacion pendiente de levantar: es lo que
hace imposible que traer el historial pise una visita que el visitador todavia
no ha sincronizado. En una vereda sin senal, ese trabajo no tiene papelera de
donde rescatarlo.
"""

from datetime import datetime

from pydantic import BaseModel, Field


class HallazgoRemoto(BaseModel):
    """Un dato de una visita pasada, con su procedencia.

    Viaja con `certeza` por lo mismo que en el informe: un estimado presentado
    como hecho es peor que un dato ausente, y aca ademas nadie estuvo en esa
    conversacion para corregirlo.
    """

    # Solo la clave: el nombre legible del campo y su modulo los pone la app
    # contra su catalogo local, que es donde esos nombres viven de verdad.
    clave_tecnica: str | None = None
    valor_texto: str | None = None
    valor_numerico: float | None = None
    unidad: str | None = None
    certeza: str | None = None
    fuente: str | None = None
    estado: str | None = None
    entidad_destino: str | None = None
    entidad_local_id: str | None = None
    cita_textual: str | None = None
    segundo_audio: int | None = None
    hablante: str | None = None
    razonamiento: str | None = None
    confianza: float | None = None
    valor_corregido: str | None = None


class EvidenciaRemota(BaseModel):
    titulo: str | None = None
    tipo: str | None = None
    tomada_en: datetime | None = None
    latitud: float | None = None
    longitud: float | None = None
    descripcion_visitador: str | None = None
    descripcion_ia: str | None = None
    texto_ocr: str | None = None
    estado_validacion: str | None = None

    # La foto vive en el adjunto de Airtable, que es lo unico que la tabla
    # `Evidencias` guarda de ella. Airtable rota esas URL cada pocas horas, asi
    # que sirve para descargarla AHORA y no para guardarla: el telefono baja el
    # archivo en el momento y despues se queda con el suyo.
    url: str | None = None


class GrabacionRemota(BaseModel):
    orden: int | None = None
    archivo: str | None = None
    inicio: datetime | None = None
    duracion_min: float | None = None
    tamano_mb: float | None = None
    estado: str | None = None
    transcripcion: str | None = None
    transcripcion_marcas: str | None = None
    motor_transcripcion: str | None = None
    idioma: str | None = None

    # Esta si es del bucket y no caduca: es la fuente de verdad del audio.
    url: str | None = None


class InformeRemoto(BaseModel):
    titulo: str | None = None
    tipo: str | None = None
    contenido: str | None = None
    version: int | None = None
    generado_en: datetime | None = None
    entregado: bool = False
    medio_entrega: str | None = None
    enlace_pdf: str | None = None


class VisitaRemota(BaseModel):
    """Una visita ya sincronizada, como la devuelve Airtable.

    `codigo_visita` es el UUID que genero el telefono que la registro. Es la
    llave con la que la app decide si esta visita ya la tiene —y entonces no la
    toca— o si es de otro telefono y puede espejarla.
    """

    codigo_visita: str
    inicio: datetime | None = None
    fin: datetime | None = None
    estado: str | None = None
    tipo_visita: str | None = None
    completitud_pct: int = 0

    latitud: float | None = None
    longitud: float | None = None

    productor: str | None = None
    finca: str | None = None
    # Sin municipio: la app lo resuelve desde su tabla de veredas, igual que el
    # nombre de los campos del catalogo.
    vereda: str | None = None
    visitador: str | None = None

    objetivo: str | None = None
    observaciones: str | None = None
    resumen: str | None = None
    temas_pendientes: str | None = None

    consiente_audio: bool = False
    consiente_fotos: bool = False
    consiente_uso_datos: bool = False
    segundo_consentimiento: int | None = None
    marcada_para_eliminacion: bool = False

    hallazgos: list[HallazgoRemoto] = Field(default_factory=list)
    evidencias: list[EvidenciaRemota] = Field(default_factory=list)
    grabaciones: list[GrabacionRemota] = Field(default_factory=list)
    informes: list[InformeRemoto] = Field(default_factory=list)


class HistorialProductor(BaseModel):
    productor_id: str
    productor: str | None = None
    codigo_productor: str | None = None
    documento: str | None = None

    # De la mas reciente a la mas vieja: quien abre el historial en la finca
    # quiere la ultima visita, no la primera.
    visitas: list[VisitaRemota] = Field(default_factory=list)

    truncado: bool = False
