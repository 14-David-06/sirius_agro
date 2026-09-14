# Base de datos Airtable — Copiloto de campo

Base: **Sirius Agro App** — `app7f9V8mIcopAAdv`
(la misma que ya usa `backend/.env`; la tabla `Reuniones` sigue ahí, sin tocar).

Convención: nombres de campo **sin tildes ni ñ**, igual que en el resto del proyecto.
Fechas ISO, horas en `America/Bogota`.

## Flujo que soporta el modelo

```
PRODUCTOR -> FINCA -> VISITA -> GRABACION + EVIDENCIA -> HALLAZGOS (IA)
          -> VALIDACION -> DIAGNOSTICO + INDICADORES -> OPORTUNIDADES -> INFORME
```

## Tablas

| Tabla | ID | Para qué sirve |
|---|---|---|
| Visitadores | `tblzyISjMzH2JBLin` | Quién hace la visita |
| Veredas | `tbl8IIpcNFOHsgNOp` | Territorio (municipio / vereda) |
| Productores | `tblh727lye1N27Z0b` | Identidad del agricultor |
| Fincas | `tblfUSm5SaLT1KV1J` | Unidad productiva |
| Lotes | `tbl6mxGSLbcaDKTbs` | Subdivisiones de la finca |
| Visitas | `tblv5fzFJiqjuZKwr` | **Evento central** |
| Grabaciones | `tblpfHtKhrPNPQAMm` | Audio + transcripción |
| Evidencias | `tblKaxB2PDit0B7qR` | Fotos, OCR de etiquetas |
| Insumos detectados | `tblrk3TXL86cq9E4r` | Productos leídos por OCR o mencionados |
| Catalogo de Campos | `tblu6GshimULyLUAo` | Diccionario de módulos y variables (74 sembradas, 55 activas en la V1) |
| Hallazgos | `tbl73vmrXGHqQxGp5` | **Datos extraídos por la IA, con fuente y confianza** |
| Diagnosticos | `tblIY5Q8oxYZq97LK` | Interpretación por dimensión |
| Indicadores | `tbliSmnsSjXtqPbVV` | Línea base comparable entre visitas |
| Oportunidades | `tblDOQaOgzprlEZB4` | Recomendaciones e intervenciones |
| Informes | `tblczDOcHeq9taOQ9` | Entregables (PDF en el bucket) |
| Unidades | `tbl8JhwAVnNvVxAuB` | Factores de conversión a kilogramos |

## Decisiones de modelado

**1. Los módulos no son columnas.** El cuestionario vive como registros en
`Catalogo de Campos` y cada dato extraído es un registro en `Hallazgos`. Así la IA
puede aprender a extraer variables nuevas sin migrar la base, y el visitador nunca
recorre módulos: solo revisa los `Hallazgos` con baja confianza.

**2. Todo dato extraído es trazable.** Cada `Hallazgo` guarda `Fuente`
(Audio / Foto / OCR / GPS / Manual), la `Cita textual` de la transcripción, el
`Segundo del audio` y el `Hablante`. Si el productor reclama un dato, se puede ir al
audio exacto.

**3. Certeza y validación son dos ejes distintos.** `Hallazgos.Certeza` dice de dónde
salió el dato: `Confirmado` (lo dijo textualmente), `Estimado` (dio un aproximado o un
rango), `Inferido` (se dedujo — **exige `Razonamiento`**), `Pendiente` (no salió, o
salió sin cita). `Hallazgos.Estado` dice qué hizo el visitador: `Propuesto por IA` →
`Confirmado` / `Corregido` / `Descartado`. Un dato puede estar `Estimado` y a la vez
validado. La pantalla de validación filtra por `Certeza` ≠ Confirmado o `Confianza < 70%`.

**Tres reglas duras que el backend aplica, no el modelo:**
1. `Hablante = visitador` ⇒ `Certeza` nunca puede ser `Confirmado`. El visitador
   sugiriendo un dato no es el agricultor afirmándolo.
