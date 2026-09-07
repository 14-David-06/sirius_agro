"""El directorio de agricultores ya registrados.

Es de solo lectura y va en la direccion contraria a todo lo demas del backend:
aca Airtable es la fuente y el telefono el espejo. Sirve para una sola cosa —
que el visitador que llega a la finca de don Pedro no vuelva a crear a don
Pedro— y por eso trae la ficha entera y no solo el nombre: si el agricultor ya
existe, la segunda visita no deberia volver a preguntarle el documento.

Lo que NO trae: fincas, lotes ni hallazgos. Eso es historia de la finca y se
lee en Airtable; meterlo aca convertiria una ayuda de tecleo en una descarga
de la base entera sobre una red de vereda.
"""

from datetime import date

from pydantic import BaseModel


class ProductorDirectorio(BaseModel):
    """Un agricultor que ya existe en Airtable, como lo ve la app.

    `id` es el record id de Airtable. Es lo que el telefono guarda como
    `remoteId` para poder reconocer a la misma persona la proxima vez sin
    depender del nombre, que se escribe distinto en cada visita.
    """

    id: str
    nombre_completo: str
    codigo_productor: str | None = None
    documento: str | None = None
    tipo_documento: str | None = None
    telefono: str | None = None
    telefono_alterno: str | None = None
    genero: str | None = None
    fecha_nacimiento: date | None = None
    nivel_educativo: str | None = None
    anios_experiencia: int | None = None
    personas_hogar: int | None = None
    organizacion: str | None = None
    consentimiento_datos: bool = False

    # URL del adjunto en Airtable. Es temporal (Airtable las rota), asi que la
    # app la usa para mostrar una cara mientras elige, no para guardarla como
    # si fuera permanente.
    foto_url: str | None = None


class DirectorioProductores(BaseModel):
    productores: list[ProductorDirectorio] = []

    # Cuantos quedaron fuera del limite. La app lo dice en pantalla: un
    # directorio recortado en silencio se ve igual que un agricultor que no
    # esta registrado, y ahi es donde se crea el duplicado.
    truncado: bool = False
