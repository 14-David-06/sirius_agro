"""El chat que el visitador consulta en campo.

Es la unica parte de la app donde el modelo habla con el visitador y no del
agricultor. Por eso el prompt es corto y la regla principal es la contraria a
la del informe: aca SI puede aportar conocimiento agronomico general, siempre
que quede claro que es general y no una observacion de esta finca.
"""

from anthropic import AsyncAnthropic
from fastapi import HTTPException

from ..config import Settings
from ..schemas_chat import MAX_MENSAJES, ChatRequest, ChatResult
from .errors import UPSTREAM_EXCEPTIONS, upstream_error

SYSTEM = """Sos el asistente de campo de Sirius Regenerative. Hablas con el
VISITADOR — el tecnico que esta en la finca —, no con el agricultor.

Como respondes:
- En espanol, directo y corto. El visitador te lee de pie, con el telefono en
  una mano y bajo el sol. Tres parrafos son muchos.
- Agronomia regenerativa aplicada: suelo, agua, coberturas, biofertilizantes,
  manejo de potreros, biochar. Si la pregunta es de otro tema, respondela igual
  si podes ayudar, sin dar rodeos.
- Si te preguntan por una finca o una visita, respondes SOLO con lo que este en
  el contexto que te pasaron. Si el dato no esta, decis que no esta registrado
  y sugeris que lo pregunte en la proxima visita. No lo completes de memoria.
- Distingui siempre lo general de lo de esta finca. "En general, un suelo asi
  responde a..." es distinto de "en esta finca vimos...", y confundirlos hace
  que el visitador le repita al productor algo que nadie observo.
- No prometas nada en nombre de Sirius: ni precios, ni productos, ni plazos,
  ni fechas de visita.
- Si no sabes, decilo en una linea. Es mas util que una respuesta larga que
  suene bien.
- Texto plano. La app muestra la respuesta en una burbuja de chat: no hay
  titulos ni tablas que renderizar. Vinetas con "- " y, si algo tiene que
  resaltar, negrita con **dobles asteriscos**. Nada mas."""


def _system(req: ChatRequest) -> str:
    partes = [SYSTEM]
    if req.visitador:
        partes.append(f"Estas hablando con {req.visitador}.")
    if req.contexto:
        partes.append(
            "CONTEXTO DE LAS VISITAS DE ESTE DISPOSITIVO\n"
            "(Es todo lo que sabes de estas fincas. Lo que no este aca, no lo "
            "sabes.)\n" + req.contexto
        )
    return "\n\n".join(partes)


async def responder(settings: Settings, req: ChatRequest) -> ChatResult:
    if not settings.anthropic_api_key:
        raise HTTPException(
            status_code=500, detail="Falta ANTHROPIC_API_KEY en el backend."
        )

    mensajes = [
        {"role": m.rol, "content": m.contenido}
        for m in req.mensajes[-MAX_MENSAJES:]
        if m.contenido.strip()
    ]
    # La API rechaza un hilo vacio o que no arranque con el usuario, y ese 400
    # llegaria a la app como un error de proveedor sin sentido para nadie.
    if not mensajes or mensajes[0]["role"] != "user":
        raise HTTPException(
            status_code=400, detail="El chat empieza con un mensaje del visitador."
        )

    cliente = AsyncAnthropic(api_key=settings.anthropic_api_key)
    try:
        respuesta = await cliente.messages.create(
            model=settings.claude_model,
            max_tokens=1500,
            system=_system(req),
            messages=mensajes,
        )
    except UPSTREAM_EXCEPTIONS as exc:
        raise upstream_error("Anthropic", exc) from exc

    texto = "".join(
        bloque.text for bloque in respuesta.content if bloque.type == "text"
    ).strip()

    if not texto:
        raise HTTPException(
            status_code=502, detail="El modelo devolvio una respuesta vacia."
        )

    return ChatResult(respuesta=texto, modelo=settings.claude_model)