2. Sin `Cita textual` ⇒ el hallazgo baja a `Certeza = Pendiente`, cualquiera que sea
   la confianza que reportó el modelo.
3. `Certeza = Inferido` sin `Razonamiento` ⇒ baja a `Pendiente`.

**3b. Un hallazgo sabe a qué se refiere.** `Entidad destino` + `Entidad local id`
distinguen *cuál* de los tres cultivos tiene 4 ha. Sin eso todos los hallazgos de
cultivo se pisan entre sí. El `Entidad local id` lo asigna el modelo (`cultivo_1`,
`cultivo_2`) y el backend lo resuelve a `Lotes` al sincronizar.

**4. La finca es la que se transforma, no la visita.** `Productor` y `Finca` son
permanentes; `Visita` es el evento. `Indicadores` repite las mismas mediciones visita
tras visita (marca `Es linea base` en la primera) para poder medir el cambio.

**5. Insumos aparte de Hallazgos.** Una etiqueta produce muchos atributos
estructurados (ingrediente activo, registro ICA, categoría toxicológica) que valen
como tabla propia — es la base para proponer sustitución por bioinsumos.

**6. Idempotencia offline.** `Visitas.Codigo de visita` es el UUID que genera la app
antes de tener red. Al sincronizar, el backend busca por ese código y hace upsert:
reintentar una sincronización nunca duplica la visita.

**7. La identidad del agricultor NO sale de la conversación.** Nadie dice su
número de cédula hablando de su finca. `Productores` se llena desde el módulo
«El agricultor» de la visita —documento y tipo, teléfonos, foto de perfil, y de
forma opcional género, nacimiento, educación, experiencia, hogar y asociación— y
se llena una sola vez en la vida del productor: la segunda visita ya lo
encuentra con ficha. Todo lo demás (cultivos, suelos, riego, insumos) sigue
saliendo del audio y viviendo en `Hallazgos`.

`Documento` es el campo que sostiene el upsert: el backend busca por
`Documento` → `Codigo productor` → `Nombre completo`, y si cae al nombre, dos
personas homónimas de la misma vereda terminan compartiendo fichas y fincas.
Cuando el productor ya existe se **actualiza**, no se deja igual: la ficha casi
nunca se completa en la primera visita.

`Productores.Foto` es un adjunto que Airtable trae de una URL del bucket. La
foto se guarda bajo el prefijo de la visita donde se tomó
(`visitas/<codigo>/fotos/perfil.jpg`), no bajo el productor: si el agricultor
revoca el consentimiento, borrar la visita tiene que llevarse su retrato.

`Productores.Consentimiento de datos` es la autorización de la **persona** (Ley
1581/2012) y se copia de la visita en la que se pidió, con su fecha. Los tres
consentimientos de `Visitas` son distintos y se piden en cada visita: grabar y
fotografiar son permisos del momento. La autorización solo se escribe cuando es
un sí — una visita en la que el productor no autorizó no puede borrar la
autorización que dio en otra.

**7b. El nombre del agricultor se reconoce, no se vuelve a escribir.**
`GET /v1/productores` devuelve la ficha de los productores ya registrados y la
app la guarda en su base local. Al crear la visita, el campo del nombre sugiere
los que coinciden y, si el visitador reconoce a uno, la visita se cuelga de esa
ficha (`Tipo de visita = Seguimiento`) en vez de crear una persona nueva. Sin
esto, «Pedro Gomez», «pedro gomez» y «don Pedro» son tres `Productores` con
tres `Fincas` y ninguna historia en comun.

Es una **ayuda, no un requisito**: se busca contra el espejo local, asi que
funciona sin senal, y cuando el agricultor no esta en ninguna lista se escribe
el nombre y la visita arranca igual. El endpoint cayendose no puede impedir un
registro — una finca no deja de existir porque la vereda no tenga cobertura.

