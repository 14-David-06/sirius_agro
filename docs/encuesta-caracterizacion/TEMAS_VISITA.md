# Temas de la encuesta en la visita

> Archivo generado por `app/tool/encuesta/generar_catalogo.py`. Para cambiarlo, edite las tablas de ese
> script (`TEMAS`, `REACTIVADOS`, `REDUNDANTES`, `QUITADAS`, `AJUSTES`) y vuelva a generar.

Las preguntas de la encuesta no son un cuestionario aparte: son temas que se hablan en la visita. Entran al
catálogo de campos de la app, que es de donde sale la lista «Cobertura de la conversación» y lo que la IA busca
en la grabación.

- **61 temas nuevos**: 56 aparecen en la lista y 5 son sensibles (no se sugieren).
- **5 preguntas usan 6 campos que ya existían en Airtable, apagados**: se prendieron en vez de crear temas repetidos.
- **40 preguntas no se agregaron** porque el catálogo o la visita ya las cubren.
- **10 preguntas se quitaron** a pedido: 41, 42, 43, 44, 67, 76, 77, 78, 79, 87.
- **4 temas que ya estaban se ajustaron** a pedido: Identificación quedó en una sola pregunta.

## 1. Temas nuevos

### Agua y riego

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 34 | Agua para tomar y cocinar | ¿De dónde sacan principalmente el agua para tomar y cocinar? | Lista | Sí |
| 100 | Cuidado del agua | ¿Qué hace para cuidar y aprovechar el agua? | Texto | Sí |

### Aspiraciones y proyectos

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 111 | Planes con la finca | En los próximos 5 años, ¿piensa seguir trabajando la finca? | Lista | Sí |
| 113 | Temas en que quiere capacitarse | ¿En qué temas le gustaría recibir capacitación o acompañamiento? (máximo 3) | Texto | Sí |
| 114 | Como prefiere el acompanamiento | ¿Cómo prefiere recibir el acompañamiento? (máximo 2) | Texto | Sí |
| 115 | Interes en asociarse | ¿Le interesaría unirse con otros productores para comprar insumos, vender juntos o acceder a proyectos? | Lista | Sí |

### Conectividad

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 104 | Aparatos en el hogar | ¿Con cuáles de estos aparatos cuenta su hogar? | Texto | Sí |
| 105 | Internet en la casa o la finca | ¿Tienen internet en la casa o en la finca? | Lista | Sí |
| 107 | Frecuencia de uso de internet | ¿Con qué frecuencia usa usted internet (en el celular u otro aparato)? | Lista | Sí |
| 108 | Manejo del celular y el computador | ¿Qué tanto sabe usar… a) el celular inteligente; b) el computador? | Texto | Sí |
| 109 | Para que usa el celular o internet | ¿Para qué usa el celular o internet? | Texto | Sí |

### Cultivos

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 72 | Destino de la cosecha | ¿Para qué es principalmente la cosecha de este cultivo? | Lista | Sí |
| 73 | Perdidas de la cosecha | De la última cosecha, ¿qué parte se perdió (por plagas, clima, daño o porque no se pudo vender)? | Lista | Sí |
| 74 | Semilla o material de siembra | ¿Qué semilla o material de siembra usó? | Lista | Sí |

### Economia y comercializacion

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 48 | Parte del ingreso que viene de la finca | De toda la plata que entra al hogar, ¿qué parte viene de la finca? | Lista | Sí |
| 49 | Los ingresos alcanzan | Con la plata que entra al hogar, ¿les alcanza para los gastos básicos (comida, servicios, transporte, estudio)? | Lista | Sí |
| 50 | La finca deja ganancia | En los últimos 3 años, ¿la finca le ha dejado ganancia después de pagar los gastos? | Lista | Sí |
| 52 | Cuenta, billetera digital y seguros | ¿Usted tiene alguno de estos productos? | Texto | Sí |
| 54 | Credito: por que no lo pidio o se lo negaron | ¿Por qué no pidió el crédito, o por qué se lo negaron? | Texto | Sí |
| 55 | Credito: quien le presto | ¿Quién le prestó? | Texto | Sí |
| 56 | RUT, Camara de Comercio y factura | ¿Tiene alguno de estos registros para su actividad productiva? | Texto | Sí |
| 92 | Acuerdo con el comprador | ¿Qué tipo de acuerdo tiene con su comprador principal? | Lista | Sí |
| 93 | Como saca los productos | ¿Cómo saca los productos para venderlos? | Lista | Sí |
| 95 | Dificultades para vender | ¿Cuáles son las mayores dificultades para vender sus productos? (máximo 3) | Texto | Sí |

