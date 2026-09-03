"""Login contra `Sirius Nomina Core` → `Personal`.

Por que vive en el backend y no en la app: verificar la contrasena exige leer
la tabla `Personal`, y leerla exige el PAT de Airtable. Un PAT dentro de un APK
que anda en el bolsillo de alguien es un PAT publico, y ese PAT abre la nomina
entera — salarios, cuentas bancarias, documentos. La app nunca lo ve.

El hash lo escribe una app de Next.js con bcrypt. Aca solo se verifica; esta
base es de **solo lectura** para el agro: si alguien cambia de contrasena, se
cambia en nomina.
"""

from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass
from urllib.parse import quote

import bcrypt
import httpx
from fastapi import HTTPException

from ..config import Settings
from .errors import UPSTREAM_EXCEPTIONS, upstream_error

API = "https://api.airtable.com/v0"

CAMPO_ID_EMPLEADO = "ID Empleado"
CAMPO_DOCUMENTO = "Numero Documento"
CAMPO_NOMBRE = "Nombre completo"
CAMPO_EMAIL = "Correo electrónico"
CAMPO_PASSWORD = "Password"
CAMPO_ESTADO = "Estado de actividad"
CAMPO_NIVEL = "Nivel Acceso (from Nivel_Sistema_Nuevo)"
CAMPO_ORDEN_NIVEL = "Orden Nivel (from Nivel_Sistema_Nuevo)"
CAMPO_ROL = "Rol (from Rol)"

ESTADO_ACTIVO = "Activo"

# bcrypt marca su propio formato. Se exige el prefijo en vez de intentar
# verificar a ciegas: si un registro quedo en texto plano, tiene que fallar
# ruidosamente y no compararse contra nada.
# Solo las revisiones que el paquete `bcrypt` de Dart sabe verificar: si el
# backend aceptara una que la app no, el login online pasaria y el offline no.
_BCRYPT = re.compile(r"^\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}$")


@dataclass(frozen=True)
class Empleado:
    id_empleado: str
    # Normalizada a digitos: es la llave del login y de la copia local.
    cedula: str
    nombre: str
    email: str
    rol: str
    nivel_acceso: str
    orden_nivel: int
    hash_bcrypt: str


def _texto(valor: object) -> str:
    """Airtable devuelve los lookup como lista y los vacios como ausentes."""
    if isinstance(valor, list):
        return str(valor[0]).strip() if valor else ""
    if isinstance(valor, dict):
        return str(valor.get("name", "")).strip()
    return str(valor).strip() if valor is not None else ""


def _entero(valor: object, por_defecto: int) -> int:
    texto = _texto(valor)
    try:
        return int(float(texto))
    except (TypeError, ValueError):
        return por_defecto


def solo_digitos(valor: str) -> str:
    """La cedula, sin puntos, espacios ni guiones.

    En nomina `Numero Documento` es texto libre, asi que hay registros con
    `1.234.567` y otros con `1234567`. Comparar en crudo haria que poder
    entrar dependiera de como la tecleo quien cargo la nomina.

    Normalizar tambien cierra la puerta a inyectar en la formula: lo que
    llega a Airtable no puede tener otra cosa que digitos.
    """
    return re.sub(r"\D", "", valor or "")


async def _buscar(settings: Settings, cedula: str) -> dict | None:
    """Trae el registro de `Personal` cuya cedula coincide.

    Se normalizan LOS DOS lados: el numero que llega y el que esta guardado.
    La formula le pide a Airtable que quite puntos, guiones y espacios antes
    de comparar.
    """
    numero = solo_digitos(cedula)
    if not numero:
        return None

    campo = f"{{{CAMPO_DOCUMENTO}}}"
    for basura in (".", "-", " "):
        campo = f'SUBSTITUTE({campo},"{basura}","")'
    formula = f"{campo}='{numero}'"

    tabla = quote(settings.nomina_table, safe="")
    url = f"{API}/{settings.nomina_base_id}/{tabla}"
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            respuesta = await client.get(
                url,
                headers={"Authorization": f"Bearer {settings.nomina_token}"},
                params={"filterByFormula": formula, "maxRecords": 1},
            )
    except UPSTREAM_EXCEPTIONS as exc:
        raise upstream_error("Airtable (nomina)", exc) from exc

    if respuesta.status_code >= 400:
        raise HTTPException(
            status_code=502,
            detail=(
                f"Nomina respondio {respuesta.status_code}. "
                "Revisa NOMINA_TOKEN y NOMINA_BASE_ID en el .env del backend."
            ),
        )

    registros = respuesta.json().get("records", [])
    return registros[0] if registros else None


def _verificar(password: str, hash_guardado: str) -> bool:
    """bcrypt es lento a proposito (~100 ms), asi que no bloquea el event loop."""
    return bcrypt.checkpw(password.encode("utf-8"), hash_guardado.encode("utf-8"))


async def autenticar(settings: Settings, cedula: str, password: str) -> Empleado:
    if not settings.nomina_token or not settings.nomina_base_id:
        raise HTTPException(
            status_code=500,
            detail="Falta configuracion de nomina: NOMINA_TOKEN y NOMINA_BASE_ID.",
        )
    if not solo_digitos(cedula) or not password:
        raise HTTPException(status_code=400, detail="Faltan cedula o contrasena.")

    registro = await _buscar(settings, cedula)

    # Mismo mensaje para "no existe" y "contrasena mala": decir cual de las dos
    # fallo convierte el login en un verificador de quien trabaja en la empresa.
    generico = HTTPException(status_code=401, detail="Cedula o contrasena incorrectos.")
    if registro is None:
        raise generico

    campos = registro.get("fields", {})
    guardado = _texto(campos.get(CAMPO_PASSWORD))

    if not guardado:
        raise HTTPException(
            status_code=403,
            detail=(
                "Esa persona no tiene contrasena en nomina. "
                "Hay que asignarsela en Sirius Nomina Core antes de entrar."
            ),
        )
    if not _BCRYPT.match(guardado):
        # No se intenta comparar en texto plano ni migrar el valor al vuelo: si
        # el registro no esta hasheado, es un problema de nomina y se dice.
        raise HTTPException(
            status_code=500,
            detail=(
                "La contrasena de esa persona no esta hasheada con bcrypt en "
                "nomina. La app no compara contrasenas en texto plano."
            ),
        )

    if not await asyncio.to_thread(_verificar, password, guardado):
        raise generico

    # El estado se mira DESPUES de verificar la contrasena: si se mirara antes,
    # el error distinto revelaria quien esta de baja sin saber la contrasena.
    estado = _texto(campos.get(CAMPO_ESTADO))
    if estado != ESTADO_ACTIVO:
        raise HTTPException(
            status_code=403,
            detail=f"Esa persona esta «{estado or 'sin estado'}» en nomina, no activa.",
        )

    return Empleado(
        id_empleado=_texto(campos.get(CAMPO_ID_EMPLEADO)),
        cedula=solo_digitos(_texto(campos.get(CAMPO_DOCUMENTO))),
        nombre=_texto(campos.get(CAMPO_NOMBRE)),
        email=_texto(campos.get(CAMPO_EMAIL)),
        rol=_texto(campos.get(CAMPO_ROL)),
        nivel_acceso=_texto(campos.get(CAMPO_NIVEL)),
        # Sin nivel, el menos privilegiado. Nunca al reves: un lookup vacio no
        # puede convertir a alguien en Super Admin.
        orden_nivel=_entero(campos.get(CAMPO_ORDEN_NIVEL), 99),
        hash_bcrypt=guardado,
    )
