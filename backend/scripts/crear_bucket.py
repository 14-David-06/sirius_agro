"""Crea y configura el bucket S3 de audio y fotos, y verifica que sirva.

    python scripts/crear_bucket.py            # crea y configura
    python scripts/crear_bucket.py --verificar # solo comprueba lo que ya hay

Lee las credenciales de `backend/.env`. No pide nada por consola ni imprime
llaves.

Sobre el modelo de acceso, que es la decision que importa:

El bucket queda con **lectura publica de objetos pero sin listado**. Airtable
carga un adjunto yendo el mismo a la URL desde sus servidores, y ademas
`Grabaciones.Enlace de audio` tiene que seguir funcionando dentro de meses para
poder volver a escuchar la cita que respalda un dato. Una URL prefirmada expira
y no sirve para lo segundo.

Que no haya listado es lo que protege: las rutas son
`visitas/<uuid v4>/audio/...`, asi que sin poder listar el bucket no hay forma
de descubrir una grabacion. El modelo de seguridad es el de un enlace no
publicado, no el de un archivo abierto al mundo. Si eso no alcanza para el
piloto, la alternativa es bucket cerrado + backend que redirige con URL
prefirmada, y eso exige tener el backend desplegado.
"""

import argparse
import json
import sys
import uuid
from pathlib import Path

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.config import Settings  # noqa: E402


def _cliente(s: Settings):
    return boto3.client(
        "s3",
        endpoint_url=s.bucket_endpoint or None,
        aws_access_key_id=s.bucket_access_key,
        aws_secret_access_key=s.bucket_secret_key,
        region_name=s.bucket_region,
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )


def detectar_region(s: Settings) -> str | None:
    """Pregunta a AWS en que region esta el bucket.

    Quien crea el bucket en la consola no siempre sabe que region le toco, y
    apuntar a la equivocada da un PermanentRedirect que no dice cual es la
    correcta. Es un dato que AWS ya tiene: se le pregunta.
    """
    if s.bucket_endpoint:
        # Los compatibles no implementan get_bucket_location de forma util.
        return s.bucket_region

    sonda = boto3.client(
        "s3",
        aws_access_key_id=s.bucket_access_key,
        aws_secret_access_key=s.bucket_secret_key,
        region_name="us-east-1",
        config=Config(signature_version="s3v4"),
    )
    try:
        r = sonda.get_bucket_location(Bucket=s.bucket_name)
    except ClientError as e:
        if e.response["Error"]["Code"] in ("NoSuchBucket", "404"):
            return None
        raise
    # us-east-1 se reporta como None, que es la rareza historica de S3.
    return r.get("LocationConstraint") or "us-east-1"


