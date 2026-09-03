from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_api_key: str = ""

    # Transcripcion diarizada. Whisper quedo fuera porque no separa voces, y
    # sin voces separadas no se puede aplicar la regla de que lo dicho por el
    # visitador nunca queda Confirmado.
    elevenlabs_api_key: str = ""
    elevenlabs_model: str = "scribe_v2"

    # ElevenLabs toma ISO-639-1 o 639-3 y no distingue variantes regionales:
    # no hay un es-419 que pedir como con Deepgram, solo "es". Dejarlo vacio
    # hace que detecte el idioma solo, que en una grabacion de campo con ruido
    # y motores de fondo es peor que decirselo.
    elevenlabs_language: str = "es"

    # Maximo de voces esperadas. 0 = lo decide el proveedor, que es lo que
    # conviene: fijar 2 fusionaria dos personas en una sola voz si en la visita
    # habla un tercero, y una voz fusionada le atribuye al agricultor cosas que
    # dijo el visitador — justo al reves de la regla que sostiene el dato.
    elevenlabs_num_speakers: int = 0

    openai_api_key: str = ""
    whisper_model: str = "whisper-1"

    anthropic_api_key: str = ""
    claude_model: str = "claude-opus-5"

    airtable_token: str = ""
    airtable_base_id: str = ""
    airtable_table: str = "Reuniones"

    # Login contra Sirius Nomina Core. Es OTRA base y conviene que sea otro
    # PAT, con alcance de solo lectura sobre Personal: el token del agro no
    # tiene por que poder leer salarios ni cuentas bancarias.
    nomina_token: str = ""
    # Sin default: el id de la base de nomina no se hardcodea aca. El repo es
    # publico y dejarlo escrito senala a la base que guarda salarios y cuentas
    # bancarias, que es medio camino andado si algun dia se filtra un PAT.
    # Vacio hace fallar el login con un mensaje claro (ver nomina.py) en vez de
    # apuntar sin querer a produccion desde un entorno de pruebas.
    nomina_base_id: str = ""
    nomina_table: str = "Personal"

    # Hasta que orden jerarquico se considera Coordinador en ESTA app. En
    # nomina 1 = Super Admin y el numero sube al bajar el privilegio.
    nomina_orden_coordinador: int = 2

    # Cuantos dias puede el telefono validar la contrasena sin haber hablado
    # con el backend. Pasado el plazo exige un login con red, que es lo unico
    # que ve si la persona sigue activa en nomina.
    dias_max_offline: int = 30

    # Bucket S3 para audio y fotos. Las credenciales solo viven aca: una llave
    # dentro de un APK que anda en el bolsillo de alguien es una llave publica.
    bucket_endpoint: str = ""
    bucket_name: str = ""
    bucket_access_key: str = ""
    bucket_secret_key: str = ""

    # R2 y B2 ignoran la region, S3 no. "auto" es lo que espera R2.
    bucket_region: str = "auto"

    # Dominio publico o CDN del bucket. Airtable carga un adjunto yendo el
    # mismo a la URL desde sus servidores, asi que si el endpoint no es
    # alcanzable desde internet hay que poner aca el que si lo es.
    bucket_public_url: str = ""

    # ElevenLabs acepta hasta 3 GB de audio pregrabado, pero el techo real lo
    # pone el host: en Vercel el cuerpo de una peticion no puede pasar de
    # 4,5 MB y ese limite es de infraestructura, no se configura.
    #
    # 4 MB deja margen para el sobre multipart. La app graba AAC-LC a 32 kbps
    # en tramos de 5 min (~1,2 MB), asi que hay 3x de holgura; lo que esto
    # atrapa es un tramo que se alargo por un fallo. Preferimos fallar aca con
    # un mensaje que explique, y no con el 413 pelado de la plataforma.
    #
    # En un host sin este limite (contenedor propio, App Runner) se sube con
    # MAX_AUDIO_BYTES en el entorno.
    max_audio_bytes: int = 4 * 1024 * 1024


@lru_cache
def get_settings() -> Settings:
    return Settings()
