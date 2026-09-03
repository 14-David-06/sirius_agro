from datetime import datetime

from pydantic import BaseModel, Field

# Es el que promete el guion de consentimiento: "con eso le armo un informe de
# su finca y se lo entrego". Coincide con una opcion de `Informes.Tipo`.
TIPO_AGRICULTOR = "Resumen para el agricultor"


class HallazgoInforme(BaseModel):
    """Un dato extraido, con lo que hace falta para no mentir al escribirlo.

    `certeza` viaja porque el informe NO puede presentar un estimado como si
    fuera un hecho: el agricultor lo va a leer y va a corregir lo que no
    reconozca. Que corrija es bueno; que no note la diferencia, no.
    """

    campo: str
    clave_tecnica: str
    valor: str
    unidad: str | None = None
    certeza: str = "Pendiente"
    modulo: str | None = None


class InformeRequest(BaseModel):
    codigo_visita: str
    fecha: datetime | None = None

    productor: str | None = None
    finca: str | None = None
    vereda: str | None = None
    municipio: str | None = None
    visitador: str | None = None

    # La conversacion completa. Puede venir vacia si todavia no se transcribio:
    # en ese caso el informe se arma solo con los hallazgos.
    transcripcion: str | None = None

    hallazgos: list[HallazgoInforme] = Field(default_factory=list)
    temas_pendientes: str | None = None
    completitud_pct: int = 0


class InformeResult(BaseModel):
    titulo: str
    tipo: str = TIPO_AGRICULTOR

    # Markdown. Es lo que va a `Informes.Contenido` y lo que la app muestra.
    contenido: str
    generado_en: datetime
    modelo: str
