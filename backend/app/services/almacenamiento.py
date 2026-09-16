"""Bucket S3 para audio y fotos.

El audio vive aca, no en Airtable: los adjuntos de Airtable topan en 5 MB por
archivo y sus URLs expiran en horas. Una conversacion de 30 min pesa ~7 MB, asi
que si el audio solo viviera en el adjunto, en unos meses no se podria volver a
escuchar la cita que respalda un dato — y ahi se cae toda la procedencia.

Las credenciales solo existen aca. La app sube contra el backend, nunca contra
S3 directo: una llave de bucket dentro de un APK que anda en el bolsillo de
alguien es una llave publica.

La excepcion es el PDF del informe, que sube con una URL prefirmada (ver
`firmar_subida`). No rompe la regla: una URL firmada no es una llave, es un
permiso que vence y que solo sirve para UNA ruta. El informe lleva las fotos
embebidas y pesa mas que el cuerpo maximo que admite el host, asi que no puede
pasar por el backend; y no queremos regenerarlo aca, porque el documento que
respalda lo acordado es el que el productor tiene en la mano.
"""

import mimetypes
from collections.abc import AsyncIterator
from functools import lru_cache
from urllib.parse import urlparse

import boto3
import httpx
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException

from ..config import Settings
from ..schemas_visita import ArchivoSubido, SubidaFirmada

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
    # El informe que se le entrega al agricultor. Se archiva el PDF exacto que
    # se compartio, no uno regenerado: el documento que respalda lo acordado
    # en la finca es el que el productor tiene en la mano.
    ".pdf": "application/pdf",
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


_PREFIJO = {
    "audio": "tramo",
    "fotos": "foto",
    "informes": "informe",
    # El informe tecnico de la empresa. Carpeta y prefijo propios: comparte
    # visita y numero de version con el del agricultor, asi que con el mismo
    # nombre el segundo que subiera borraria al primero.
    "informes_tecnicos": "informe-tecnico",
}


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


# Cuanto vive la URL firmada. Quince minutos: el telefono la pide y sube en
# seguida, pero en una vereda con una barra la subida de un PDF con fotos puede
# arrastrarse. El plazo cubre el reintento inmediato sin dejar tirado un permiso
# de escritura que sirva manana.
_VENCIMIENTO_FIRMA = 15 * 60


def firmar_subida(
    settings: Settings,
    codigo_visita: str,
    categoria: str,
    nombre: str,
    orden: int | None = None,
) -> SubidaFirmada:
    """Firma un PUT para que el telefono suba directo al bucket.

    Es para el PDF del informe: lleva las fotos embebidas a resolucion completa
    y pesa mas que el cuerpo maximo del host (4,5 MB en Vercel, que es limite
    de infraestructura y no se configura), asi que no cabe por `/v1/archivos`.

    La clave la arma el backend, nunca el cliente: la firma autoriza esa ruta y
    solo esa. Si el telefono pudiera elegirla, podria escribir sobre el audio de
    otra visita — y el `Content-Type` va dentro de la firma por lo mismo, para
    que el objeto no quede como `application/octet-stream` y el navegador lo
    descargue en vez de abrirlo.
    """
    if not configurado(settings):
        raise HTTPException(
            status_code=500,
            detail=(
                "El bucket no esta configurado: faltan BUCKET_NAME, "
                "BUCKET_ACCESS_KEY o BUCKET_SECRET_KEY en el backend."
            ),
        )

    clave = clave_de(codigo_visita, categoria, nombre, orden)
    tipo = _tipo(nombre)
    cliente = _cliente(
        settings.bucket_endpoint,
        settings.bucket_access_key,
        settings.bucket_secret_key,
        settings.bucket_region,
    )

    try:
        firmada = cliente.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": settings.bucket_name,
                "Key": clave,
                "ContentType": tipo,
            },
            ExpiresIn=_VENCIMIENTO_FIRMA,
        )
    except (BotoCoreError, ClientError) as exc:
        raise HTTPException(
            status_code=502, detail=f"El bucket no dio la firma: {exc}"
        ) from exc

    return SubidaFirmada(
        url_firmada=firmada,
        url_publica=url_publica(settings, clave),
        clave=clave,
        content_type=tipo,
        vence_en=_VENCIMIENTO_FIRMA,
    )