### Familia y social

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 12 | Nivel de estudios de cada persona | ¿Hasta qué año o nivel estudió? | Texto | Sí |
| 13 | Sabe leer y escribir | ¿Sabe leer y escribir? | Texto | Sí |
| 14 | Estudia actualmente | ¿Actualmente estudia (escuela, colegio, SENA o universidad)? | Texto | Sí |
| 15 | Afiliacion a salud | ¿Está afiliado(a) a salud (EPS)? ¿De qué forma? | Texto | Sí |
| 16 | Ocupacion de cada persona | ¿A qué se dedica principalmente? | Texto | Sí |
| 17 | Dificultades permanentes | ¿Tiene alguna dificultad permanente (que no se quita) para alguna de estas actividades? Marque solo si tiene mucha dificultad o no puede hacerlo. | Texto | No: tema sensible |
| 18 | Jefatura del hogar | En su hogar, ¿quién es reconocido(a) como la cabeza o jefe(a) del hogar? | Lista | Sí |
| 19 | Se considera campesino | ¿Usted se considera campesino(a)? | Lista | No: tema sensible |
| 20 | Pertenencia etnica | Esta pregunta es voluntaria. De acuerdo con su cultura, su pueblo o sus tradiciones, ¿usted se reconoce como…? | Lista | No: tema sensible |
| 27 | Cotiza a pension | ¿Usted cotiza o aporta para pensión? | Lista | Sí |
| 28 | Cuidado de personas a cargo | ¿Usted tiene a su cargo el cuidado permanente de alguna persona (niños pequeños, personas mayores, enfermas o con discapacidad)? | Lista | Sí |
| 29 | Vivienda: tenencia | La casa donde vive su familia es: | Lista | Sí |
| 30 | Vivienda: material de las paredes | ¿De qué material son la mayoría de las paredes de la casa? | Lista | Sí |
| 31 | Vivienda: material del piso | ¿De qué es la mayor parte del piso de la casa? | Lista | Sí |
| 32 | Vivienda: cuartos para dormir | ¿En cuántos cuartos duermen las personas de su hogar? | Numero | Sí |
| 33 | Vivienda: energia electrica | ¿La casa tiene luz (energía eléctrica)? ¿De dónde viene principalmente? | Lista | Sí |
| 35 | Vivienda: servicio sanitario | ¿Qué tipo de baño o servicio sanitario tiene la casa? | Lista | Sí |
| 36 | Vivienda: con que cocinan | ¿Con qué cocinan principalmente? | Lista | Sí |
| 37 | Vivienda: manejo de la basura | ¿Qué hacen principalmente con la basura de la casa? | Lista | Sí |
| 38 | Tiempo al pueblo, a salud y a la escuela | ¿Cuánto tiempo se demora en llegar desde la finca, por el medio que usa normalmente, hasta… a) el pueblo (cabecera municipal); b) el centro o puesto de salud más cercano; c) la escuela o colegio más cercano? | Texto | Sí |
| 39 | Sisben | ¿Su hogar está registrado en el Sisbén? ¿Sabe en qué grupo está? | Lista | Sí |
| 45 | Alimentos para el consumo de la casa | ¿Qué alimentos producen en la finca para el consumo de la casa? | Texto | Sí |
| 61 | Quien decide en la finca | ¿Quién toma las decisiones sobre la finca (qué sembrar, qué vender, en qué invertir)? | Lista | Sí |
| 97 | Participacion en organizaciones | ¿Qué tanto participa en esa(s) organización(es)? | Lista | No: tema sensible |

