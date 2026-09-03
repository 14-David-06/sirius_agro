from pydantic import BaseModel, Field

# Cuantos turnos viajan al modelo. La conversacion completa se guarda en el
# telefono; aca solo importa que el hilo quepa y no crezca sin techo.
MAX_MENSAJES = 40


class MensajeChat(BaseModel):
    # "user" o "assistant". Es lo que espera la API de Anthropic tal cual.
    rol: str
    contenido: str


class ChatRequest(BaseModel):
    mensajes: list[MensajeChat] = Field(default_factory=list)

    # Quien pregunta, para que el modelo no lo trate como si fuera el
    # agricultor. Opcional: si la sesion no esta a mano el chat igual sirve.
    visitador: str | None = None

    # Resumen de las visitas del dispositivo, armado por la app. Sin esto el
    # chat responde agronomia general; con esto responde sobre estas fincas.
    contexto: str | None = None


class ChatResult(BaseModel):
    respuesta: str
    modelo: str
