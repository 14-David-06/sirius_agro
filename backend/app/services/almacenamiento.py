"""Bucket S3 para audio y fotos.

El audio vive aca, no en Airtable: los adjuntos de Airtable topan en 5 MB por
archivo y sus URLs expiran en horas. Una conversacion de 30 min pesa ~7 MB, asi
que si el audio solo viviera en el adjunto, en unos meses no se podria volver a
escuchar la cita que respalda un dato — y ahi se cae toda la procedencia.

Las credenciales solo existen aca. La app sube contra el backend, nunca contra
S3 directo: una llave de bucket dentro de un APK que anda en el bolsillo de
alguien es una llave publica.
"""

import mimetypes
from functools import lru_cache

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException

from ..config import Settings
from ..schemas_visita import ArchivoSubido

# Extensiones que se aceptan, con su tipo. Se decide aca y no por lo que diga
# el cliente: el Content-Type que manda un cliente es un dato, no una garantia,
# y de esto depende que el navegador reproduzca el audio en vez de descargarlo.
_TIPOS = {
    ".m4a": "audio/mp4",
    ".mp4": "audio/mp4",
    ".aac": "audio/aac",
    ".wav": "audio/wav",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
}


def configurado(settings: Settings) -> bool:
    """El endpoint no entra: en AWS es opcional.

    Los compatibles (R2, B2, MinIO) exigen endpoint; AWS lo deduce de la
    region. Exigirlo dejaria fuera al proveedor mas comun por nada.
    """
    return bool(
        settings.bucket_name
        and settings.bucket_access_key
        and settings.bucket_secret_key
    )


@lru_cache
def _cliente(endpoint: str, access_key: str, secret_key: str, region: str):
    """Cliente S3 cacheado: crearlo por peticion agrega latencia por nada.

    El estilo de direccionamiento depende del proveedor: los compatibles (R2,
    B2, MinIO) no siempre resuelven el virtual-host y necesitan `path`, pero
    AWS lleva anios empujando el virtual-host y `path` es su camino
    obsoleto. Se elige por si hay endpoint propio o no.
    """
    estilo = "path" if endpoint else "auto"
    return boto3.client(
        "s3",
        # None y no "": boto3 arma el endpoint de AWS a partir de la region,
        # y una cadena vacia lo rompe en vez de dejarlo deducir.
        endpoint_url=endpoint or None,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        region_name=region,
        config=Config(
            signature_version="s3v4",
            s3={"addressing_style": estilo},
            retries={"max_attempts": 3, "mode": "standard"},
        ),
    )


def _tipo(nombre: str) -> str:
    for ext, mime in _TIPOS.items():
        if nombre.lower().endswith(ext):
            return mime
    adivinado, _ = mimetypes.guess_type(nombre)
    return adivinado or "application/octet-stream"


_PREFIJO = {"audio": "tramo", "fotos": "foto"}


def nombre_ordenado(categoria: str, nombre: str, orden: int | None) -> str:
    """Renombra el archivo a `foto-03.jpg` / `tramo-02.m4a`.

    La camara nombra las fotos `foto-1788370464996.jpg` con el reloj en
    milisegundos. Ordena bien, pero no le dice nada a nadie: quien abra el
    bucket a los seis meses para buscar la etiqueta de un insumo ve cuatro
    numeros de trece digitos.

    Se rellena con cero a dos digitos porque S3 ordena como texto: sin el
    cero, `foto-10` queda antes que `foto-2`.

    Sin `orden` se conserva el nombre original: es preferible un nombre feo a
    inventar una posicion que no se sabe.
    """
    if orden is None:
        return nombre
    extension = nombre.rsplit(".", 1)[-1].lower() if "." in nombre else "bin"
    return f"{_PREFIJO.get(categoria, 'archivo')}-{orden:02d}.{extension}"