Al mezclar el directorio con lo que ya tiene el telefono la regla es **rellenar,
no pisar**: lo que el visitador acaba de teclear en la finca puede ser mas nuevo
que Airtable y todavia no haber subido. Solo mandan desde Airtable las llaves de
identidad (`Codigo productor`, el record id) y el nombre canonico, y solo cuando
la persona se reconocio por documento o por record id — nunca por nombre, que es
justo lo que el documento existe para desempatar.

## Contrato de la IA (estructuración)

El modelo debe devolver, por visita:

El esquema JSON **se genera desde `Catalogo de Campos`** filtrando `Activo = true`,
no se escribe a mano. Agregar una variable en Airtable la agrega al esquema sin
recompilar nada.

```json
{
  "hallazgos": [
    {
      "clave": "fuente_agua",
      "entidad_destino": "Finca",
      "entidad_local_id": null,
      "valor_texto": "Quebrada al lado del lote de abajo",
      "valor_numerico": null,
      "unidad": null,
      "certeza": "Confirmado",
      "hablante": "agricultor",
      "razonamiento": null,
      "confianza": 0.86,
      "cita": "...nosotros cogemos el agua de la quebradita...",
      "segundo": 412
    },
    {
      "clave": "area_por_cultivo",
      "entidad_destino": "Cultivo",
      "entidad_local_id": "cultivo_1",
      "valor_texto": "plátano",
      "valor_numerico": 4,
      "unidad": "ha",
      "certeza": "Estimado",
      "hablante": "agricultor",
      "razonamiento": null,
      "confianza": 0.71,
      "cita": "...serán como cuatro hectáreas de plátano...",
      "segundo": 638
    }
  ],
  "insumos": [ { "nombre_comercial": "...", "tipo": "Fungicida", "confianza": 0.9 } ],
  "diagnostico": { "resumen": "...", "fortalezas": [], "limitantes": [], "riesgos": [] },
  "oportunidades": [ { "titulo": "...", "tipo": "Bioinsumos", "impacto": "Alto" } ],
  "temas_pendientes": ["..."]
}
```

- `clave` debe ser una `Clave tecnica` de `Catalogo de Campos` con `Activo = true`.
  Lo que el modelo no pueda mapear va a `temas_pendientes`; **no se inventa un campo**.
- Todo campo admite `null`. Un `null` honesto vale más que un valor plausible.
- Sin `cita` el backend fuerza `Pendiente` — el modelo no puede evitar esa regla
  reportando confianza alta.
- Escritura en lotes de 10 registros: Airtable topa en 5 req/s.

## Unidades

`Unidades` (`tbl8JhwAVnNvVxAuB`) convierte a kilogramos lo que el agricultor dice en
bultos, arrobas o cargas, para que los `Indicadores` sean comparables entre visitas.
`Estado = Verificar` significa que el factor **varía según el producto** y hay que
preguntar antes de convertir: un bulto de fertilizante son 50 kg, pero un bulto de
yuca es lo que quepa. El piloto va llenando la tabla.

## El personal viene de nomina, no se administra aqui

`Visitadores` (`tblzyISjMzH2JBLin`) es un **espejo de solo lectura** de
`Sirius Nomina Core` → `Personal` (la base se configura con `NOMINA_BASE_ID`;
el id no se escribe aqui porque este repositorio es publico).

Airtable **no permite vincular registros entre bases**, asi que la union es el campo
`ID Empleado` (`SIRIUS-PER-XXXX`). Si alguien entra o sale de la empresa se cambia en
nomina y se vuelve a sembrar: **nunca se edita la persona aqui**, o las dos bases se
separan sin que nadie se entere.

Sembrados: los **18 empleados activos**. Los dos «De baja» y la cuenta generica
suspendida de la empresa quedaron fuera.

### No hay tres visitadores fijos

El plan pedia «crear los 3 registros de Visitadores». **Nadie en la nomina tiene cargo
de visitador de campo** — los 18 activos son planta, produccion, laboratorio,
administracion y comercial. Las visitas del piloto son una reasignacion, no un puesto.

Asi que en vez de elegir tres personas de antemano, la app trae un **selector con los
18** y quien hace la visita se elige al crearla. El telefono recuerda la ultima
seleccion, porque casi siempre es la misma persona — pero se puede cambiar, porque el
telefono se presta.

