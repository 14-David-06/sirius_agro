# Temas de la encuesta de caracterización dentro de la visita

Las preguntas de la encuesta de caracterización **no son un cuestionario aparte**: son temas que se hablan en la visita. Por eso
entran a la lista **«Cobertura de la conversación»** de cada visita, junto a los temas que ya había. Rama: `feature/encuesta-caracterizacion`.

## Cómo funciona

La visita no cambió de forma de trabajar:

1. El visitador conversa con el productor y graba.
2. La lista «Cobertura de la conversación» le muestra, por módulo, los temas que faltan por tocar.
3. Al procesar la grabación, la IA saca de la conversación lo que se dijo de cada tema, con su cita.
4. Los temas que ya se hablaron salen de la lista y sube el porcentaje de cobertura.

Lo que cambió es el catálogo de temas:

| | Antes | Ahora |
|---|---:|---:|
| Temas en el catálogo | 55 | 122 |
| Temas que cuentan para la cobertura | 27 | 89 |
| Temas que aparecen en la lista de una visita nueva | 26 | 88 |

El detalle de qué entró, qué no y por qué está en `TEMAS_VISITA.md`:

- **61 temas nuevos**, con el texto de la pregunta de la encuesta tal cual. 56 aparecen en la lista.
- **5 son temas sensibles** (discapacidad, identidad campesina, pertenencia étnica, conflicto armado y participación en
  organizaciones). Están en el catálogo para que la IA los registre si el productor los cuenta, pero no se le sugieren al visitador
  ni cuentan para la cobertura. Es la misma regla que la app ya aplicaba al motivo de llegada a la tierra.
- **5 preguntas usan 6 campos que ya existían en Airtable, apagados** (ayudas del Gobierno, crédito, equipos e instalaciones,
  contratación de trabajadores y estado del camino). Se prendieron en vez de crear temas que dijeran lo mismo. Conservan el nombre,
  el tipo y la pregunta guía que tenían en Airtable.
- **40 preguntas no se agregaron** porque el catálogo o la visita ya las cubren (nombre, documento, celular, vereda, tamaño del
  hogar, área, tenencia, cultivos, comprador, fuente de agua, señal…).
- **10 preguntas se quitaron** a pedido: 41 a 44, 67, 76 a 79 y 87.

Los temas nuevos usan los 13 módulos que ya había en la app. Los 6 campos que se prendieron traen sus tres módulos de Airtable, que
ahora aparecen en la lista: «Creditos y apoyos», «Mano de obra» y «Maquinaria e infraestructura».

## Airtable

No se creó ninguna tabla, campo ni opción, y no se creó ningún registro. El único cambio, hecho el 13 de noviembre de 2026 a pedido
de David, fue marcar la casilla «Activo» en 6 registros que ya existían en «Catalogo de Campos»:

| Clave técnica | Campo | Módulo | Pregunta de la encuesta |
|---|---|---|---:|
| `apoyos_recibidos` | Apoyos institucionales recibidos | Creditos y apoyos | 40 |
| `tiene_credito` | Tiene credito | Creditos y apoyos | 53 |
| `maquinaria` | Maquinaria y equipos | Maquinaria e infraestructura | 64 |
| `infraestructura` | Infraestructura de la finca | Maquinaria e infraestructura | 64 |
| `contrata_jornaleros` | Contrata jornaleros | Mano de obra | 66 |
| `acceso_vial` | Acceso vial | Maquinaria e infraestructura | 94 |

Ninguno tenía hallazgos enlazados. Para devolverse basta desmarcar «Activo» en esos 6 registros. Su casilla «Obligatorio MVP» sigue
sin marcar en Airtable; en la app sí cuentan como obligatorios, porque eso es lo que los pone en la lista.

**Los 61 temas nuevos solo existen en la app.** Cuando se sube una visita, el backend descarta los datos cuyo tema no está activo
en el catálogo de Airtable y los reporta, sin crear nada. Eso significa que hoy:

- Lo que se hable de los 6 campos que se prendieron **sí llega a Airtable**, como el resto de la visita.
- Lo que se hable de los 61 temas nuevos **queda en el celular** y en el zip que se exporta de la visita. No llega a Airtable.

Para que lleguen habría que agregar esos 61 temas a la tabla «Catalogo de Campos». Son registros, no cambios de estructura. La app
de producción no cambia por eso: su lista de temas sale del catálogo que trae el APK, no de Airtable.

## Cambiar los temas

Las cuatro tablas están al inicio de `app/tool/encuesta/generar_catalogo.py`:

