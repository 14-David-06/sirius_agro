# Poner el backend en un servidor continuo (Vercel)

Mientras el backend corra solo en el PC, la app apunta a `localhost` y desde el
celular eso no existe: el login cae al modo sin red y la transcripcion falla con
`Connection refused`. Esto lo arregla.

## Por que Vercel sirve, y donde esta el filo

| Limite de Vercel | Lo que hace la app | Margen |
|---|---|---|
| **4,5 MB** de cuerpo por peticion (de infraestructura, **no se configura**) | Tramo de audio AAC-LC 32 kbps × 5 min = **1,2 MB**. Foto 720p = 200-400 KB | 3,7× |
| **300 s** por funcion (Hobby y Pro por defecto; Pro llega a 800 s) | Transcribir un tramo + extraer hallazgos | Comodo |
| Funciones efimeras, sin disco persistente | Todo va a S3 (`almacenamiento.py`), nada se escribe local | Sin problema |

El filo es el de 4,5 MB. Por eso `MAX_AUDIO_BYTES` quedo en **4 MB**: asi un
tramo que no se cerro cuando debia falla con un mensaje que explica que paso, y
no con el `413` pelado de la plataforma. Hay un test que falla si alguien lo
sube por encima de 4,5 MB.

Si algun dia el audio sube de tamano (mas bitrate, tramos mas largos), Vercel
deja de servir y hay que mover el backend a un contenedor —
App Runner, Railway o un VPS— y subir `MAX_AUDIO_BYTES` por entorno.

## 1. Crear el proyecto en Vercel

El repositorio tiene la app Flutter y el backend juntos, asi que hay que
apuntarle a la carpeta:

- **Root Directory**: `backend`
- Framework: lo detecta solo (FastAPI, por `requirements.txt`)

Ya esta commiteado lo que Vercel necesita:

| Archivo | Para que |
|---|---|
| `backend/pyproject.toml` | `entrypoint = "app.main:app"`. Sin esto Vercel cargaria `app/main.py` suelto y reventaria: usa imports relativos |
| `backend/.python-version` | 3.12 |
| `backend/vercel.json` | `maxDuration: 300` y excluye tests y `.venv` del bundle |
| `backend/.vercelignore` | Que `.venv` (666 MB) nunca salga del PC |

## 2. Variables de entorno

En **Settings → Environment Variables**, copiadas de `backend/.env`:

```
APP_API_KEY          ELEVENLABS_API_KEY    ELEVENLABS_MODEL
ANTHROPIC_API_KEY    CLAUDE_MODEL          ELEVENLABS_LANGUAGE
AIRTABLE_TOKEN       AIRTABLE_BASE_ID      AIRTABLE_TABLE
BUCKET_NAME          BUCKET_ACCESS_KEY     BUCKET_SECRET_KEY
BUCKET_REGION
NOMINA_TOKEN         NOMINA_BASE_ID        NOMINA_TABLE
```

`NOMINA_TOKEN` es el unico que todavia no existe: **conviene un PAT distinto al
del agro, de solo lectura y con alcance unicamente a la base
`Sirius Nomina Core`**. Ese token puede leer salarios, cuentas bancarias y
documentos de identidad de los 18 empleados; no tiene por que ser el mismo que
publica visitas.

`.env` esta en `.gitignore` y nunca se commiteo — verificado con `gitleaks`
sobre el historial completo.

## 3. Comprobar que quedo arriba

```bash
curl https://<proyecto>.vercel.app/health
# {"status":"ok"}

# El login exige la API key, como todo /v1
curl -X POST https://<proyecto>.vercel.app/v1/auth/login \
  -H "X-API-Key: <APP_API_KEY>" -H "Content-Type: application/json" \
  -d '{"identificador":"SIRIUS-PER-0002","password":"..."}'
```

`/health` no pide llave a proposito: es lo que usa el health check del host.

## 4. Recompilar la app

La URL y la llave se fijan **al compilar**, no en tiempo de ejecucion. Cambiarlas
exige reinstalar el APK; no basta con reabrir la app.

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<proyecto>.vercel.app \
  --dart-define=API_KEY=<APP_API_KEY>
```

Sin `--dart-define`, `API_BASE_URL` cae a `http://localhost:8000` y pasa
exactamente lo de la captura.

**El APK de release ya no permite HTTP en claro.** `usesCleartextTraffic` se
movio al manifiesto de `debug`, asi que una URL sin TLS no funciona en
produccion aunque alguien la pase por `--dart-define`. Para desarrollo contra la
LAN, usar `flutter run` o `--debug`.

## Probar sin desplegar todavia

El celular por USB puede llegar al backend del PC sin WiFi ni despliegue:

```bash
adb reverse tcp:8000 tcp:8000
cd backend && .venv/Scripts/uvicorn app.main:app --port 8000
```

Con eso `http://localhost:8000` **en el celular** es el PC, y el APK de debug
—que si permite HTTP en claro— hace login de verdad contra nomina.
