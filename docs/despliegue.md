# Lanzar a produccion

Dos cosas distintas: **el backend** tiene que estar siempre arriba y alcanzable
desde 4G, y **el APK** tiene que estar bien compilado y bien firmado. Si falta
cualquiera de las dos, la app funciona en el escritorio y no en la finca.

---

## 0. Primero la llave de firma. No es opcional y no se puede posponer

La llave con la que se firma un APK **es la identidad de la app para Android**.
Un APK firmado con otra llave no puede actualizar al instalado: hay que
desinstalar, y desinstalar **borra la base local** — o sea las visitas grabadas
que todavia no se sincronizaron.

Hasta ahora los APK se firmaban con la llave de **depuracion**, que Android
genera sola en cada maquina (`~/.android/debug.keystore`). Consecuencia: si este
PC se pierde o se reinstala, ningun APK nuevo podria actualizar los telefonos
del piloto. Y cualquiera puede firmar con una llave de debug, asi que no hay
garantia de que el APK que le llega al visitador salio de ustedes.

**Cuanto mas tarde se arregle, mas telefonos quedan atados a esa llave.**
Hacerlo antes de repartir el primero cuesta un comando.

```bash
keytool -genkey -v -keystore C:/ruta/segura/sirius-agro.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias sirius
```

Despues, `app/android/key.properties` (ya esta en `.gitignore`):

```properties
storePassword=...
keyPassword=...
keyAlias=sirius
storeFile=C:/ruta/segura/sirius-agro.jks
```

El `build.gradle.kts` ya lo lee. Sin ese archivo cae a la llave de debug, que
sirve para probar y **no** para repartir.

> Guarden el `.jks` y las contrasenas donde sobrevivan a que se dane un PC.
> Perder esa llave significa que nadie puede volver a actualizar la app sin que
> cada visitador desinstale y pierda lo que tenga sin sincronizar.

---

## 1. Backend en Vercel

### Por que Vercel sirve, y donde esta el filo

| Limite | Lo que hace la app | Margen |
|---|---|---|
| **4,5 MB** de cuerpo por peticion (de infraestructura, **no se configura**) | Tramo AAC-LC 32 kbps × 5 min = **1,2 MB**. Foto 720p = 200-400 KB | 3,7× |
| **300 s** por funcion (Hobby y Pro por defecto; Pro llega a 800 s) | Transcribir + extraer + informe | Comodo |
| Funciones efimeras, sin disco | Todo va a S3 (`almacenamiento.py`) | Sin problema |

Por el filo de 4,5 MB, `MAX_AUDIO_BYTES` quedo en **4 MB**: un tramo que no se
cerro cuando debia falla con un mensaje que explica, y no con el `413` pelado
de la plataforma. Hay un test que falla si alguien lo sube por encima.

Si algun dia el audio crece (mas bitrate, tramos mas largos), Vercel deja de
servir y hay que mover el backend a un contenedor (App Runner, Railway, VPS) y
subir `MAX_AUDIO_BYTES` por entorno.

### Crear el proyecto

**No hace falta separar el backend a otro repositorio.** Vercel importa este
mismo repo y se le indica que carpeta construir:

- **Root Directory: `backend`** (la app Flutter queda al lado, ignorada)
- Framework: lo detecta solo por `requirements.txt`

Si mas adelante hace falta desplegar algo mas del repo (una web, un panel), se
crea otro proyecto de Vercel apuntando al mismo repositorio con otro Root
Directory. Son proyectos distintos sobre el mismo Git.

#### Por que hay un `ignoreCommand`

Vercel sabe saltarse builds de proyectos que no cambiaron, pero **solo si el
monorepo usa workspaces de npm/yarn/pnpm/Bun**. Este repo es Flutter + Python,
asi que Vercel trata cualquier cambio como global: sin nada mas, tocar una
pantalla de la app dispararia un despliegue del backend.

Por eso `backend/vercel.json` trae:

```json
"ignoreCommand": "git diff --quiet HEAD^ HEAD ./"
```

`./` es la Root Directory, o sea `backend/`. `git diff --quiet` sale con 0
cuando no hay diferencias, y Vercel entiende **0 = saltar el build**, 1 =
construir. Resultado: solo se despliega cuando cambio algo del backend.

Ya esta commiteado lo que necesita:

| Archivo | Para que |
|---|---|
| `backend/pyproject.toml` | `entrypoint = "app.main:app"`. Sin esto Vercel cargaria `app/main.py` suelto y reventaria: usa imports relativos |
| `backend/.python-version` | 3.12 |
| `backend/vercel.json` | `maxDuration: 300`, excluye tests y `.venv` del bundle |
| `backend/.vercelignore` | Que el `.venv` (666 MB) nunca salga del PC |

### Variables de entorno