### Historia y origen

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 22 | Afectacion por el conflicto | Esta pregunta es voluntaria. ¿Usted o alguien de su familia ha sido afectado por el conflicto armado (por ejemplo, desplazamiento, despojo o abandono de tierras)? | Lista | No: tema sensible |
| 26 | Formacion en temas del campo | ¿Ha hecho algún curso o estudio sobre temas del campo? | Lista | Sí |

### Insumos y manejo

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 84 | Proteccion al aplicar quimicos | Cuando aplica químicos, ¿usa elementos de protección (guantes, tapabocas, gafas, overol, botas)? | Lista | Sí |
| 85 | Envases vacios de quimicos | ¿Qué hace con los envases vacíos de los químicos? | Lista | Sí |
| 88 | Asistencia tecnica: recibio | En el último año, ¿recibió asesoría o asistencia técnica para la finca? | Si/No | Sí |
| 89 | Asistencia tecnica: quien se la dio | ¿Quién se la dio? | Texto | Sí |
| 90 | Asistencia tecnica: utilidad | ¿Qué tan útil le pareció esa asistencia? | Lista | Sí |

### Riesgos y clima

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 103 | Tumba de monte o bosque | En los últimos 5 años, ¿ha tumbado monte o bosque para sembrar o hacer potreros? | Si/No | Sí |

### Tierra y tenencia

| P | Tema | Pregunta | Tipo | En la lista |
|---:|---|---|---|---|
| 23 | Vive en la finca | ¿Usted vive en la finca? | Lista | Sí |
| 24 | Dedicacion a la finca | ¿Cuánto tiempo le dedica usted al trabajo de la finca? | Lista | Sí |
| 59 | Documento de la tierra | ¿Qué papel o documento tiene de esa tierra? | Lista | Sí |
| 60 | Documento de la tierra: a nombre de quien | ¿A nombre de quién está ese documento? | Lista | Sí |
| 63 | Como esta repartida la tierra | ¿Cómo está repartida la tierra de la finca? Marque los usos que tiene y, si sabe, cuántas hectáreas tiene en cada uno. | Texto | Sí |

## 2. Preguntas que usan un campo que ya existía en Airtable

Estos campos estaban en el «Catalogo de Campos» con «Activo» sin marcar. Conservan su nombre, su módulo,
su tipo y su pregunta guía, tal como están en Airtable. Aparecen en la lista en su propio módulo.

| P | Pregunta de la encuesta | Campo de Airtable | Módulo | Pregunta guía | Tipo |
|---:|---|---|---|---|---|
| 40 | En el último año, ¿usted o alguien de su hogar recibió alguna ayuda o subsidio del Gobierno? | `apoyos_recibidos`: Apoyos institucionales recibidos | Creditos y apoyos | ¿Lo ha visitado alguna entidad o programa? | Texto |
| 53 | En el último año, ¿pidió algún préstamo o crédito para la finca? | `tiene_credito`: Tiene credito | Creditos y apoyos | ¿Tiene algun credito o deuda con banco? | Si/No |
| 64 | ¿Con cuáles de estos equipos o instalaciones cuenta la finca? | `maquinaria`: Maquinaria y equipos | Maquinaria e infraestructura | ¿Que herramientas o maquinas tiene? | Texto |
| 64 | ¿Con cuáles de estos equipos o instalaciones cuenta la finca? | `infraestructura`: Infraestructura de la finca | Maquinaria e infraestructura | ¿Que construcciones tiene: beneficiadero, bodega, corral? | Texto |
| 66 | ¿Contrata trabajadores para la finca? | `contrata_jornaleros`: Contrata jornaleros | Mano de obra | ¿Contrata gente para las labores? | Si/No |
| 94 | ¿Cómo está el camino principal para llegar a la finca? | `acceso_vial`: Acceso vial | Maquinaria e infraestructura | Observacion del visitador al llegar. | Lista |

## 3. Preguntas que no se agregaron por repetidas