| Campo | Que es |
|---|---|
| `ID Empleado` | `SIRIUS-PER-XXXX`. La llave hacia nomina |
| `Cargo` | El cargo real en la empresa (`LIDER EN REGENERACION AMBIENTAL`) |
| `Rol` | El papel dentro de **esta app**: `Visitador` o `Coordinador` |

`Rol` se derivo del `Nivel de acceso` de nomina (Super Admin/Admin → Coordinador,
Usuario → Visitador). **Es una propuesta, no un dato de la empresa** — conviene
revisarla antes del piloto.

### Credenciales: lo que NO se copio

> **`Personal.Password` en Sirius Nomina Core guarda contrasenas en texto plano.**

No se leyo, no se copio y no se sembro. La app agro tendra **su propia credencial con
hash en el backend**, vinculada al empleado por `ID Empleado`. Tres razones:
propagar el texto plano a un cuarto sistema lo empeora; un telefono perdido en un
potrero no puede abrir la nomina de la empresa; y el Dia 2 pedia hash de todas formas.

La tabla local de la app **no tiene columna donde guardar una contrasena**, y hay un
test que lo verifica. No alcanza con acordarse de no leerla: si la columna no existe,
no se puede copiar por descuido.

> Pendiente en Nomina Core, fuera del alcance de este proyecto pero **conviene
> arreglarlo**: migrar `Personal.Password` a un hash. Cinco sistemas ya la consumen.

### Registro de la app: pendiente

`Sirius Nomina Core` tiene `Sistemas y Aplicaciones` (`SIRIUS-APP-0001` a `0005`) con
`Accesos_Personal_Sistema` y `Niveles_Acceso` — un RBAC ya construido. Lo correcto es
registrar **Sirius Agro como `SIRIUS-APP-0006`** y dar los accesos ahi, en vez de
inventar un esquema paralelo. **No se escribio en la base de nomina**: eso queda para
que lo haga alguien con esa decision en la mano.

## Territorio: Barranca de Upia

`Veredas` (`tbl8IIpcNFOHsgNOp`) tiene las 7 veredas del municipio: **Carutal, El
Algarrobo, El Hijoa, Guaicaramo, Las Moras, Los Pavitos, San Ignacio**
(departamento Meta).

`Codigo DANE` quedo vacio a proposito: no se cargo un codigo sin verificarlo. Es un
dato de una linea que conviene llenar antes del piloto si se quiere cruzar con
estadistica oficial, pero un codigo equivocado es peor que uno ausente.

**Semilla offline.** Las veredas y las 55 variables activas van empaquetadas en el
APK (`app/assets/semilla/*.json`). Sin eso, un visitador que instala la app y se va
al campo sin abrirla con red no tendria selector de veredas ni obligatorios: la
completitud diria 0% de 0 campos y la lista de faltantes saldria vacia — la app le
diria que la visita esta bien cuando no sabe nada. Al primer sincronizado, Airtable
sobreescribe la semilla por clave tecnica.

`app/test/semilla_test.dart` verifica que la semilla coincida con el estado real
(7 veredas, 55 activos, 27 obligatorios, todos con `Pregunta guia`). Si alguien
activa un modulo en Airtable y no regenera los assets, las pruebas fallan antes de
que el APK salga a campo.

## Un obligatorio que no se pregunta

`Catalogo de Campos.No sugerir al visitador` marca las variables que **cuentan para
la completitud pero nunca aparecen en la lista de preguntas pendientes** del Dia 11.

Hoy solo `motivo_llegada` esta marcada. Cuenta porque es informacion valiosa cuando
el productor la ofrece; no se sugiere porque preguntarle de frente a alguien por que
le toco dejar su tierra, para cerrar un checklist, es exactamente lo que la
descripcion del campo prohibe.

