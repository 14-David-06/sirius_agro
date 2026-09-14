"""El chat de la visita: complementar lo que falto y preguntar sobre ella.

Es la tercera cosa que el modelo hace en este sistema, y la unica que ESCRIBE
datos a partir de lo que teclea el visitador. Las otras dos leen: la extraccion
estructura lo que dijo el agricultor en el audio, y el informe lo redacta.

De ahi sale la diferencia que gobierna todo este modulo: **la fuente de estos
datos es el visitador, no el agricultor**. Por eso salen con `fuente = Manual`
y `hablante = visitador`, que no es una etiqueta decorativa — dispara la
primera regla dura del sistema (lo que dice el visitador nunca es `Confirmado`)
tanto en la app como al escribir en Airtable.

Se guarda tambien la conversacion entera, no solo los datos: dentro de seis
meses, un valor que no salio del audio tiene que poder explicarse.
"""

from pydantic import BaseModel, Field

from .schemas import CampoCatalogo

# Cuantos turnos viajan al modelo, igual que en el chat de campo: el hilo
# completo vive en el telefono, aca solo importa que quepa.
MAX_MENSAJES = 30

# Coincide con una opcion de `Informes.Tipo`. La sincronizacion escribe con
# `typecast`, asi que Airtable crea la opcion la primera vez y no hay que
# tocar el esquema a mano.
TIPO_CONVERSACION = "Complemento de la visita"


class MensajeComplemento(BaseModel):
    # "user" o "assistant", como los espera la API de Anthropic.
    rol: str
    contenido: str


class ComplementoRequest(BaseModel):
    codigo_visita: str
    mensajes: list[MensajeComplemento] = Field(default_factory=list)

    # El catalogo activo, que manda la app. Igual que en la extraccion: el
    # esquema se genera desde el, para que el modelo no pueda devolver una
    # clave que la app no sabe donde guardar.
    campos: list[CampoCatalogo] = Field(default_factory=list)

    # Lo que la visita YA tiene registrado, con su certeza, y lo que falta.
    # Sin esto el modelo no puede responder preguntas sobre la visita ni saber
    # que vale la pena preguntarle al visitador.
    contexto: str | None = None

    visitador: str | None = None


class ComplementoResult(BaseModel):
    # Lo que se le muestra al visitador en la burbuja del chat.
    respuesta: str

    # En el MISMO formato que devuelve la extraccion, a proposito: la app los
    # guarda por el camino que ya existe, que es el que aplica las reglas duras
    # y recalcula la completitud.
    hallazgos: list[dict] = Field(default_factory=list)

    temas_pendientes: list[str] = Field(default_factory=list)
    modelo: str