def clave_de(
    codigo_visita: str,
    categoria: str,
    nombre: str,
    orden: int | None = None,
) -> str:
    """Ruta dentro del bucket.

    Se agrupa por visita, y la visita va como primer segmento a proposito:
    borrar una visita revocada tiene que ser borrar un prefijo, no rastrear
    archivos sueltos. `Marcada para eliminacion` no se puede cumplir a medias.

    Por eso la fecha NO va en la ruta aunque haria el bucket mas legible: se
    perderia esa propiedad. Para buscar por fecha o por productor esta
    Airtable, que es donde alguien busca de verdad.
    """
    limpio = (
        nombre_ordenado(categoria, nombre, orden)
        .replace("/", "-")
        .replace("\\", "-")
        .strip()
        or "archivo"
    )
    return f"visitas/{codigo_visita}/{categoria}/{limpio}"


def url_publica(settings: Settings, clave: str) -> str:
    """URL con la que Airtable va a buscar el archivo.

    Airtable carga un adjunto yendo el mismo a la URL desde sus servidores, asi
    que tiene que ser alcanzable desde internet. Si el bucket es privado hay
    que poner `BUCKET_PUBLIC_URL` apuntando al dominio publico o al CDN; el
    endpoint interno no le sirve a Airtable.
    """
    base = (settings.bucket_public_url or "").rstrip("/")
    if base:
        return f"{base}/{clave}"

    if settings.bucket_endpoint:
        endpoint = settings.bucket_endpoint.rstrip("/")
        return f"{endpoint}/{settings.bucket_name}/{clave}"

    # AWS sin endpoint explicito: el dominio virtual-host del bucket. Se usa
    # este y no el de estilo path porque es el que AWS mantiene vigente.
    return (
        f"https://{settings.bucket_name}.s3.{settings.bucket_region}"
        f".amazonaws.com/{clave}"
    )


def subir(
    settings: Settings,
    contenido: bytes,
    codigo_visita: str,
    categoria: str,
    nombre: str,
    orden: int | None = None,
) -> ArchivoSubido:
    if not configurado(settings):
        raise HTTPException(
            status_code=500,
            detail=(
                "El bucket no esta configurado: faltan BUCKET_NAME, "
                "BUCKET_ACCESS_KEY o BUCKET_SECRET_KEY en el backend."
            ),
        )
    if not contenido:
        raise HTTPException(status_code=400, detail="El archivo llego vacio.")

    clave = clave_de(codigo_visita, categoria, nombre, orden)
    cliente = _cliente(
        settings.bucket_endpoint,
        settings.bucket_access_key,
        settings.bucket_secret_key,
        settings.bucket_region,
    )

    try:
        cliente.put_object(
            Bucket=settings.bucket_name,
            Key=clave,
            Body=contenido,
            ContentType=_tipo(nombre),
        )
    except (BotoCoreError, ClientError) as exc:
        raise HTTPException(
            status_code=502, detail=f"El bucket rechazo la subida: {exc}"
        ) from exc

    return ArchivoSubido(
        url=url_publica(settings, clave), clave=clave, bytes=len(contenido)
    )


def borrar_visita(settings: Settings, codigo_visita: str) -> int:
    """Borra todo el audio y las fotos de una visita revocada.

    Existe para poder cumplir `Marcada para eliminacion` de verdad: el
    productor que revoca el consentimiento tiene derecho a que el audio
    desaparezca, no a que se le quite un enlace de una tabla.
    """
    if not configurado(settings):
        return 0

    cliente = _cliente(
        settings.bucket_endpoint,
        settings.bucket_access_key,
        settings.bucket_secret_key,
        settings.bucket_region,
    )
    prefijo = f"visitas/{codigo_visita}/"
    borrados = 0

    try:
        paginas = cliente.get_paginator("list_objects_v2").paginate(
            Bucket=settings.bucket_name, Prefix=prefijo
        )
        for pagina in paginas:
            claves = [{"Key": o["Key"]} for o in pagina.get("Contents", [])]
            if not claves:
                continue
            # delete_objects topa en 1000 llaves por llamada.
            for i in range(0, len(claves), 1000):
                cliente.delete_objects(
                    Bucket=settings.bucket_name,
                    Delete={"Objects": claves[i : i + 1000]},
                )
            borrados += len(claves)
    except (BotoCoreError, ClientError) as exc:
        raise HTTPException(
            status_code=502, detail=f"El bucket rechazo el borrado: {exc}"
        ) from exc

    return borrados