Consecuencia asumida: la completitud de una visita puede quedarse debajo de 100% sin
que el visitador tenga forma de saber que le falta. Es el precio correcto — el
checklist no manda sobre la conversacion. En la app: `faltantes()` las incluye,
`faltantesSugeribles()` no.

> La casilla esta **invertida** (marcada = no sugerir) porque en Airtable una casilla
> no puede venir marcada por defecto, y el default correcto es "si se puede preguntar".

## Consentimiento (Ley 1581/2012)

Los tres consentimientos viven en `Visitas`, no en `Productores`: se piden **en cada
visita**, porque autorizar una grabación en marzo no autoriza la de septiembre.

| Campo | Efecto en la app |
|---|---|
| `Consiente audio` | El botón de grabar está **deshabilitado** hasta marcarlo |
| `Consiente fotos` | La cámara no se habilita sin él |
| `Consiente uso de datos` | Autoriza el tratamiento para diagnóstico y acompañamiento |
| `Segundo del consentimiento` | Segundo del audio donde consta verbalmente — es la prueba auditable |
| `Marcada para eliminacion` | El productor revocó: el backend borra audio del bucket, fotos y hallazgos |

`Productores.Consentimiento de datos` queda como el consentimiento marco de la
persona; no reemplaza los de la visita.

## Transcripcion diarizada — el contrato con la extraccion

`Grabaciones.Transcripcion con marcas de tiempo` lleva **un turno por linea**,
con este formato exacto:

```
[00:07] Hablante 1: Buenos dias don Pedro, yo trabajo con Sirius.
[00:19] Hablante 2: Mucho gusto, Pedro Rodriguez.
[00:34] Hablante 2: La finca sera de unas doce hectareas.
```

**Este formato es el contrato con el Dia 5.** El modelo de extraccion lo lee y de
ahi saca `cita_textual` y `segundo`. Cambiarlo obliga a revisar el prompt.

Motor: **Deepgram** con `diarize=true` y `utterances=true`. `utterances` es lo que
agrupa las palabras en turnos ya cerrados; sin eso habria que reconstruirlos a mano
juntando palabras por hablante, que es el trabajo que el proveedor ya hizo mejor.

> **Idioma:** Deepgram **no expone un codigo `es-CO`.** El spec lo pedia, pero no
> existe. Se usa `es-419` (espanol latinoamericano), que es lo mas cercano al habla
> llanera. Es configurable por `.env`: si el piloto muestra que `es` transcribe
> mejor, se cambia sin tocar codigo.

### Vocabulario de refuerzo

Un motor generico transcribe «Guaicaramo» como «guai caramo» y «gallinaza» como
«gallina asa». Cada error rompe algo concreto: la vereda no empareja con el listado,
el insumo no se reconoce, y el apellido del productor queda mal **en el informe que
se le entrega en la mano**.

La lista base (`backend/app/services/vocabulario.py`) trae veredas, cultivos del
piedemonte, insumos, unidades y terminos del oficio. Pero lo que la vuelve util de
verdad se le suma **por visita**: el nombre del productor, su vereda y su finca. Un
termino generico ayuda poco; el apellido de la persona que esta hablando ayuda mucho.

El nombre va completo y partido en palabras, porque el agricultor dice «Pedro» a
secas y el visitador «don Pedro Rodriguez». Las palabras de una o dos letras se
descartan: no aportan y gastan cupo del limite del proveedor.

> El nombre del parametro **cambia entre generaciones del modelo**: `nova-2` usa
> `keywords`, `nova-3` usa `keyterm`. Pasar el equivocado **no da error** — Deepgram
> lo ignora en silencio y el refuerzo simplemente no ocurre. El codigo lo elige por
> el nombre del modelo.

### Quien es el visitador: una sugerencia, no un dato

La diarizacion separa las voces pero no sabe cual es cual. Y de eso depende la regla
dura de que **lo dicho por el visitador nunca queda Confirmado**.

El backend propone: en una visita que salio bien el agricultor habla mas que el
visitador, asi que la voz con menos tiempo de habla es probablemente la del
visitador. Devuelve `hablante_visitador_sugerido` **con su razon en una linea**, y si
las dos voces hablaron parecido devuelve `null` en vez de adivinar.

