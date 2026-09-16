import 'package:drift/drift.dart';

import 'enums.dart';

/// Toda entidad lleva un UUID v4 generado EN EL DISPOSITIVO, antes de tener red.
/// Ese id viaja a Airtable como `Codigo de visita` y es la llave de idempotencia:
/// reintentar una sincronizacion nunca duplica la visita.

/// Espejo local del `Catalogo de Campos` de Airtable.
/// Existe para que la app pueda calcular completitud y redactar la lista de
/// faltantes SIN RED. Se refresca al sincronizar, pero nunca es requisito.
@DataClassName('CatalogoCampo')
class CatalogoCampos extends Table {
  TextColumn get claveTecnica => text()();
  TextColumn get campo => text()();
  TextColumn get modulo => text()();
  TextColumn get tipoDato => text().withDefault(const Constant('Texto'))();
  TextColumn get unidad => text().nullable()();

  /// Valores permitidos cuando tipoDato = Lista, uno por linea.
  TextColumn get opciones => text().nullable()();

  /// El motor de faltantes usa esta pregunta TEXTUALMENTE. No la reescribe.
  TextColumn get preguntaGuia => text().nullable()();
  TextColumn get descripcion => text().nullable()();
  BoolColumn get obligatorioMvp => boolean().withDefault(const Constant(false))();
  TextColumn get prioridad => text().nullable()();

  /// Alcance de la version. activo = false significa que sigue existiendo como
  /// esquema pero no se le pide al modelo. Se prende sin tocar codigo.
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  /// Cuenta para la completitud pero NUNCA se le sugiere al visitador como
  /// pregunta pendiente. Para temas sensibles que solo se registran si el
  /// productor los cuenta por su cuenta. Invertido igual que en Airtable,
  /// donde una casilla no puede venir marcada por defecto.
  BoolColumn get noSugerir => boolean().withDefault(const Constant(false))();

  DateTimeColumn get actualizadoEn => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {claveTecnica};
}

/// Ajustes internos de la app, clave/valor.
///
/// Vive en la base y no en shared_preferences a proposito: el unico ajuste
/// que hay hoy es que version de la semilla ya se aplico, y ese dato solo
/// tiene sentido junto a las tablas que describe. Si alguien borra la base, el
/// marcador se va con ella y la semilla se vuelve a aplicar, que es lo
/// correcto. En shared_preferences sobreviviria y mentiria.
@DataClassName('Ajuste')
class Ajustes extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column> get primaryKey => {clave};
}

/// Veredas precargadas para que el selector funcione en modo avion.
@DataClassName('Vereda')
class Veredas extends Table {
  TextColumn get id => text()();
  TextColumn get vereda => text()();
  TextColumn get municipio => text()();
  TextColumn get departamento => text().nullable()();
  TextColumn get remoteId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espejo de los empleados activos de Sirius Nomina Core.
///
/// La persona NO se administra aqui: si alguien entra o sale de la empresa se
/// cambia en nomina y se vuelve a sembrar. La llave entre las dos bases es
/// [idEmpleado], porque Airtable no permite vincular registros entre bases.
///
/// Aqui NO se guarda contrasena: este espejo se siembra desde el APK y viaja
/// en el repositorio. Lo que hace falta para entrar sin senal vive en
/// [CredencialesLocales], que solo se llena tras un login con red.
@DataClassName('Visitador')
class Visitadores extends Table {
  TextColumn get id => text()();

  /// SIRIUS-PER-XXXX. Llave estable hacia la nomina.
  TextColumn get idEmpleado => text().nullable()();

  TextColumn get nombre => text()();
  TextColumn get usuarioApp => text()();

  /// Cargo en la empresa, tal como esta en nomina. Distinto de [rol], que es
  /// el papel dentro de esta app.
  TextColumn get cargo => text().nullable()();