- `TEMAS`: número de pregunta, módulo y nombre corto de cada tema que se agrega.
- `REACTIVADOS`: preguntas que usan un campo que ya existía en Airtable. Los datos de esos campos están copiados en
  `CAMPOS_DE_AIRTABLE`; si se cambian en Airtable hay que copiar el cambio ahí.
- `REDUNDANTES`: preguntas que no se agregan y qué campo las cubre.
- `QUITADAS`: preguntas que se dejan por fuera.

Hace falta Python 3 con `openpyxl` (`pip install openpyxl`). Desde la raíz del repositorio:

```
python app/tool/encuesta/generar_catalogo.py
cd app
flutter test
```

El script falla, sin escribir nada, si alguna de las 116 preguntas no está en exactamente una de las cuatro tablas. Volver a
correrlo es seguro: quita lo que él mismo agregó y lo vuelve a generar; los 55 campos originales no se tocan. Cada vez que corre
cambia la fecha del catálogo, y con eso la app vuelve a cargar el catálogo al abrirse. Un tema que sale del catálogo queda apagado
en los celulares que ya lo tenían; no se borra, para no dejar sin nombre los datos de visitas ya hechas.

Si un tema nuevo necesita un módulo que la app no tenía, hay que darle ícono en `app/lib/core/iconos_modulo.dart` y regenerar la
fuente del informe en PDF con `python tool/iconos_modulo.py` (requiere `pip install fonttools`).

Los temas marcados como complementarios en el Excel quedaron con prioridad «3 Deseable» y los esenciales con «2 Importante».
Todos aparecen en la lista. Para que los complementarios no aparezcan basta con poner `obligatorio_mvp` en falso para ellos en el script.

## Dónde está cada cosa

| Ruta | Qué es |
|---|---|
| `docs/encuesta-caracterizacion/encuesta_caracterizacion_productores.xlsx` | La fuente: hoja «Encuesta» |
| `app/tool/encuesta/generar_catalogo.py` | Agrega los temas al catálogo y escribe `TEMAS_VISITA.md` |
| `app/assets/semilla/catalogo.json` | El catálogo que trae la app: 55 campos originales, 6 que se prendieron y 61 temas de la encuesta |
| `app/test/catalogo_encuesta_test.dart` | Pruebas de los temas nuevos |
| `docs/encuesta-caracterizacion/TEMAS_VISITA.md` | Lista de temas agregados, prendidos, repetidos y quitados |

Código existente que cambió:

- `app/assets/semilla/catalogo.json` y los números esperados en tres pruebas que fijaban el tamaño del catálogo
  (`semilla_test.dart`, `flujo_visita_test.dart`, `migracion_test.dart`).
- `app/lib/core/iconos_modulo.dart` y `app/assets/fuentes/IconosModulo.ttf`: ícono para los tres módulos que se prendieron.
- `app/lib/data/semilla.dart` y `app/lib/data/db/app_database.dart`: al cargar un catálogo nuevo, la app apaga los temas que ya no
  vienen en él. Antes solo agregaba y actualizaba, así que un tema retirado seguía activo en los celulares que lo habían recibido.

## Lo que no entró a main

Antes de esta aclaración se construyó un formulario de 116 preguntas para llenar dentro de la visita, y un servicio en el backend
que sugería respuestas desde la grabación. Se descartó y **no está en `main`**. Quedó guardado en el último commit de la rama
`feature/encuesta-caracterizacion`, por si sirve de base más adelante:

- El formulario: `app/lib/core/encuesta/`, `app/lib/data/encuesta_repository.dart`, `app/lib/data/caracterizacion_de_visita.dart`,
  `app/lib/state/encuesta.dart`, `app/lib/ui/encuesta/`, sus pruebas y sus enganches en `acciones_visitas.dart`,
  `exportador_visita.dart`, `providers.dart`, `api_client.dart` y `pubspec.yaml`.
- El servicio del backend: `backend/app/services/caracterizacion.py`, `backend/app/schemas_caracterizacion.py` y la ruta
  `POST /v1/caracterizaciones/sugerencias` en `backend/app/main.py`. Nunca se desplegó.
- Los documentos del primer enfoque (guardar la encuesta en una base de 18 tablas): `MAPEO.md`, `SOLICITUD_CAMBIOS_AIRTABLE.md`,
  `DIAGNOSTICO.md`, sus generadores y el resto de las plantillas de origen.

## Compilar el APK de prueba

Canal `dev`, que se instala al lado de la app de producción sin tocarla:

```
cd app
flutter build apk --debug --flavor dev --dart-define=API_BASE_URL=https://sirius-agro.vercel.app --dart-define=API_KEY=<APP_API_KEY>
```