def _politica(bucket: str) -> dict:
    """Lectura publica de objetos, y solo de objetos.

    No se concede `s3:ListBucket` a proposito: sin listado, las rutas con UUID
    v4 no se pueden descubrir. Conceder el listado convertiria el bucket en un
    indice de todas las conversaciones del piloto.
    """
    return {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "LecturaPublicaDeObjetos",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": f"arn:aws:s3:::{bucket}/visitas/*",
            }
        ],
    }


def crear(s: Settings) -> None:
    c = _cliente(s)
    bucket = s.bucket_name

    try:
        # us-east-1 es el unico que NO acepta LocationConstraint. Mandarlo
        # ahi da InvalidLocationConstraint, que no explica nada.
        if s.bucket_region == "us-east-1":
            c.create_bucket(Bucket=bucket)
        else:
            c.create_bucket(
                Bucket=bucket,
                CreateBucketConfiguration={"LocationConstraint": s.bucket_region},
            )
        print(f"[ok] bucket creado: {bucket} ({s.bucket_region})")
    except ClientError as e:
        codigo = e.response["Error"]["Code"]
        if codigo in ("BucketAlreadyOwnedByYou", "BucketAlreadyExists"):
            print(f"[ok] el bucket ya existia: {bucket}")
        else:
            raise

    # Cifrado en reposo. Son conversaciones con personas identificables sobre
    # su tierra y su situacion: el default correcto es cifrado.
    c.put_bucket_encryption(
        Bucket=bucket,
        ServerSideEncryptionConfiguration={
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"},
                    "BucketKeyEnabled": True,
                }
            ]
        },
    )
    print("[ok] cifrado en reposo activado (AES256)")

    # Versionado: un reintento de la cola sobreescribe la misma llave, y un
    # audio pisado por una subida a medias no se recupera de ningun lado.
    c.put_bucket_versioning(
        Bucket=bucket, VersioningConfiguration={"Status": "Enabled"}
    )
    print("[ok] versionado activado")

    # Se bloquean las ACL publicas pero se permite la politica de bucket: es
    # la unica combinacion con la que se puede dar lectura de objetos sin
    # abrir tambien las ACL por objeto.
    c.put_public_access_block(
        Bucket=bucket,
        PublicAccessBlockConfiguration={
            "BlockPublicAcls": True,
            "IgnorePublicAcls": True,
            "BlockPublicPolicy": False,
            "RestrictPublicBuckets": False,
        },
    )
    print("[ok] ACL publicas bloqueadas, politica de bucket permitida")

    c.put_bucket_policy(Bucket=bucket, Policy=json.dumps(_politica(bucket)))
    print("[ok] politica aplicada: GetObject publico en visitas/*, sin listado")

    # Sin CORS, un navegador que intente reproducir el audio desde otra pagina
    # recibe el archivo pero no lo puede leer.
    c.put_bucket_cors(
        Bucket=bucket,
        CORSConfiguration={
            "CORSRules": [
                {
                    "AllowedHeaders": ["*"],
                    "AllowedMethods": ["GET", "HEAD"],
                    "AllowedOrigins": ["*"],
                    "MaxAgeSeconds": 3600,
                }
            ]
        },
    )
    print("[ok] CORS de lectura configurado")


def verificar(s: Settings) -> bool:
    """Sube un archivo de prueba, lo lee por la URL publica y lo borra.

    Es la unica comprobacion que vale: que la politica este puesta no
    garantiza que Airtable pueda descargar el archivo, y descubrir eso a mitad
    de una visita en campo es tarde.
    """
    import urllib.error
    import urllib.request

    from app.services import almacenamiento

    c = _cliente(s)
    clave = f"visitas/prueba-{uuid.uuid4()}/audio/prueba.txt"
    contenido = b"prueba de sirius agro"
    ok = True

    c.put_object(
        Bucket=s.bucket_name, Key=clave, Body=contenido, ContentType="text/plain"
    )
    print(f"[ok] subida: {clave}")

    url = almacenamiento.url_publica(s, clave)
    print(f"     URL publica: {url}")
    try:
        with urllib.request.urlopen(url, timeout=15) as r:
            leido = r.read()
        if leido == contenido:
            print("[ok] Airtable va a poder descargar el archivo")
        else:
            print("[FALLA] la URL respondio pero con otro contenido")
            ok = False
    except urllib.error.HTTPError as e:
        print(f"[FALLA] la URL publica respondio {e.code}: {e.reason}")
        print("        Revisa BUCKET_PUBLIC_URL y la politica del bucket.")
        ok = False
    except Exception as e:  # noqa: BLE001
        print(f"[FALLA] no se pudo abrir la URL publica: {e}")
        ok = False

    # Que el listado NO funcione es parte de lo que se verifica: es lo unico
    # que impide descubrir las grabaciones de las demas visitas.
    try:
        with urllib.request.urlopen(
            almacenamiento.url_publica(s, "").rstrip("/"), timeout=10
        ) as r:
            if r.status == 200:
                print("[AVISO] el bucket permite listar: cualquiera puede")
                print("        enumerar las grabaciones. Quita s3:ListBucket.")
                ok = False
    except Exception:
        print("[ok] el bucket no se puede listar desde afuera")

    c.delete_object(Bucket=s.bucket_name, Key=clave)
    print("[ok] archivo de prueba borrado")
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--verificar",
        action="store_true",
        help="solo comprueba lo que ya existe, no crea ni cambia nada",
    )
    args = parser.parse_args()

    s = Settings()
    faltan = [
        nombre
        for nombre, valor in (
            ("BUCKET_NAME", s.bucket_name),
            ("BUCKET_ACCESS_KEY", s.bucket_access_key),
            ("BUCKET_SECRET_KEY", s.bucket_secret_key),
            ("BUCKET_REGION", s.bucket_region),
        )
        if not valor
    ]
    if faltan:
        print("Faltan variables en backend/.env: " + ", ".join(faltan))
        return 1

    if s.bucket_region == "auto" and not s.bucket_endpoint:
        # "auto" es de Cloudflare R2 y en AWS no es una region valida. Si el
        # bucket ya existe, AWS sabe donde esta: se le pregunta en vez de
        # hacer que alguien lo adivine.
        real = detectar_region(s)
        if real is None:
            print(f"El bucket '{s.bucket_name}' no existe o las llaves no lo ven.")
            print("Revisa el nombre y los permisos del usuario IAM.")
            return 1
        print(f"[ok] region detectada: {real}")
        print(f"     Ponla en backend/.env como BUCKET_REGION={real}")
        s = s.model_copy(update={"bucket_region": real})

    if not args.verificar:
        crear(s)
        print()

    return 0 if verificar(s) else 1


if __name__ == "__main__":
    raise SystemExit(main())