| P | Pregunta de la encuesta | Ya la cubre |
|---:|---|---|
| 1 | Le vamos a hacer unas preguntas sobre su familia y su finca para saber cómo podemos acompañarlos mejor. La información es confidencial y solo se usa para este proyecto. ¿Nos autoriza a registrar y usar sus respuestas? | El permiso de uso de datos que la visita pide al empezar |
| 2 | Algunas preguntas son más personales: discapacidad, pertenencia étnica o campesina, si ha sido víctima del conflicto y participación en organizaciones. Usted decide si las responde. ¿Nos autoriza a registrar esas respuestas? | No es un tema de conversacion: los temas sensibles no se sugieren |
| 3 | ¿Cuál es su nombre completo? | `nombre_productor`: Con quien tengo el gusto? |
| 4 | ¿Qué documento de identidad tiene y cuál es el número? | `documento_identidad`: Me regala su numero de cedula para el registro? |
| 5 | ¿A qué número de celular lo podemos llamar o escribir? ¿Ese número tiene WhatsApp? | `telefono`: A que numero lo puedo contactar? |
| 6 | ¿En qué municipio y vereda queda la finca y cómo se llama la finca? | `municipio_vereda`: ¿En qué parte de la vereda nos encontramos? |
| 7 | ¿Cuántas personas viven en esta casa y comparten la comida, contándose usted? | `personas_hogar`: Quienes viven aqui con usted? |
| 8 | ¿Cuál es el nombre de esta persona? (solo el primer nombre) | `personas_hogar`: Quienes viven aqui con usted? |
| 9 | ¿Qué es esta persona de usted? | `personas_hogar`: Quienes viven aqui con usted? |
| 10 | Sexo (el encuestador lo registra; si tiene duda, pregunte con respeto). | `personas_hogar`: Quienes viven aqui con usted? |
| 11 | ¿Cuántos años cumplidos tiene? | `personas_hogar`: Quienes viven aqui con usted? |
| 21 | ¿Hace cuánto tiempo vive en esta vereda? | `anios_en_territorio`: Hace cuanto vive por aca? |
| 25 | ¿Cuántos años lleva trabajando como productor(a) del campo? | `anios_experiencia`: Hace cuanto trabaja en el campo? |
| 46 | ¿De dónde viene la plata de su hogar? Marque todas las que apliquen. Luego: ¿cuál es la más importante? | `otros_ingresos`: Tiene otras entradas fuera de la finca? |
| 47 | Sumando todo lo que entra a su hogar en un mes normal (de todas las personas y actividades), ¿en cuál de estos rangos está? (mostrar la tarjeta de rangos) | `ingreso_mensual`: Cuanto le entra al mes de la finca? |
| 51 | ¿Lleva cuentas de lo que gasta y lo que gana en la finca? | `lleva_registros`: Apunta lo que gasta y lo que vende? |
| 57 | ¿Cuánta tierra tiene la finca en total (incluyendo monte, potreros y cultivos)? Si conoce el dato exacto, anótelo. | `area_total_ha`: De que tamano es la finca? |
| 58 | La tierra que trabaja es principalmente: | `tenencia`: La tierra es propia, arrendada o de la familia? |
| 62 | ¿Qué actividades se hacen en la finca? | `cultivos_principales`: Que tiene sembrado? |
| 65 | ¿Cuántas personas de su familia trabajan de forma permanente en la finca, incluyéndose usted? ¿Cuántas de ellas son mujeres? | `trabajo_familiar`: Quien le ayuda con el trabajo de la finca? |
| 68 | ¿Cuál es el cultivo? | `cultivos_principales`: Que tiene sembrado? |
| 69 | ¿Cuánta área tiene sembrada de este cultivo? | `area_por_cultivo`: Cuanto tiene de cada cultivo? |
| 70 | ¿En qué etapa está el cultivo? | `edad_cultivo`: Hace cuanto sembro? |
| 71 | En el último año, ¿cuánto cosechó de este cultivo? (si no ha cosechado, anote 0) | `rendimiento`: Cuanto le esta produciendo? |
| 75 | ¿Qué animales tiene hoy en la finca, cuántos y para qué? | `animales`: Tiene animales? Cuantos? |
| 80 | En el último año, ¿qué le aplicó a la tierra o a los cultivos para abonarlos o mejorarlos? | `fertilizantes_usados`: Que le esta aplicando al cultivo? (fotografiar etiquetas) |
| 81 | ¿Qué tanto conoce los bioinsumos (productos con hongos, bacterias u otros organismos benéficos, como Trichoderma o Beauveria)? | `usa_bioinsumos`: Ha usado productos biologicos? |
| 82 | ¿Alguna vez le han hecho análisis de suelo a la finca? | `tiene_analisis_suelo`: Alguna vez le ha hecho analisis al suelo? |
| 83 | ¿Cómo controla las plagas, las enfermedades y las malezas? | `plaguicidas_usados`: Que usa para las plagas y enfermedades? (fotografiar etiquetas) |
| 86 | ¿Hace alguna de estas prácticas para cuidar el suelo? | `practicas_conservacion_suelo`: Hace algo para cuidar el suelo? |
| 91 | ¿A quién le vende principalmente lo que produce? | `comprador`: A quien le vende la produccion? |
| 96 | ¿Usted pertenece a alguna organización o grupo? | `organizacion`: Pertenece a alguna asociacion o cooperativa? |
| 98 | ¿De dónde saca el agua para los cultivos y los animales? | `fuente_agua`: De donde saca el agua? |
| 99 | En los últimos 3 años, ¿qué problemas ha tenido con el agua de la finca? | `escasez_agua`: En que epoca le falta el agua? |
| 101 | En el último año, ¿qué problemas del clima o de la naturaleza afectaron la finca? | `eventos_climaticos`: Como le ha pegado el verano o el invierno? |
| 102 | ¿Ha notado alguno de estos problemas en el suelo de la finca? | `problemas_suelo`: Como ve el suelo? Se le compacta, se le lava, se le seca? |
| 106 | ¿Cómo es la señal de celular en la finca? | `calidad_senal`: Como es la senal aqui en la finca? |
| 110 | ¿Hay algún joven de la familia (menor de 40 años) que trabaje en la finca y quiera seguir con ella? | `relevo_generacional`: Los hijos siguen en el campo o se fueron? |
| 112 | ¿Cuáles son los 3 problemas más grandes que tiene hoy para sacar adelante la finca? | `riesgo_principal`: Que es lo que mas lo preocupa hoy? |
| 116 | Si tuviera apoyo, ¿qué mejora o proyecto le gustaría hacer en su finca? (respuesta corta) | `que_quiere_mejorar`: Que le gustaria mejorar en la finca? |