**Lo confirma el visitador de un toque en la validacion, una vez por visita.** Si el
mapeo se invierte, se degrada el dato del agricultor y se avala el del visitador —
exactamente al reves de lo que la regla busca. Fingir precision aca es peor que
preguntar.

## El audio vive en el bucket, no en Airtable

`Grabaciones.Enlace de audio` (url) es la fuente de verdad. `Grabaciones.Audio`
(adjunto) queda solo como respaldo de audios cortos, porque Airtable topa en **5 MB
por archivo** y sus URLs expiran en horas — y una conversación de 30 min pesa ~7 MB.
Si el audio solo vive en el adjunto, en unos meses no se puede volver a escuchar la
cita que respalda un dato, y ahí se cae toda la procedencia.

Credenciales del bucket **solo en el backend**. La app sube contra un endpoint del
backend, nunca contra S3 directo.

### El PDF del informe: la excepcion, con URL prefirmada

El informe lleva las fotos embebidas a resolución completa y pesa **más que el
cuerpo máximo del host** (4,5 MB en Vercel, límite de infraestructura que no se
configura), así que no cabe por `POST /v1/archivos` como el audio y las fotos.

La app pide `POST /v1/archivos/firma` y el backend devuelve un PUT prefirmado
contra `visitas/<uuid>/informes/informe-NN.pdf`. No rompe la regla de arriba: una
URL firmada no es una llave, es un permiso que vence a los 15 min y que autoriza
**una sola ruta** — la arma el backend, nunca el cliente, porque si el teléfono
pudiera elegirla podría escribir sobre el audio de otra visita.

Se archiva el PDF que se compartió, no uno regenerado en el servidor: el documento
que respalda lo acordado en la finca es el que el productor tiene en la mano, y un
renderizador que cambia en seis meses daría otro papel. El `NN` es la versión del
informe, porque las versiones no se borran — sin eso, regenerar sobreescribiría en
el bucket el informe que ya se entregó.

`Informes.Enlace del PDF` (url) es la fuente de verdad; `Informes.PDF` (adjunto) es
respaldo, por el mismo tope de 5 MB. Puede llegar vacío en el primer upsert: el PDF
va por su propio ítem de la cola (prioridad 300, detrás del audio y las fotos) y la
visita se vuelve a encolar cuando termina de subir.

Como la clave empieza por la visita, `borrar_visita` barre el informe junto con el
audio y las fotos: `Marcada para eliminacion` sigue cumpliéndose completa.

### Dos informes por visita: el del agricultor y el técnico

Una visita puede tener **dos series de informes**, cada una con su propia
numeración de versiones, distinguidas por `Informes.Tipo`:

| `Tipo` | Formato | Quién lo lee | Carpeta en el bucket |
| --- | --- | --- | --- |
| `Resumen para el agricultor` | FT-AGRO-001 | El productor, en su casa | `visitas/<uuid>/informes/informe-NN.pdf` |
| `Informe tecnico de visita` | FT-AGRO-002 | La empresa | `visitas/<uuid>/informes_tecnicos/informe-tecnico-NN.pdf` |

Las carpetas son distintas porque el backend renombra por categoría y por orden,
y las dos series comparten numeración: en la misma carpeta, el técnico 01
sobreescribiría el del agricultor 01 — y el que se perdería es el que ya se
entregó. La app pide la firma con `categoria=informes_tecnicos`; `firmar_subida`
acepta esas dos categorías y ninguna más.

La opción nueva de `Tipo` **no hay que crearla a mano**: la sincronización
escribe con `typecast`, así que Airtable la agrega la primera vez que llega un
informe técnico.

