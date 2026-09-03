import logging

from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .config import Settings, get_settings
from .schemas import (
    ExtraccionRequest,
    ExtraccionResult,
    PublishRequest,
    PublishResult,
    Report,
    ReportRequest,
    TranscriptionResult,
)
from .schemas_auth import LoginRequest, LoginResult
from .schemas_visita import ArchivoSubido, VisitaPayload, VisitaSyncResult
from .services import (
    airtable,
    almacenamiento,
    extraccion as extraccion_service,
    nomina,
    report as report_service,
    sincronizacion,
    transcription,
)

logger = logging.getLogger(__name__)

app = FastAPI(title="Sirius Agro API", version="0.2.0")

# La app corre tambien en web, asi que el navegador hace preflight.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def unhandled_error(request: Request, exc: Exception) -> JSONResponse:
    """Red de seguridad: la app espera JSON con `detail`, no un "Internal Server Error" pelado."""
    # Starlette vuelve a levantar la excepcion despues de esto, asi que el traceback
    # completo lo imprime uvicorn; aca solo dejamos la ruta que fallo.
    logger.error("Fallo no controlado en %s %s: %r", request.method, request.url.path, exc)
    return JSONResponse(
        status_code=500,
        content={
            "detail": f"Error interno del backend: {type(exc).__name__}. Revisa los logs del servidor."
        },
    )


def require_api_key(
    x_api_key: str = Header(default=""),
    settings: Settings = Depends(get_settings),
) -> Settings:
    if not settings.app_api_key:
        raise HTTPException(status_code=500, detail="APP_API_KEY no esta configurada.")

    # Se distinguen los dos casos a proposito. En el celular del visitador no
    # hay consola: si el APK se compilo sin --dart-define=API_KEY el header no
    # llega, y decir "invalida" manda a revisar el valor equivocado.
    if not x_api_key:
        raise HTTPException(
            status_code=401,
            detail=(
                "La app no mando X-API-Key: se compilo sin "
                "--dart-define=API_KEY. Hay que reinstalarla, no basta con "
                "recargar: la llave se fija al compilar."
            ),
        )
    if x_api_key != settings.app_api_key:
        raise HTTPException(
            status_code=401,
            detail="X-API-Key invalida: la app trae una llave distinta a APP_API_KEY.",
        )
    return settings


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/auth/login", response_model=LoginResult)
async def login(
    req: LoginRequest,
    settings: Settings = Depends(require_api_key),
) -> LoginResult:
    """Verifica la contrasena contra Sirius Nomina Core.

    Es el unico camino: la app no habla con Airtable, porque el PAT que lee
    `Personal` tambien lee salarios y cuentas bancarias.
    """
    empleado = await nomina.autenticar(settings, req.cedula, req.password)

    return LoginResult(
        id_empleado=empleado.id_empleado,
        cedula=empleado.cedula,
        nombre=empleado.nombre,
        email=empleado.email,
        rol_nomina=empleado.rol,
        nivel_acceso=empleado.nivel_acceso,
        orden_nivel=empleado.orden_nivel,
        rol_app=(
            "Coordinador"
            if empleado.orden_nivel <= settings.nomina_orden_coordinador
            else "Visitador"
        ),
        hash_offline=empleado.hash_bcrypt,
        dias_max_offline=settings.dias_max_offline,
    )


@app.post("/v1/transcripciones", response_model=TranscriptionResult)
async def crear_transcripcion(
    file: UploadFile = File(...),
    idioma: str = Form(""),
    diarizar: bool = Form(True),
    # Terminos especificos de esta visita, separados por coma: el nombre del
    # productor, su vereda, los insumos que ya se le registraron. Es lo que
    # de verdad mejora la transcripcion — un termino generico ayuda poco, el
    # apellido de la persona que esta hablando ayuda mucho.
    terminos: str = Form(""),
    settings: Settings = Depends(require_api_key),
) -> TranscriptionResult:
    audio = await file.read()
    extra = [t.strip() for t in terminos.split(",") if t.strip()]
    return await transcription.transcribe(
        settings,
        file.filename or "tramo.m4a",
        audio,
        language=idioma or None,
        diarizar=diarizar,
        terminos_extra=extra,
    )


@app.post("/v1/transcriptions", response_model=TranscriptionResult, deprecated=True)
async def create_transcription_legacy(
    file: UploadFile = File(...),
    language: str = Form("es"),
    settings: Settings = Depends(require_api_key),
) -> TranscriptionResult:
    """Ruta vieja, en ingles y sin diarizacion por defecto.

    Se conserva para no romper una app a medio actualizar en el celular de
    alguien. Se puede borrar cuando todos los APK en campo esten al dia.
    """
    audio = await file.read()
    return await transcription.transcribe(
        settings, file.filename or "tramo.m4a", audio, language=language, diarizar=False
    )


@app.post("/v1/extracciones", response_model=ExtraccionResult)
async def crear_extraccion(
    req: ExtraccionRequest,
    settings: Settings = Depends(require_api_key),
) -> ExtraccionResult:
    return await extraccion_service.extraer(settings, req)


@app.post("/v1/reports", response_model=Report)
async def create_report(
    req: ReportRequest,
    settings: Settings = Depends(require_api_key),
) -> Report:
    return await report_service.build_report(settings, req)


@app.post("/v1/meetings", response_model=PublishResult)
async def publish_meeting(
    req: PublishRequest,
    settings: Settings = Depends(require_api_key),
) -> PublishResult:
    return await airtable.publish(settings, req)


@app.post("/v1/archivos", response_model=ArchivoSubido)
async def subir_archivo(
    file: UploadFile = File(...),
    codigo_visita: str = Form(...),
    # audio | fotos. Define la carpeta dentro del prefijo de la visita, para
    # que borrar una visita revocada sea borrar un prefijo.
    categoria: str = Form("audio"),
    # Posicion dentro de la visita. Con esto el archivo queda como `foto-03.jpg`
    # en vez del reloj en milisegundos que pone la camara. Opcional: sin el se
    # conserva el nombre original en vez de inventar una posicion.
    orden: int | None = Form(None),
    settings: Settings = Depends(require_api_key),
) -> ArchivoSubido:
    """Sube un tramo de audio o una foto al bucket y devuelve su URL.

    La app sube contra esta ruta y nunca contra S3 directo: las credenciales
    del bucket no pueden viajar dentro de un APK.
    """
    if categoria not in ("audio", "fotos"):
        raise HTTPException(
            status_code=400, detail="categoria tiene que ser 'audio' o 'fotos'."
        )

    contenido = await file.read()
    if len(contenido) > settings.max_audio_bytes:
        raise HTTPException(
            status_code=413,
            detail=(
                f"El archivo pesa {len(contenido) / (1024 * 1024):.1f} MB y el "
                f"limite es {settings.max_audio_bytes / (1024 * 1024):.0f} MB."
            ),
        )

    return almacenamiento.subir(
        settings,
        contenido,
        codigo_visita=codigo_visita,
        categoria=categoria,
        nombre=file.filename or "archivo",
        orden=orden,
    )


@app.post("/v1/visitas", response_model=VisitaSyncResult)
async def sincronizar_visita(
    payload: VisitaPayload,
    settings: Settings = Depends(require_api_key),
) -> VisitaSyncResult:
    """Sincroniza la visita completa a Airtable.

    Idempotente por `codigo_visita`, que es el UUID que genero el telefono
    antes de tener red: reintentar desde una vereda con senal intermitente
    nunca duplica.
    """
    return await sincronizacion.sincronizar(settings, payload)