En **Settings → Environment Variables**, copiadas de `backend/.env`:

```
APP_API_KEY          ELEVENLABS_API_KEY    ELEVENLABS_MODEL
ANTHROPIC_API_KEY    CLAUDE_MODEL          ELEVENLABS_LANGUAGE
AIRTABLE_TOKEN       AIRTABLE_BASE_ID      AIRTABLE_TABLE
BUCKET_NAME          BUCKET_ACCESS_KEY     BUCKET_SECRET_KEY
BUCKET_REGION
NOMINA_TOKEN         NOMINA_BASE_ID        NOMINA_TABLE
```

**`NOMINA_TOKEN` hoy es el mismo PAT del agro.** Ese token tambien lee salarios,
cuentas bancarias y documentos de identidad de los 18 empleados, y va a quedar
como variable de entorno en Vercel. Antes de produccion conviene separarlo: un
PAT propio, de solo lectura, con alcance unicamente a `Sirius Nomina Core`.

`.env` esta en `.gitignore` y nunca se commiteo (verificado con `gitleaks`
sobre el historial completo).

### Comprobar

```bash
curl https://<proyecto>.vercel.app/health
# {"status":"ok"}

curl -X POST https://<proyecto>.vercel.app/v1/auth/login \
  -H "X-API-Key: <APP_API_KEY>" -H "Content-Type: application/json" \
  -d '{"cedula":"...","password":"..."}'
```

`/health` no pide llave a proposito: es lo que usa el health check del host.

---

## 2. El APK de produccion

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<proyecto>.vercel.app \
  --dart-define=API_KEY=<APP_API_KEY>
```

La URL y la llave **se fijan al compilar**. Cambiarlas exige reinstalar; no
basta con reabrir la app.

Tres redes de seguridad ya puestas:

1. **Si falta un `--dart-define`, la pantalla de login lo dice** en rojo, con
   que falto y que hacer. Antes apuntaba a `localhost` en silencio y el
   visitador lo descubria en la finca.
2. **El APK de release no permite HTTP en claro.** `usesCleartextTraffic` vive
   solo en los manifiestos de `debug` y `profile`. Una URL sin TLS no funciona
   en produccion aunque alguien la pase por `--dart-define`.
3. **La firma sale de `key.properties`** si existe (ver punto 0).

### Verificar el APK antes de repartirlo

```bash
# Que quedo firmado con la llave de produccion y no con la de debug
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# Que NO permite trafico en claro
aapt2 dump xmltree --file AndroidManifest.xml \
  build/app/outputs/flutter-apk/app-release.apk | grep -i cleartext
# no debe imprimir nada
```

---

## 3. Que pasa cuando algo se cae

La app esta hecha para que el backend caido **no** detenga una visita:

| Se cae | Que pasa |
|---|---|
| No hay señal en la finca | Se graba, se fotografia y se llenan datos igual. Todo queda en cola |
| El backend no responde | El login cae a la copia local (si esa persona ya entro en ese telefono) |
| Vercel esta caido al sincronizar | La cola reintenta; nada se pierde |
| Pasan mas de 30 dias sin red | El login offline caduca a proposito: es lo unico que puede ver si alguien salio de la empresa |

Lo que **si** exige red: el primer login de cada persona en cada telefono,
procesar la conversacion y generar el informe.

---

## 4. Antes de repartir, revisar

- [ ] `key.properties` creado y el `.jks` respaldado fuera del PC
- [ ] APK verificado con `keytool -printcert` (llave de produccion, no debug)
- [ ] Proyecto en Vercel con Root Directory `backend` y las 16 variables
- [ ] `NOMINA_TOKEN` separado en un PAT propio de solo lectura
- [ ] `curl /health` responde desde fuera de la red de la oficina
- [ ] Un login real desde 4G, sin cable y con el PC apagado
- [ ] Decidir si el repositorio sigue publico (hoy lo esta; ya no tiene PII ni
      secretos, pero expone la estructura de las bases de Airtable)

## 5. Como se actualiza la app despues

No hay tienda. Hoy el APK se pasa a mano. Mientras la firma sea la misma,
instalar encima **conserva la base local**. Si mas adelante molesta repartir
archivos, las opciones son Play Store (interno o cerrado) o Firebase App
Distribution; las dos exigen que la firma ya este resuelta, que es el punto 0.

---

## Probar sin desplegar

El celular por USB llega al backend del PC sin WiFi ni despliegue:

```bash
adb reverse tcp:8000 tcp:8000
cd backend && .venv/Scripts/uvicorn app.main:app --port 8000
```

Con eso `http://localhost:8000` **en el celular** es el PC, y un APK de `debug`
o `profile` —que si permiten HTTP en claro— habla con el de verdad. El tunel se
cae al desconectar el cable; se repone con el mismo comando.
