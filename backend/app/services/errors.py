"""Traduce las fallas de los proveedores externos a HTTPException con detalle legible.

Sin esto, un 401 de Anthropic o un timeout de Airtable escapan como un 500 pelado y la
app solo muestra "Internal Server Error", sin pista de que hay que revisar.
"""

import anthropic
import httpx
import openai
from fastapi import HTTPException

# El orden de los `except` importa: en los dos SDK, APITimeoutError hereda de
# APIConnectionError, y AuthenticationError y RateLimitError heredan de APIStatusError.
_TIMEOUT = (anthropic.APITimeoutError, openai.APITimeoutError, httpx.TimeoutException)
_AUTH = (
    anthropic.AuthenticationError,
    anthropic.PermissionDeniedError,
    openai.AuthenticationError,
    openai.PermissionDeniedError,
)
_RATE_LIMIT = (anthropic.RateLimitError, openai.RateLimitError)
_CONNECTION = (anthropic.APIConnectionError, openai.APIConnectionError, httpx.RequestError)
_STATUS = (anthropic.APIStatusError, openai.APIStatusError)


def _detail(exc: Exception) -> str:
    return (getattr(exc, "message", None) or str(exc))[:400]


def upstream_error(service: str, exc: Exception) -> HTTPException:
    """Devuelve la HTTPException que le corresponde a `exc` viniendo de `service`."""
    if isinstance(exc, _TIMEOUT):
        return HTTPException(
            status_code=504,
            detail=f"{service} no respondio a tiempo. Volve a intentar en un momento.",
        )
    if isinstance(exc, _AUTH):
        # La llave vive en el backend, asi que esto es configuracion nuestra, no del proveedor.
        return HTTPException(
            status_code=500,
            detail=f"Las credenciales de {service} son invalidas. Revisa el .env del backend.",
        )
    if isinstance(exc, _RATE_LIMIT):
        return HTTPException(
            status_code=429,
            detail=f"{service} esta limitando las peticiones. Espera unos minutos y reintenta.",
        )
    if isinstance(exc, _CONNECTION):
        return HTTPException(
            status_code=502,
            detail=f"No se pudo conectar con {service}: {_detail(exc)}",
        )
    if isinstance(exc, _STATUS):
        return HTTPException(
            status_code=502,
            detail=f"{service} respondio {exc.status_code}: {_detail(exc)}",
        )
    return HTTPException(status_code=502, detail=f"Fallo inesperado de {service}: {_detail(exc)}")


UPSTREAM_EXCEPTIONS = (anthropic.APIError, openai.APIError, httpx.HTTPError)
