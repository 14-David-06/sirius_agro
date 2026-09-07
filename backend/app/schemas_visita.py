"""Payload de sincronizacion de una visita.

Lo manda la app desde su base local, que es la fuente de verdad mientras no
hay senal. Todo es opcional salvo `codigo_visita` a proposito: una visita se
sincroniza tal como este, aunque este a medias. Esperar a que este completa
significaria que un telefono que se moja en el potrero se lleva la visita.

`codigo_visita` es el UUID que genero el telefono antes de tener red. El
backend hace upsert por ese codigo, asi que reintentar nunca duplica.
"""

from datetime import date, datetime

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


class PuntoTrazadoPayload(BaseModel):
    """Un vertice, con la huella de como se capturo.

    `precision_m` y `automatico` no son adorno: son lo que permite decidir, tres
    meses despues, si un lindero raro fue un error del visitador o un salto del
    GPS bajo los arboles. Un area que nadie puede auditar no se puede usar para
    calcular una dosis.
    """

    id: str
    orden: int
    latitud: float
    longitud: float
    altitud: float | None = None
    precision_m: float | None = None
    capturado_en: datetime | None = None

    # false = lo marco el visitador con el boton. true = lo puso el reloj.
    automatico: bool = False
    nota: str | None = None


class TrazadoPayload(BaseModel):
    """El poligono de un lote o el recorrido por el cultivo, caminado a pie.

    Los puntos viajan completos, sin diezmar: el area sale de ellos y la app no
    guarda otra copia del lindero.

    `area_m2` y `perimetro_m` los calcula la app y viajan como referencia. El
    backend puede recalcularlos desde los puntos; si los dos numeros no
    coinciden, manda el que sale de los puntos.
    """

    id: str
    nombre: str
    tipo: str = "Poligono"
    modo_captura: str = "Manual"
    etiqueta: str | None = None
    notas: str | None = None

    # La configuracion con la que se capturo. Se guarda porque explica la
    # figura: un contorno con un punto cada 30 s tiene menos detalle que uno
    # cada 5, y eso no se puede deducir mirando el area.
    intervalo_seg: int | None = None
    distancia_min_m: float | None = None
    precision_max_m: float | None = None

    # Un poligono sin cerrar no es un lote: se lee como recorrido a medias.
    cerrado: bool = True

    area_m2: float | None = None
    area_ha: float | None = None
    perimetro_m: float | None = None
    creado_en: datetime | None = None

    puntos: list[PuntoTrazadoPayload] = Field(default_factory=list)


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


class InformePayload(BaseModel):
    """El informe que se le entrega al agricultor.

    Viaja con la visita en vez de subirse aparte: se genera en el celular, en
    la finca, y tiene que llegar a Airtable por el mismo camino que el resto —
    la cola offline — o se perderia al cerrar la app sin señal.
    """

    id: str
    titulo: str
    tipo: str = "Resumen para el agricultor"
    contenido: str
    version: int = 1
    generado_en: datetime | None = None
    entregado: bool = False
    medio_entrega: str | None = None

    # URL del PDF en el bucket. Solo la trae si el telefono ya alcanzo a
    # subirlo: el PDF va por su propio item de la cola y puede quedar pendiente
    # cuando la visita ya se sincronizo. Vacio no significa que no exista,
    # significa que todavia no subio.
    enlace_pdf: str | None = None


class ProductorPayload(BaseModel):
    """La ficha del agricultor, tal como la llena el modulo de la visita.

    Todo es opcional menos el nombre: la visita crea al productor con lo unico
    que se sabe al llegar a una finca. El `documento` es el que importa —es la
    llave con la que se decide si esta persona ya existe en Airtable— y por eso
    llega desde la app y no se deduce aca.
    """

    nombre_completo: str
    documento: str | None = None
    tipo_documento: str | None = None
    telefono: str | None = None
    telefono_alterno: str | None = None
    genero: str | None = None
    fecha_nacimiento: date | None = None
    nivel_educativo: str | None = None
    anios_experiencia: int | None = None
    personas_hogar: int | None = None

    # Vacio significa que no pertenece a ninguna: de aqui se deriva la casilla
    # `Pertenece a organizacion`, para no pedirle dos veces lo mismo.
    organizacion: str | None = None

    notas: str | None = None

    # Autorizacion de tratamiento (Ley 1581/2012). Va en la persona y no solo
    # en la visita: el permiso de grabar y de fotografiar se pide en cada
    # visita, pero que sus datos se puedan tratar se autoriza una vez.
    consentimiento_datos: bool = False
    fecha_consentimiento: date | None = None

    # URL de la foto de perfil en el bucket. Solo llega si el telefono ya
    # alcanzo a subirla: el retrato va por su propio item de la cola.
    enlace_foto: str | None = None

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
    informes: list[InformePayload] = Field(default_factory=list)

    # Los lotes y recorridos caminados en la finca.
    #
    # Estan tipados y validados, pero TODAVIA NO SE ESCRIBEN EN AIRTABLE: hacen
    # falta las tablas `Trazados` y `Puntos de trazado`, y escribir en un campo
    # que no existe hace que Airtable rechace el registro entero — se perderia
    # la sincronizacion de la visita completa, no solo del poligono.
    #
    # Mientras eso no exista, el lindero no se pierde: vive en la base del
    # telefono y sale en el KML y en el .zip de la visita. Ver
    # `docs/airtable-schema.md`.
    trazados: list[TrazadoPayload] = Field(default_factory=list)


class VisitaSyncResult(BaseModel):
    codigo_visita: str
    record_id: str
    url: str

    grabaciones: int = 0
    evidencias: int = 0
    hallazgos: int = 0
    informes: int = 0

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


class SubidaFirmada(BaseModel):
    """Permiso temporal para que el telefono suba UN archivo al bucket.

    `url_firmada` es contra donde se hace el PUT y vence; `url_publica` es la
    que se guarda y la que Airtable va a usar para buscar el archivo despues.
    Son distintas a proposito: la firmada lleva la autorizacion en la query y
    guardarla seria guardar un enlace que manana no sirve.

    `content_type` va firmado, asi que el PUT tiene que mandar ese mismo header
    o S3 rechaza la subida.
    """

    url_firmada: str
    url_publica: str
    clave: str
    content_type: str
    vence_en: int