  TextColumn get email => text().nullable()();
  TextColumn get telefono => text().nullable()();
  TextColumn get rol => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  TextColumn get remoteId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Lo que permite entrar sin senal.
///
/// Guarda el hash bcrypt que devolvio el backend al verificar la contrasena
/// contra `Sirius Nomina Core`. Tres reglas que no son negociables:
///
///  1. Solo entra aqui quien YA acerto la contrasena en este telefono. Nunca
///     se descarga la nomina completa: un equipo perdido expone, como mucho,
///     los hashes de quienes lo usaron.
///  2. La contrasena en claro no se guarda jamas. Se compara contra el hash.
///  3. [validoHasta] obliga a volver a pasar por el backend cada tanto. Es lo
///     unico que puede enterarse de que alguien salio de la empresa: nomina no
///     tiene forma de avisarle a un telefono que esta en una vereda.
@DataClassName('CredencialLocal')
class CredencialesLocales extends Table {
  /// La cedula, normalizada a solo digitos. Es la llave porque es lo unico
  /// que el visitador tiene antes de autenticarse — y lo unico que se sabe de
  /// memoria estando en una finca.
  ///
  /// Se guarda normalizada para que entrar no dependa de si la tecleo con
  /// puntos: `1.234.567` y `1234567` tienen que ser la misma persona.
  TextColumn get cedula => text()();

  TextColumn get idEmpleado => text()();
  TextColumn get nombre => text()();
  TextColumn get email => text().nullable()();

  /// bcrypt, tal como lo escribio la app de nomina en Next.js.
  TextColumn get hashBcrypt => text()();

  /// Papel dentro de esta app: Visitador o Coordinador.
  TextColumn get rolApp => text().withDefault(const Constant('Visitador'))();
  TextColumn get nivelAcceso => text().nullable()();
  IntColumn get ordenNivel => integer().withDefault(const Constant(99))();

  DateTimeColumn get ultimoLoginOnline => dateTime()();

  /// Despues de esta fecha el login offline se rechaza y hay que buscar senal.
  DateTimeColumn get validoHasta => dateTime()();

