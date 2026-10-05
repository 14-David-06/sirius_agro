from datetime import datetime

from pydantic import BaseModel, Field


class AsistenciaPayload(BaseModel):
    """Lo que el telefono sabe de un registro de asistencia al subirlo.

    Los datos de la persona NO vienen aqui: la persona los dijo en la nota de
    voz, y es el backend el que los saca de ahi cuando hay red. El telefono
    solo guarda el audio, la firma y el contexto en que se tomaron. Los
    archivos viajan en el mismo multipart, como partes aparte.
    """

    # UUID generado en el telefono antes de tener red. Llave de idempotencia.
    codigo_registro: str = Field(min_length=1)

    registrado_en: datetime
    acepta_terminos: bool
    terminos_url: str | None = None

    # Taller o jornada. Lo escribe el visitador, no la persona.
    evento: str | None = None

    duracion_nota_seg: int | None = None
    latitud: float | None = None
    longitud: float | None = None

    visitador_id_empleado: str | None = None
    visitador_nombre: str | None = None


class DatosAsistencia(BaseModel):
    """Lo que se saco de la nota de voz. Todo opcional: lo que no se dijo o
    no se entendio queda vacio y se anota en `por_confirmar`."""

    nombre_completo: str | None = None
    cedula: str | None = None
    telefono: str | None = None
    correo: str | None = None
    # Nombre exacto de la vereda en la tabla Veredas, o None si no se
    # reconocio.
    vereda: str | None = None
    # Ya no se preguntan en la nota (tampoco la visita). Quedan por los
    # registros viejos, que los traen en Airtable.
    cultivos: list[str] = Field(default_factory=list)
    area_sembrada_ha: float | None = None
    quiere_visita: bool | None = None
    por_confirmar: list[str] = Field(default_factory=list)


class AsistenciaSyncResult(BaseModel):
    record_id: str
    creado: bool
    procesado: bool
    enlace_firma: str | None = None
    enlace_nota_voz: str | None = None
    enlace_foto: str | None = None
    transcripcion: str | None = None
    datos: DatosAsistencia | None = None