Diferencia de fondo entre los dos: el del agricultor lo **escribe el modelo** a
partir de la conversación. El técnico **no pasa por el modelo** — se arma en el
teléfono con lo que ya está en la base (coordenadas de la visita y de la finca,
áreas y perímetros calculados sobre los vértices caminados, hallazgos con su
certeza, metadatos de cada foto, el registro de consentimiento con el segundo del
audio donde consta). Por eso sus números se pueden auditar y por eso se genera
**sin señal**. `Informes.Contenido` del técnico lleva las mismas tablas en
markdown, para poder leerlo en Airtable sin abrir el adjunto y para poder
rearmar el documento si el renderizador cambia.

## El chat que escribe: complementar una visita

`POST /v1/complemento` es el único punto del sistema donde un dato entra al
registro **sin haber pasado por el audio**. El visitador escribe lo que quedó a
medias —«el esposo se llama Hernán», «el arriendo son 600 mil al mes»— y eso se
guarda como `Hallazgos` de la visita, sube a Airtable y mueve la completitud.

Lo que lo hace aceptable no está en el prompt, porque un modelo puede
desobedecer una instrucción:

1. **El backend marca la procedencia, no el modelo**: todo hallazgo que sale de
   ahí lleva `fuente = Manual` y `hablante = visitador`, reescritos por el
   servicio. Si el modelo pudiera elegir esos dos campos, bastaría una
   alucinación para que un dato tecleado entrara como si lo hubiera afirmado el
   agricultor frente a una grabadora.
2. **Esa marca dispara la regla dura número 1**: `Hablante = visitador` ⇒ nunca
   `Confirmado`. La app la aplica al escribir (`insertarHallazgo`) y el backend
   al sincronizar. Un complemento entra, como mucho, `Estimado`.
3. **Cada dato lleva como `Cita textual` la frase con que el visitador lo
   dijo.** Es lo que hace auditable el guardado directo: meses después, un valor
   que no vino del audio se puede explicar.

El `segundo` viaja en `null` a propósito: no hay grabación detrás, y un segundo
inventado mandaría a alguien a escuchar un minuto donde nadie dijo nada.

**La conversación completa se archiva** como una fila de `Informes` con
`Tipo = Complemento de la visita` (opción creada sola por `typecast`). Es **una
fila por visita que se reescribe**, no una versión por mensaje: veinte turnos
dejarían veinte informes y ninguno sería el bueno. Se guarda literal y no
resumida porque es el registro de procedencia — un resumen escrito por el modelo
sería un registro de procedencia que ya pasó por un modelo.

El chat **no sugiere** los campos marcados `No sugerir al visitador`. Preguntarle
a alguien por qué le tocó dejar su tierra, para cerrar un checklist, es justo lo
que esa bandera existe para impedir, y el chat no es la excepción.

## El historial baja: la primera lectura de visitas

Hasta esta version la sincronizacion era **de una sola via**: el telefono
empujaba y nunca bajaba. `GET /v1/productores/{id}/visitas` es la primera
excepcion despues del directorio — devuelve las visitas ya registradas de un
agricultor, con sus hallazgos, evidencias, grabaciones e informes.

Tres reglas lo gobiernan, y las tres existen para que consultar el historial no
pueda costar trabajo de campo:

1. **Se pide por agricultor**, nunca "todas". Bajarle a un telefono de campo el
   historial del equipo entero mueve datos personales de productores a
   dispositivos que no los registraron.
2. **Baja como espejo de solo lectura.** En la app esas visitas llevan
   `Visitas.soloLectura = true` (esquema local v9) y el guardarraíl vive en
   `encolarVisita`, por donde pasan todos los caminos que escriben en Airtable:
   un espejo **nunca** entra a la cola. Sin eso, consultar el historial podria
   reescribir en el registro central la visita de otro visitador con los datos
   parciales que este telefono alcanzo a bajar.
3. **Una visita que ya esta en el telefono y no es espejo se salta entera.** Ahi
   el telefono es la fuente de verdad, porque es donde se registro.

Detalles que importan al leer:

- Los hijos enlazan a la visita por **record id**, no por codigo. Casar por
  codigo devuelve visitas sin un solo hallazgo y **sin ningun error**, que se
  leen como visitas donde no se registro nada.