def borrar_visita(settings: Settings, codigo_visita: str) -> int:
    """Borra el audio, las fotos y el informe de una visita revocada.

    Existe para poder cumplir `Marcada para eliminacion` de verdad: el
    productor que revoca el consentimiento tiene derecho a que el audio
    desaparezca, no a que se le quite un enlace de una tabla.

    Barre por prefijo, asi que cubre las categorias que existan hoy y las que
    se agreguen: por eso la visita va como primer segmento de la clave.
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


# Los unicos destinos de los que el backend acepta traer un archivo ajeno.
#
# La lista no es burocracia: sin ella `?url=` convierte al backend en un
# mensajero que va a donde le digan, incluida la red interna del host. Airtable
# rota el dominio de sus adjuntos por version (v5, v6...), asi que se compara
# por sufijo de dominio y no por igualdad.
_DOMINIOS_DE_ADJUNTOS = ("airtableusercontent.com", "airtable.com")


def _destino_permitido(settings: Settings, url: str) -> str:
    """El host de [url] si se le puede pedir un archivo, o revienta con 400."""
    partes = urlparse(url)
    if partes.scheme != "https" or not partes.hostname:
        raise HTTPException(
            status_code=400,
            detail="Solo se bajan archivos por https con dominio explicito.",
        )

    host = partes.hostname.lower()

    # El host del bucket se deriva de `url_publica` y no se arma aparte: es la
    # misma funcion que decide donde quedan los archivos al subirlos, asi que
    # no pueden desalinearse. Configurar un CDN nuevo y que el proxy siga
    # aceptando el dominio viejo seria justo el fallo que esto evita.
    propios = {h for h in (urlparse(url_publica(settings, "")).hostname,) if h}
    propios |= {
        h
        for h in (
            urlparse(settings.bucket_public_url).hostname,
            urlparse(settings.bucket_endpoint).hostname,
        )
        if h
    }

    permitido = host in propios or any(
        host == d or host.endswith(f".{d}") for d in _DOMINIOS_DE_ADJUNTOS
    )
    if not permitido:
        raise HTTPException(
            status_code=400,
            detail=f"No se bajan archivos de {host}.",
        )
    return host


async def abrir_remoto(settings: Settings, url: str) -> tuple[AsyncIterator[bytes], str, int | None]:
    """Abre el archivo de [url] y devuelve sus bytes, su tipo y su tamano.

    Existe porque el telefono no siempre alcanza a Airtable ni al bucket: en el
    campo va por la red de la finca, y conectado por USB no tiene mas salida
    que este backend. Bajar por el mismo canal que el resto de la API es lo que
    hace que ver una foto del historial funcione siempre que funcione la app.
    """
    _destino_permitido(settings, url)

    cliente = httpx.AsyncClient(timeout=httpx.Timeout(60.0, connect=10.0))
    try:
        peticion = cliente.build_request("GET", url)
        respuesta = await cliente.send(peticion, stream=True)
    except httpx.HTTPError as exc:
        await cliente.aclose()
        raise HTTPException(
            status_code=502, detail=f"No se pudo bajar el archivo: {exc}"
        ) from exc

    if respuesta.status_code >= 400:
        estado = respuesta.status_code
        await respuesta.aclose()
        await cliente.aclose()
        # 404 en un adjunto de Airtable casi siempre es una URL vencida: las
        # rota cada pocas horas y la que guardo el telefono ya no sirve. Hay
        # que volver a pedir el detalle de la visita, no reintentar esta.
        raise HTTPException(
            status_code=502 if estado >= 500 else 404,
            detail=(
                f"El origen respondio {estado}. Si es un adjunto de Airtable, "
                "el enlace ya vencio: vuelve a pedir el detalle de la visita."
            ),
        )

    tipo = respuesta.headers.get("content-type", "application/octet-stream")
    largo = respuesta.headers.get("content-length")

    async def bytes_del_origen() -> AsyncIterator[bytes]:
        try:
            async for trozo in respuesta.aiter_bytes():
                yield trozo
        finally:
            await respuesta.aclose()
            await cliente.aclose()

    return bytes_del_origen(), tipo, int(largo) if largo and largo.isdigit() else None