  @override
  Set<Column> get primaryKey => {cedula};
}

/// La sesion abierta en el telefono. Una fila como mucho ([unica] es siempre
/// 0), para que "quien esta usando la app" sea una pregunta con una respuesta.
@DataClassName('Sesion')
class Sesiones extends Table {
  IntColumn get unica => integer().withDefault(const Constant(0))();
  TextColumn get cedula => text().references(CredencialesLocales, #cedula)();
  DateTimeColumn get abierta => dateTime()();

  /// Si el ultimo login fue offline. Se muestra en la app: el visitador tiene
  /// derecho a saber que su sesion se valido contra una copia local.
  BoolColumn get offline => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {unica};
}

/// El informe que se le entrega al agricultor.
///
/// Se guarda local antes de subirlo: se genera en la finca, y si dependiera de
/// que la subida funcione, cerrar la app sin señal lo perderia. Va a Airtable
/// por la misma cola que el audio y las fotos.
@DataClassName('Informe')
class Informes extends Table {
  TextColumn get id => text()();
  TextColumn get visitaId => text().references(Visitas, #id)();

  TextColumn get titulo => text()();
  TextColumn get tipo =>
      text().withDefault(const Constant('Resumen para el agricultor'))();

  /// Markdown. Se guarda el texto y no un PDF: desde aqui se regenera el
  /// documento sin volver a pagarle al modelo.
  TextColumn get contenido => text()();

  /// Sube en cada regeneracion. El anterior no se borra: si el visitador
  /// regenera y el nuevo sale peor, el que ya le mostro al productor sigue ahi.
  IntColumn get version => integer().withDefault(const Constant(1))();

  DateTimeColumn get generadoEn => dateTime()();
  TextColumn get modelo => text().nullable()();

  BoolColumn get entregado => boolean().withDefault(const Constant(false))();
  TextColumn get medioEntrega => text().nullable()();

  /// El PDF armado, en disco. Se guarda el archivo y no solo el markdown
  /// porque es el documento que el productor tiene en la mano: regenerarlo
  /// meses despues con otra version del renderizador daria otro papel, y el
  /// que respalda lo acordado es este.
  TextColumn get pdfPath => text().nullable()();

  /// URL del PDF en el bucket. Nula hasta que la cola lo sube: el PDF va por
  /// su propio item y puede quedar pendiente cuando la visita ya subio.
  TextColumn get enlacePdf => text().nullable()();

  TextColumn get remoteId => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// La persona. Permanente: la visita es el evento, el agricultor sigue ahi
/// visita tras visita.
///
/// La visita lo crea con el nombre y nada mas, porque al llegar a una finca lo
/// unico que se sabe es a quien se viene a ver. El resto se completa desde el
/// modulo «El agricultor» de la visita, y se completa una sola vez en la vida
/// del productor: la segunda visita ya lo encuentra con ficha.
///
/// [documento] no es un campo mas: es la LLAVE con la que el backend decide si
/// este agricultor ya existe en Airtable. Sin el, el upsert cae al nombre, y
/// dos personas que se llaman igual en la misma vereda terminan con las fincas
/// mezcladas.
@DataClassName('Productor')
class Productores extends Table {
  TextColumn get id => text()();
  TextColumn get nombreCompleto => text()();
  TextColumn get documento => text().nullable()();

  /// CC | CE | TI | NIT | Pasaporte | Sin documento. Texto y no enum porque
  /// son las opciones del select de Airtable y viajan tal cual.
  TextColumn get tipoDocumento => text().nullable()();

  TextColumn get telefono => text().nullable()();
  TextColumn get telefonoAlterno => text().nullable()();

  TextColumn get genero => text().nullable()();
  DateTimeColumn get fechaNacimiento => dateTime().nullable()();
  TextColumn get nivelEducativo => text().nullable()();
  IntColumn get aniosExperiencia => integer().nullable()();
  IntColumn get personasHogar => integer().nullable()();

  /// Vacio significa que no pertenece a ninguna: el backend deriva de aqui la
  /// casilla `Pertenece a organizacion`, para no pedir dos veces lo mismo.
  TextColumn get organizacion => text().nullable()();

  TextColumn get notas => text().nullable()();

  /// La foto de perfil, en disco. Se guarda dentro de la carpeta de la visita
  /// donde se tomo: si esa visita se elimina por revocacion, la foto de la
  /// persona se va con el prefijo, que es exactamente lo que pidio.
  TextColumn get fotoPath => text().nullable()();

  /// URL de la foto en el bucket. Nula hasta que la cola la sube; es lo que
  /// Airtable usa para traerse el adjunto de `Productores.Foto`.
  TextColumn get enlaceFoto => text().nullable()();

  /// Miniatura de la foto que ya esta en Airtable, para reconocer al
  /// agricultor en el directorio antes de crearlo de nuevo.
  ///
  /// Es de Airtable y Airtable la rota cada pocas horas, asi que se muestra
  /// mientras sirva y su ausencia no significa nada: la foto de verdad es
  /// [fotoPath] en el telefono y [enlaceFoto] en el bucket.
  TextColumn get fotoRemota => text().nullable()();

  /// Autorizacion de tratamiento de datos (Ley 1581/2012). Va aqui y no solo
  /// en la visita porque la autorizacion es DE LA PERSONA: el permiso de
  /// grabar y de fotografiar se pide en cada visita, pero que sus datos se
  /// puedan tratar se autoriza una vez y queda con ella.
  BoolColumn get consentimientoDatos =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get fechaConsentimiento => dateTime().nullable()();

  /// Cuando alguien completo la ficha. Null = solo tiene el nombre con el que
  /// nacio, y el modulo de la visita lo va a decir.
  DateTimeColumn get datosCompletadosEn => dateTime().nullable()();

  /// Consecutivo BU-0001. Lo asigna el BACKEND al sincronizar, no la app:
  /// dos telefonos offline generarian el mismo numero.
  TextColumn get codigoProductor => text().nullable()();
  TextColumn get remoteId => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Finca')
class Fincas extends Table {
  TextColumn get id => text()();
  TextColumn get productorLocalId => text().references(Productores, #id)();
  TextColumn get nombre => text()();
  TextColumn get veredaLocalId => text().nullable().references(Veredas, #id)();
  RealColumn get latitud => real().nullable()();
  RealColumn get longitud => real().nullable()();
  RealColumn get areaTotalHa => real().nullable()();
  TextColumn get remoteId => text().nullable()();
  BoolColumn get sincronizada => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Visita')
class Visitas extends Table {
  /// UUID v4 del dispositivo. Es tambien `Visitas.Codigo de visita` en Airtable.
  TextColumn get id => text()();

  DateTimeColumn get inicio => dateTime()();
  DateTimeColumn get fin => dateTime().nullable()();

  TextColumn get visitadorLocalId =>
      text().nullable().references(Visitadores, #id)();
  TextColumn get productorLocalId =>
      text().nullable().references(Productores, #id)();
  TextColumn get fincaLocalId => text().nullable().references(Fincas, #id)();
  TextColumn get veredaLocalId => text().nullable().references(Veredas, #id)();

  TextColumn get tipoVisita => text().nullable()();
  RealColumn get latitud => real().nullable()();
  RealColumn get longitud => real().nullable()();
  RealColumn get precisionGps => real().nullable()();

  TextColumn get estado => text().withDefault(const Constant('En curso'))();

  // --- Consentimiento (Ley 1581/2012). Se piden en CADA visita. ---
  /// El boton de grabar esta deshabilitado mientras esto sea false.
  BoolColumn get consienteAudio =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get consienteFotos =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get consienteUsoDatos =>
      boolean().withDefault(const Constant(false))();

  /// Segundo del audio donde consta verbalmente. Prueba auditable.
  IntColumn get segundoConsentimiento => integer().nullable()();

  /// El productor revoco. Al sincronizar, el backend borra audio, fotos y hallazgos.
  BoolColumn get marcadaParaEliminacion =>
      boolean().withDefault(const Constant(false))();

  TextColumn get objetivo => text().nullable()();
  TextColumn get observaciones => text().nullable()();
  TextColumn get resumen => text().nullable()();
  TextColumn get temasPendientes => text().nullable()();
  TextColumn get notasPruebaCampo => text().nullable()();

  /// Recalculada localmente en cada cambio de hallazgos. El backend la recalcula
  /// al sincronizar y su valor manda: este es para el semaforo en campo.
  IntColumn get completitudPct => integer().withDefault(const Constant(0))();

  BoolColumn get sincronizada => boolean().withDefault(const Constant(false))();
  DateTimeColumn get sincronizadaEn => dateTime().nullable()();

  /// Esta visita se bajo de Airtable para consultarla, no se registro aqui.
  ///
  /// Es la marca que la vuelve intocable: no se graba, no se le toman fotos,
  /// no se edita y NUNCA se vuelve a encolar. Sin esto, espejar el historial
  /// de un agricultor podria terminar reescribiendo en Airtable una visita que
  /// hizo otro visitador con datos a medio bajar.
  ///
  /// Que sea una columna y no un estado es a proposito: `estado` viaja a
  /// Airtable, y el hecho de que una copia viva en este telefono no es asunto
  /// del registro central.
  BoolColumn get soloLectura => boolean().withDefault(const Constant(false))();

  /// Cuando se bajo el espejo. Es lo que permite decir en la pantalla «traido
  /// el martes» y saber si vale la pena volver a pedirlo.
  DateTimeColumn get descargadaEn => dateTime().nullable()();

  /// Cuando se bajo el DETALLE de este espejo: hallazgos, fotos, audio,
  /// informes.
  ///
  /// Null significa que del espejo solo esta la ficha, que es como llega desde
  /// el indice automatico. Esa diferencia es lo que permite que la lista se
  /// refresque sola sin bajar cientos de megas: doscientas fichas son unos KB,
  /// y las mismas con sus fotos no caben en un telefono de campo.
  ///
  /// Sin esta columna habria que adivinar si una visita sin hallazgos es una
  /// visita vacia o una que no se ha terminado de bajar — y son cosas
  /// distintas que se ven igual.
  DateTimeColumn get detalleEn => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Grabacion')
class Grabaciones extends Table {
  TextColumn get id => text()();
  TextColumn get visitaId => text().references(Visitas, #id)();

  /// Secuencia dentro de la visita. Una visita tiene varias grabaciones:
  /// pausas, llamadas entrantes, y el boton "Seguir grabando" del Dia 11.
  IntColumn get orden => integer()();

  /// Ruta en disco. El audio se escribe POR TRAMOS mientras se graba, no al
  /// final: si la app muere a los 28 minutos, se conservan los 28 minutos.
  TextColumn get archivoPath => text()();

  DateTimeColumn get inicio => dateTime()();
  IntColumn get duracionSeg => integer().withDefault(const Constant(0))();
  IntColumn get tamanoBytes => integer().withDefault(const Constant(0))();

  /// URL en el bucket. Fuente de verdad del audio; el adjunto de Airtable no.
  TextColumn get enlaceAudio => text().nullable()();

  TextColumn get transcripcion => text().nullable()();

  /// Segmentos con segundo de inicio y hablante. Sin esto no hay citas, y sin
  /// citas no hay procedencia.
  TextColumn get transcripcionMarcas => text().nullable()();
  TextColumn get motorTranscripcion => text().nullable()();
  TextColumn get estado => text().withDefault(const Constant('Grabada'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Evidencia')
class Evidencias extends Table {
  TextColumn get id => text()();
  TextColumn get visitaId => text().references(Visitas, #id)();
  TextColumn get tipo => text().nullable()();
  TextColumn get archivoPath => text()();
  DateTimeColumn get tomadaEn => dateTime()();
  RealColumn get latitud => real().nullable()();
  RealColumn get longitud => real().nullable()();

  /// Segundo de la grabacion en curso cuando se tomo la foto. Permite volver a
  /// lo que se estaba hablando mientras se fotografiaba.
  IntColumn get segundoAudio => integer().nullable()();

  TextColumn get descripcionVisitador => text().nullable()();
  TextColumn get descripcionIa => text().nullable()();
  TextColumn get textoOcr => text().nullable()();
  TextColumn get enlaceArchivo => text().nullable()();
  TextColumn get estadoValidacion =>
      text().withDefault(const Constant('Sin revisar'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// El "sobre de dato": cada valor que el modelo extrajo, con su procedencia.
@DataClassName('Hallazgo')
class Hallazgos extends Table {
  TextColumn get id => text()();
  TextColumn get visitaId => text().references(Visitas, #id)();

  /// Clave tecnica del catalogo. No es texto libre: si el modelo devuelve una
  /// clave que no esta en el catalogo, el hallazgo se rechaza y va a
  /// `Visitas.temasPendientes`.
  TextColumn get claveTecnica => text().references(CatalogoCampos, #claveTecnica)();

  /// A cual de los tres cultivos se refiere.
  TextColumn get entidadDestino =>
      text().map(const EntidadDestinoConverter()).nullable()();

  /// Instancia local dentro de la visita: cultivo_1, cultivo_2. La asigna el
  /// modelo; el backend la resuelve a un Lote real al sincronizar.
  TextColumn get entidadLocalId => text().nullable()();

  TextColumn get valorTexto => text().nullable()();
  RealColumn get valorNumerico => real().nullable()();
  TextColumn get unidad => text().nullable()();

  TextColumn get fuente => text()
      .map(const FuenteHallazgoConverter())
      .withDefault(const Constant('Audio'))();

  /// Fragmento textual que respalda el dato. Sin esto, certeza baja a Pendiente.
  TextColumn get citaTextual => text().nullable()();
  IntColumn get segundoAudio => integer().nullable()();

  /// Quien lo dijo. hablante = visitador implica que NUNCA es Confirmado.
  TextColumn get hablante => text().map(const HablanteConverter()).nullable()();

  TextColumn get certeza => text()
      .map(const CertezaConverter())
      .withDefault(const Constant('Pendiente'))();

  /// Obligatorio cuando certeza = Inferido. Sin el, baja a Pendiente.
  TextColumn get razonamiento => text().nullable()();

  RealColumn get confianza => real().nullable()();

  TextColumn get estado => text()
      .map(const EstadoHallazgoConverter())
      .withDefault(const Constant('Propuesto por IA'))();

  /// Lo que el visitador dejo como verdad final. El valor original NUNCA se
  /// borra: sin los dos no se puede medir la precision del modelo en el piloto.
  TextColumn get valorCorregido => text().nullable()();
  TextColumn get validadoPorLocalId =>
      text().nullable().references(Visitadores, #id)();
  DateTimeColumn get validadoEn => dateTime().nullable()();

  DateTimeColumn get creadoEn => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// El contorno de un lote o el recorrido por el cultivo, capturado a pie.
///
/// Existe porque el area de la finca dicha en la conversacion («seran unas
/// diez hectareas») no sirve para calcular una dosis ni para comparar dos
/// visitas. Caminar el lindero si.
///
/// Lo que NO hace: decidir por el visitador. El tipo de figura, cada cuanto se
/// pone un punto, con que precision minima se acepta y cuando se cierra el
/// anillo son todos suyos y viven en esta fila — no son constantes del codigo.
/// Un lote de cafe en ladera y un lindero de potrero no se capturan igual.
@DataClassName('Trazado')
class Trazados extends Table {
  TextColumn get id => text()();
  TextColumn get visitaId => text().references(Visitas, #id)();

  /// Como lo llama el visitador: «Lote de arriba», «lindero con el vecino».
  TextColumn get nombre => text()();

  TextColumn get tipo =>
      text().map(const TipoTrazadoConverter()).withDefault(const Constant('Poligono'))();

  TextColumn get modoCaptura =>
      text().map(const ModoCapturaConverter()).withDefault(const Constant('Manual'))();

  /// Que hay sembrado ahi. Texto libre a proposito: el cultivo tambien sale de
  /// la conversacion, y obligar a elegir de una lista en el potrero es como
  /// volver a la encuesta.
  TextColumn get etiqueta => text().nullable()();
  TextColumn get notas => text().nullable()();

  /// Cada cuantos segundos se pone un punto en modo automatico. null o 0
  /// significa que este trazado no captura solo.
  IntColumn get intervaloSeg => integer().nullable()();

  /// Si el punto nuevo esta a menos de esto del anterior, no se guarda. Es lo
  /// que evita que estar parado hablando dos minutos deje cuarenta puntos
  /// encimados que le inventan forma al lote.
  RealColumn get distanciaMinM => real().nullable()();

  /// Se rechaza el punto cuya precision reportada sea peor que esto. Un punto
  /// con 60 m de error mueve un lindero mas de lo que mide el lote.
  RealColumn get precisionMaxM => real().nullable()();

  /// El anillo se cierra. Lo decide el visitador: mientras sea false, el
  /// trazado sale al KML como linea, porque un poligono que nadie cerro no es
  /// un lote — es un recorrido a medias.
  BoolColumn get cerrado => boolean().withDefault(const Constant(true))();

  /// Recalculadas en cada cambio de puntos. Se persisten para que la lista de
  /// trazados no tenga que recorrer todos los puntos de todos los lotes para
  /// mostrar un area.
  RealColumn get areaM2 => real().nullable()();
  RealColumn get perimetroM => real().nullable()();

  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();

  TextColumn get remoteId => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Un vertice del trazado, con la huella de como se capturo.
///
/// [precisionM] y [automatico] no son adorno: son lo que permite, tres meses
/// despues, decidir si un lindero raro fue un error del visitador o un salto
/// del GPS bajo los arboles. Un punto sin esa huella no se puede auditar, y un
/// area que nadie puede auditar no se puede usar para nada serio.
@DataClassName('PuntoTrazado')
class PuntosTrazado extends Table {
  TextColumn get id => text()();
  TextColumn get trazadoId => text().references(Trazados, #id)();

  /// Posicion en el anillo. El orden ES la geometria: dos puntos intercambiados
  /// convierten un lote en un ocho.
  IntColumn get orden => integer()();

  RealColumn get latitud => real()();
  RealColumn get longitud => real()();
  RealColumn get altitud => real().nullable()();

  /// Radio de error que reporto el GPS, en metros.
  RealColumn get precisionM => real().nullable()();

  DateTimeColumn get capturadoEn => dateTime()();

  /// false = lo marco el visitador con el boton. true = lo puso el reloj.
  BoolColumn get automatico => boolean().withDefault(const Constant(false))();

  TextColumn get nota => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cola de sincronizacion. Un item por unidad de trabajo, con reintento propio:
/// que falle la subida de una foto no puede bloquear la visita entera.
@DataClassName('SyncItem')
class SyncQueue extends Table {
  TextColumn get id => text()();

  /// visita | grabacion | evidencia | hallazgos | productor | finca
  TextColumn get entidad => text()();
  TextColumn get entidadId => text()();

  /// upsert | upload_audio | upload_foto | upload_informe
  TextColumn get operacion => text()();

  TextColumn get payload => text().nullable()();
  TextColumn get archivoPath => text().nullable()();

  TextColumn get estado => text()
      .map(const EstadoSyncConverter())
      .withDefault(const Constant('Pendiente'))();

  IntColumn get intentos => integer().withDefault(const Constant(0))();

  /// Retroceso exponencial. La cola solo toma items cuyo proximo intento ya paso.
  DateTimeColumn get proximoIntentoEn => dateTime()();

  /// Subida por partes de 512 KB. Permite retomar donde quedo si se cae la red
  /// a la mitad de un audio de 7 MB, sin volver a subir lo ya subido.
  IntColumn get bytesSubidos => integer().withDefault(const Constant(0))();
  IntColumn get bytesTotales => integer().withDefault(const Constant(0))();

  /// Se muestra tal cual en la pantalla de estado. El visitador merece saber
  /// por que fallo, no un spinner indefinido.
  TextColumn get ultimoError => text().nullable()();

  /// Menor primero. El audio va antes que las fotos: es lo irrecuperable.
  IntColumn get prioridad => integer().withDefault(const Constant(100))();

  DateTimeColumn get creadoEn => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