- `Completitud (%)` vuelve de fraccion a porcentaje (0,48 → 48%).
- Las fotos solo existen como **adjunto** de `Evidencias`, y Airtable rota esas
  URL cada pocas horas: la app baja los bytes en el momento y se queda con el
  archivo, no con el enlace. El audio y el PDF si tienen URL del bucket, que no
  caduca.
- El segundo del audio de una foto viaja al frente de `Descripcion del
  visitador` como `[MM:SS]` —la tabla no tiene columna propia— y la app lo
  vuelve a separar al importarlo.
- Del catalogo solo viaja la **clave tecnica**; el nombre legible del campo y su
  modulo los resuelve la app contra su catalogo sembrado. Un hallazgo cuya clave
  no este en el catalogo de ese APK se descarta y se cuenta, en vez de romper la
  importacion entera.

## Trazados: capturados en la app, todavia no en Airtable

Desde la version del croquis, una visita puede llevar **poligonos de lote y
recorridos** caminados con el GPS del telefono. Es lo que reemplaza el «seran
unas diez hectareas» de la conversación por una medida: un área dicha no
calcula una dosis ni compara dos visitas.

Dónde vive hoy:

- **En el teléfono**, en `Trazados` y `PuntosTrazado` (SQLite, esquema v6). Es
  la fuente de verdad.
- **En el KML** que exporta la pantalla del trazado y que se comparte por
  WhatsApp o correo. Abre en Google Earth y en QGIS.
- **En el `.zip`** de la visita, como `trazados.kml`, con cada vértice y su
  precisión.
- **En el payload** de `POST /v1/visitas`, ya tipado (`TrazadoPayload`).

Lo que falta: **el backend NO los escribe en Airtable todavía.** Hacen falta dos
tablas y no se inventan desde el código — escribir en un campo que no existe
hace que Airtable rechace el registro **entero**, y se perdería la
sincronización de la visita completa, no solo del polígono.

Cuando se creen, el contrato ya está definido por el payload:

| Tabla | Campos |
| --- | --- |
| `Trazados` | `Id` (texto, UUID del teléfono, llave de idempotencia), `Visita` (link), `Nombre`, `Tipo` (Poligono/Ruta/Punto), `Modo de captura` (Manual/Automatico/Mixto), `Etiqueta`, `Notas`, `Cerrado` (casilla), `Area (ha)`, `Perimetro (m)`, `Intervalo (s)`, `Distancia minima (m)`, `Precision maxima (m)`, `Creado en` |
| `Puntos de trazado` | `Id`, `Trazado` (link), `Orden`, `Latitud`, `Longitud`, `Altitud`, `Precision (m)`, `Capturado en`, `Automatico` (casilla), `Nota` |

Dos decisiones del modelo que conviene no deshacer:

**1. Cada punto guarda su precisión y si lo puso el dedo o el reloj.** Sin esa
huella no se puede decidir, tres meses después, si un lindero raro fue un error
del visitador o un salto del GPS bajo los árboles — y un área que nadie puede
auditar no sirve para calcular nada.

**2. Los puntos no se diezman al subir.** Un recorrido de 40 minutos son
cientos de coordenadas y el JSON crece, pero submuestrear en el cliente destruye
la única copia del lindero: lo que se manda es lo que se caminó.

## Vistas que conviene crear a mano en Airtable

- Visitas → **Por sincronizar** (`Sincronizada` = off) y **En validación** (`Estado` = En validacion).
- Hallazgos → **Revisar** (`Estado` = Requiere confirmacion, o `Confianza` < 70%), agrupada por Módulo.
- Oportunidades → **Pipeline** (agrupada por `Estado`, ordenada por `Prioridad`).
- Catalogo de Campos → **V1** (`Activo` = on) — son las 55 variables que se le piden al modelo.
- Catalogo de Campos → **MVP** (`Activo` = on y `Obligatorio MVP` = on) — son los 23 campos que definen la completitud.
- Hallazgos → **Sin procedencia** (`Cita textual` vacía) — control de calidad del pipeline.