## 4. Ajustes a temas que ya estaban en el catálogo

Cambios pedidos sobre campos que ya venían de Airtable. Solo están en la app: en Airtable esos registros
siguen como estaban.

| Campo | Qué cambió | Antes | Ahora |
|---|---|---|---|
| `telefono` | Sale en la lista y cuenta | Sí | No |
| `nombre_productor` | Sale en la lista y cuenta | Sí | No |
| `municipio_vereda` | Nombre | Municipio y vereda | Parte de la vereda donde queda la finca |
| `municipio_vereda` | Pregunta | En que vereda estamos? | ¿En qué parte de la vereda nos encontramos? |
| `nombre_finca` | Sale en la lista y cuenta | Sí | No |

## 5. Preguntas quitadas a pedido

| P | Pregunta de la encuesta |
|---:|---|
| 41 | …¿se preocuparon de que la comida se acabara? |
| 42 | …¿tuvieron que comer poca variedad de alimentos o comida poco nutritiva? |
| 43 | …¿algún adulto tuvo que saltarse una comida o comer menos de lo que necesitaba? |
| 44 | …¿se quedaron sin comida en la casa o alguien pasó todo un día sin comer? |
| 67 | ¿En la vereda hacen trabajo en minga, convite o mano vuelta (ayudarse entre vecinos)? |
| 76 | ¿Para qué tiene principalmente el ganado? |
| 77 | ¿Cuántos litros de leche saca al día en total? |
| 78 | ¿Cómo alimenta el ganado? |
| 79 | En el último año, ¿vacunó al ganado (por ejemplo, contra aftosa o brucelosis)? |
| 87 | ¿La finca tiene alguno de estos registros o certificaciones? |
