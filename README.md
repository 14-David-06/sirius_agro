# Sirius Reuniones

App Flutter para grabar reuniones respondiendo un cuestionario guiado mientras avanza
la grabación. Al terminar, el audio se transcribe (ElevenLabs Scribe, con Whisper de
respaldo), se genera un informe
estructurado (Claude) y todo se publica en Airtable.

```
app/       Flutter — Android, iOS, web y Windows
backend/   FastAPI — guarda las llaves y habla con ElevenLabs, Whisper, Claude y Airtable
```

La app **nunca** ve los tokens de OpenAI, Anthropic ni Airtable: solo conoce la URL del
backend y una `API_KEY` propia que va en el header `X-API-Key`.

## Flujo

1. Elegís un cuestionario y arrancás a grabar.
2. Mientras corre la grabación respondés las preguntas; cada respuesta queda marcada con
   el minuto en que la anotaste.
3. Al terminar, la app sube el audio y el backend encadena:
   `transcripción → informe → registro en Airtable`.
4. Si un paso falla, el botón **Reintentar** retoma desde donde quedó (no vuelve a
   transcribir si ya hay transcripción).

Todo se guarda localmente primero, así que una grabación nunca se pierde si el backend
está caído.

## Backend

```bash
cd backend
python -m venv .venv
.venv/Scripts/activate          # Windows;  source .venv/bin/activate en Linux/macOS
pip install -r requirements.txt
cp .env.example .env            # completá las llaves
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Endpoints (todos piden `X-API-Key`, salvo `/health`):

| Método | Ruta                 | Qué hace                                        |
|--------|----------------------|-------------------------------------------------|
| GET    | `/health`            | ping                                            |
| POST   | `/v1/transcriptions` | multipart `file` + `language` → texto (ElevenLabs) |
| POST   | `/v1/reports`        | meta + transcripción + respuestas → informe JSON |
| POST   | `/v1/meetings`       | crea el registro en Airtable                     |

Documentación interactiva en `http://localhost:8000/docs`.

### Tabla de Airtable

El backend escribe en la tabla indicada por `AIRTABLE_TABLE` y espera estos campos
(los nombres van sin tildes, tal cual):

| Campo             | Tipo                 |
|-------------------|----------------------|
| `Titulo`          | Single line text     |
| `Fecha`           | Date                 |
| `Duracion (min)`  | Number (1 decimal)   |
| `Participantes`   | Long text            |
| `Transcripcion`   | Long text            |
| `Respuestas`      | Long text            |
| `Informe`         | Long text            |
| `Estado`          | Single select        |

Se manda con `typecast: true`, así que Airtable crea sola la opción `Procesada` en
`Estado`. Si preferís otros nombres, se cambian en `backend/app/services/airtable.py`.

## App

```bash
cd app
flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=API_KEY=tu-clave
```

Sin esas dos variables la app arranca igual y podés grabar, pero no transcribe ni
publica (te lo avisa con un aviso en la barra superior).

Para compilar:

```bash
flutter build apk --flavor prod --dart-define=API_BASE_URL=... --dart-define=API_KEY=...
flutter build web              --dart-define=API_BASE_URL=... --dart-define=API_KEY=...
flutter build windows          --dart-define=API_BASE_URL=... --dart-define=API_KEY=...
```

### Los dos canales de Android

En Android hay dos *flavors* y `flutter build apk` **exige elegir uno**:

| Flavor | applicationId | Nombre bajo el icono |
|---|---|---|
| `prod` | `com.siriusregenerative.sirius_agro` | Sirius Agro |
| `dev`  | `com.siriusregenerative.sirius_agro.dev` | Sirius Agro Dev |

Son dos apps distintas para Android, con base local separada: instalar el de
pruebas no desinstala el que el visitador esta usando en campo ni le borra las
visitas que todavia no sincronizo. Probar siempre con `--flavor dev`; `prod` es
lo unico que se reparte.

### Cuestionarios

Las plantillas de preguntas viven en `app/lib/data/questionnaires.dart`. Agregar una es
sumar un `Questionnaire` a esa lista; el `id` queda guardado con cada reunión.

## Decisiones que conviene conocer

- **Audio en AAC mono a 32 kbps** (~14 MB por hora). Whisper rechaza archivos de más de
  25 MB, así que el backend corta con un 413 explicativo pasado ese límite. Para
  reuniones de más de ~2 horas hay que partir el audio o meter un paso de troceo.
- **Whisper es solo el respaldo.** El motor es ElevenLabs Scribe porque separa las
  voces, y de eso depende la regla de que lo dicho por el visitador no queda
  Confirmado. Si ElevenLabs no responde se transcribe con Whisper: el texto queda con
  sus marcas de tiempo pero sin hablante, y la respuesta lo dice en `motor` y en
  `razon_sugerencia` en vez de fingir una diarización que no hubo.
- **La transcripción no es en vivo.** El motor procesa el archivo completo al final.
  Si hace falta ver el texto avanzar durante la reunión, hay que cambiar a un motor de
  streaming (Deepgram) — es un cambio acotado a `services/transcription.py` y a la
  pantalla de grabación.
- **Persistencia local con `shared_preferences`** (JSON), para que funcione igual en las
  cuatro plataformas. Si el volumen de reuniones crece, el reemplazo natural es SQLite
  vía `drift`; la interfaz está aislada en `MeetingStore`.
- **El informe usa `claude-opus-5`** con salida estructurada (JSON schema) y fallback del
  lado del servidor, para que una reunión no se quede sin informe si un clasificador
  rechaza la petición.

## Pendiente

- SDK de Android: `flutter doctor` lo reporta faltante. Instalar Android Studio o el
  command-line tools para compilar el APK.
- Modo desarrollador de Windows (`start ms-settings:developers`) para compilar el
  target Windows — Flutter necesita symlinks para los plugins.
- Deploy del backend (Cloud Run, Railway o similar) y rotación de la `APP_API_KEY`.
