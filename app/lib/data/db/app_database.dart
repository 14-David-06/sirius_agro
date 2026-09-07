import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/geo.dart';
import 'enums.dart';
import 'tables.dart';

export 'enums.dart';
export 'tables.dart';

part 'app_database.g.dart';

/// Resultado de aplicar las reglas de procedencia a un hallazgo.
class ProcedenciaResuelta {
  const ProcedenciaResuelta(this.certeza, this.motivo);

  final Certeza certeza;

  /// Por que quedo asi. Null si el modelo propuso algo valido y se respeto.
  /// Se muestra en la pantalla de validacion para que el visitador entienda
  /// por que un dato que "se dijo" aparece como pendiente.
  final String? motivo;
}

/// Las tres reglas duras del spec, en un solo lugar y sin estado.
///
/// Viven aqui y no en el prompt a proposito: una regla que el modelo puede
/// desobedecer no es una regla. El backend aplica exactamente estas mismas al
/// escribir en Airtable; si las dos implementaciones se separan, la pantalla
/// de validacion le miente al visitador.
///
/// El orden importa: [Certeza.noLegible] se respeta por encima de todo porque
/// significa "el dato existe y no se puede leer", que no es lo mismo que
/// "no se menciono" y exige mostrar la foto recortada.
ProcedenciaResuelta resolverProcedencia({
  required Certeza propuesta,
  required Hablante? hablante,
  required String? citaTextual,
  required String? razonamiento,
  required FuenteHallazgo fuente,
}) {
  // Un campo de etiqueta ilegible no pasa por las reglas de la conversacion:
  // no tiene cita porque nadie lo dijo, lo leyo (mal) la camara.
  if (propuesta == Certeza.noLegible) {
    return const ProcedenciaResuelta(Certeza.noLegible, null);
  }

  // Regla 1: el visitador sugiriendo un dato no es el agricultor afirmandolo.
  if (hablante == Hablante.visitador && propuesta == Certeza.confirmado) {
    return const ProcedenciaResuelta(
      Certeza.estimado,
      'Lo dijo el visitador, no el agricultor.',
    );
  }

  // Regla 2: sin cita no hay procedencia, por alta que sea la confianza.
  // Los datos de GPS y los capturados a mano son la excepcion: su fuente no es
  // la conversacion, asi que no puede haber una frase que los respalde.
  final sinCita = citaTextual == null || citaTextual.trim().isEmpty;
  final exigeCita =
      fuente != FuenteHallazgo.gps && fuente != FuenteHallazgo.manual;
  if (sinCita && exigeCita) {
    return const ProcedenciaResuelta(
      Certeza.pendiente,
      'No hay cita textual que respalde el dato.',
    );
  }

  // Regla 3: inferir sin decir de que se infirio es adivinar.
  if (propuesta == Certeza.inferido &&
      (razonamiento == null || razonamiento.trim().isEmpty)) {
    return const ProcedenciaResuelta(
      Certeza.pendiente,
      'Inferido sin razonamiento.',
    );
  }

  return ProcedenciaResuelta(propuesta, null);
}

@DriftDatabase(
  tables: [
    Ajustes,
    CatalogoCampos,
    Veredas,
    Visitadores,
    CredencialesLocales,
    Sesiones,
    Productores,
    Fincas,
    Visitas,
    Grabaciones,
    Evidencias,
    Hallazgos,
    Informes,
    Trazados,
    PuntosTrazado,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sirius_agro'));

  /// Para pruebas: `AppDatabase.forTesting(NativeDatabase.memory())`.
  AppDatabase.forTesting(super.executor) : super();

  /// Subir esto es OBLIGATORIO cada vez que cambia una tabla.
  ///
  /// Drift solo crea el esquema la primera vez que abre el archivo. Si el
  /// numero no cambia, una app actualizada abre una base vieja tal cual y
  /// falla al primer INSERT con una columna que no existe — que es
  /// exactamente lo que paso en el teléfono del piloto.
  ///
  /// v2: tabla `Ajustes`, `CatalogoCampos.noSugerir` y las cuatro columnas de
  ///     nomina en `Visitadores` (idEmpleado, cargo, email, telefono).
  /// v6: `Trazados` y `PuntosTrazado` — los poligonos de lote y los recorridos
  ///     que se caminan en la finca.
  /// v7: la ficha del agricultor en `Productores` (documento y tipo, telefonos,
  ///     genero, nacimiento, educacion, experiencia, hogar, organizacion,
  ///     notas), su foto de perfil y el consentimiento de datos de la persona.
  /// v8: `Productores.fotoRemota` — la miniatura de Airtable con la que el
  ///     visitador reconoce al agricultor en el directorio.
  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, desde, hasta) async {
          // Se agregan solo las columnas que falten, en vez de asumir en que
          // version exacta quedo el dispositivo. Durante el desarrollo se
          // instalaron varios APK sin subir schemaVersion, asi que hay
          // telefonos en estados intermedios que ningun numero describe.
          //
          // Todas las columnas nuevas son nullable o tienen default, asi que
          // agregarlas no puede fallar por datos existentes.
          await _asegurarTabla(m, ajustes);
          // v4: el login pasó de correo/ID a cedula, asi que cambio la
          // llave de las dos tablas del login. Se recrean en vez de migrarse:
          // lo unico que guardan es el hash cacheado y que sesion esta
          // abierta, y eso se recupera con un login con señal.
          //
          // Esto NO se haria con visitas, grabaciones ni evidencias: ahi vive
          // lo que no se puede volver a capturar.
          if (desde < 4) {
            await m.deleteTable(sesiones.actualTableName);
            await m.deleteTable(credencialesLocales.actualTableName);
          }
          await _asegurarTabla(m, credencialesLocales);
          await _asegurarTabla(m, sesiones);
          // v5: el informe que se le entrega al agricultor.
          await _asegurarTabla(m, informes);
          // v6: los trazados. Van en ese orden: `PuntosTrazado` tiene una
          // clave foranea hacia `Trazados` y SQLite no crea la tabla hija
          // antes que la madre.
          await _asegurarTabla(m, trazados);
          await _asegurarTabla(m, puntosTrazado);
          await _asegurarColumna(m, catalogoCampos, catalogoCampos.noSugerir);
          await _asegurarColumna(m, visitadores, visitadores.idEmpleado);
          await _asegurarColumna(m, visitadores, visitadores.cargo);
          await _asegurarColumna(m, visitadores, visitadores.email);
          await _asegurarColumna(m, visitadores, visitadores.telefono);
          // v6: el PDF del informe se guarda en disco y se sube al bucket.
          // Antes vivia solo en memoria mientras la pantalla estaba abierta,
          // asi que el documento que se le entrego al productor no quedaba en
          // ninguna parte.
          await _asegurarColumna(m, informes, informes.pdfPath);
          await _asegurarColumna(m, informes, informes.enlacePdf);
          // v7: la ficha del agricultor. Hasta la v6 el productor era un
          // nombre y nada mas, asi que el `documento` —que es la llave con la
          // que el backend decide si ya existe— no tenia donde vivir en el
          // telefono.
          for (final columna in [
            productores.tipoDocumento,
            productores.telefonoAlterno,
            productores.genero,
            productores.fechaNacimiento,
            productores.nivelEducativo,
            productores.aniosExperiencia,
            productores.personasHogar,
            productores.organizacion,
            productores.notas,
            productores.fotoPath,
            productores.enlaceFoto,
            productores.consentimientoDatos,
            productores.fechaConsentimiento,
            productores.datosCompletadosEn,
            // v8: la cara con la que se reconoce al agricultor en el
            // directorio, para no volver a crearlo con otro nombre.
            productores.fotoRemota,
          ]) {
            await _asegurarColumna(m, productores, columna);
          }
        },
        beforeOpen: (details) async {
          // Sin esto SQLite ignora las claves foraneas y se pueden quedar
          // hallazgos huerfanos apuntando a una visita borrada.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Agrega la columna solo si no esta. Idempotente a proposito: correr la
  /// migracion dos veces no puede romper nada.
  Future<void> _asegurarColumna(
    Migrator m,
    TableInfo<Table, dynamic> tabla,
    GeneratedColumn columna,
  ) async {
    final existentes = await columnasDe(tabla.actualTableName);
    if (existentes.contains(columna.name)) return;
    await m.addColumn(tabla, columna);
  }

  Future<void> _asegurarTabla(Migrator m, TableInfo<Table, dynamic> tabla) async {
    final existe = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable(tabla.actualTableName)],
    ).getSingleOrNull();
    if (existe != null) return;
    await m.createTable(tabla);
  }

  // ----------------------------------------------------------------- ajustes

  Future<String?> ajuste(String clave) async {
    final fila = await (select(ajustes)..where((a) => a.clave.equals(clave)))
        .getSingleOrNull();
    return fila?.valor;
  }

  Future<void> guardarAjuste(String clave, String valor) => into(ajustes)
      .insert(AjustesCompanion.insert(clave: clave, valor: valor),
          mode: InsertMode.insertOrReplace);

  /// Las columnas que existen HOY en el archivo, no las que el codigo cree.
  Future<Set<String>> columnasDe(String tabla) async {
    final filas =
        await customSelect('PRAGMA table_info($tabla)').get();
    return filas.map((f) => f.read<String>('name')).toSet();
  }

  // ---------------------------------------------------------------- catalogo

  /// Las variables que se le piden al modelo en esta version.
  Future<List<CatalogoCampo>> camposActivos() =>
      (select(catalogoCampos)..where((c) => c.activo.equals(true))).get();

  /// Los obligatorios que definen la completitud. Hoy son 27.
  /// El numero NO esta escrito en el codigo: sale del catalogo, para que
  /// activar un modulo en Airtable no exija recompilar la app.
  Future<List<CatalogoCampo>> obligatoriosActivos() =>
      (select(catalogoCampos)
            ..where((c) => c.activo.equals(true) & c.obligatorioMvp.equals(true))
            ..orderBy([
              (c) => OrderingTerm(expression: c.modulo),
              (c) => OrderingTerm(expression: c.campo),
            ]))
          .get();

  Future<void> guardarCatalogo(List<CatalogoCamposCompanion> filas) async {
    await batch((b) => b.insertAllOnConflictUpdate(catalogoCampos, filas));
  }

  // ---------------------------------------------------------------- faltantes

  /// Las claves obligatorias que esta visita ya resolvio.
  ///
  /// "Resuelto" es deliberadamente estricto: un hallazgo Pendiente o Descartado
  /// no cuenta, y uno No legible tampoco. Si contaran, la completitud diria 100%
  /// sobre datos que nadie puede usar.
  Future<Set<String>> clavesResueltas(String visitaId) async {
    final noResuelven = [
      Certeza.pendiente.airtable,
      Certeza.noLegible.airtable,
    ];
    final filas = await (selectOnly(hallazgos, distinct: true)
          ..addColumns([hallazgos.claveTecnica])
          ..where(
            hallazgos.visitaId.equals(visitaId) &
                hallazgos.certeza.isNotIn(noResuelven) &
                hallazgos.estado
                    .isNotValue(EstadoHallazgo.descartado.airtable),
          ))
        .get();

    return filas
        .map((f) => f.read(hallazgos.claveTecnica))
        .whereType<String>()
        .toSet();
  }

  /// Obligatorios que la conversacion todavia no resolvio, con su pregunta guia.
  ///
  /// El modelo NO decide esta lista: es una resta. Lo unico que hace el modelo
  /// (Dia 11) es redactar las preguntas, y las redacta con la `preguntaGuia`
  /// que ya viene aqui.
  Future<List<CatalogoCampo>> faltantes(String visitaId) async {
    final resueltas = await clavesResueltas(visitaId);
    final obligatorios = await obligatoriosActivos();
    return obligatorios
        .where((c) => !resueltas.contains(c.claveTecnica))
        .toList();
  }

  /// Los faltantes que SI se le pueden sugerir al visitador.
  ///
  /// Distinto de [faltantes]: `motivo_llegada` cuenta para la completitud pero
  /// no entra aqui. Preguntarle de frente a alguien por que le toco dejar su
  /// tierra, para cerrar un checklist, es exactamente lo que no se debe hacer.
  /// Ese dato se registra solo si el productor lo cuenta por su cuenta.
  ///
  /// Consecuencia asumida: la completitud puede quedarse por debajo de 100%
  /// sin que el visitador tenga forma de saber que le falta. Es el precio
  /// correcto — el checklist no manda sobre la conversacion.
  Future<List<CatalogoCampo>> faltantesSugeribles(String visitaId) async {
    final todos = await faltantes(visitaId);
    return todos.where((c) => !c.noSugerir).toList();
  }

  /// Completitud determinista: obligatorios resueltos / obligatorios activos.
  /// Devuelve 0 si el catalogo local esta vacio, nunca 100: una app sin catalogo
  /// no puede afirmar que la visita esta completa.
  Future<int> calcularCompletitud(String visitaId) async {
    final obligatorios = await obligatoriosActivos();
    if (obligatorios.isEmpty) return 0;

    final resueltas = await clavesResueltas(visitaId);
    final resueltos =
        obligatorios.where((c) => resueltas.contains(c.claveTecnica)).length;
    return ((resueltos / obligatorios.length) * 100).round();
  }

  /// Recalcula y persiste. Se llama despues de cada cambio en hallazgos.
  Future<int> refrescarCompletitud(String visitaId) async {
    final pct = await calcularCompletitud(visitaId);
    await (update(visitas)..where((v) => v.id.equals(visitaId)))
        .write(VisitasCompanion(completitudPct: Value(pct)));
    return pct;
  }

  // ---------------------------------------------------------------- hallazgos

  /// Inserta aplicando las reglas duras. Devuelve la certeza que quedo, que
  /// puede ser peor que la propuesta por el modelo.
  Future<Certeza> insertarHallazgo(HallazgosCompanion fila) async {
    final resuelta = resolverProcedencia(
      propuesta: fila.certeza.present ? fila.certeza.value : Certeza.pendiente,
      hablante: fila.hablante.present ? fila.hablante.value : null,
      citaTextual: fila.citaTextual.present ? fila.citaTextual.value : null,
      razonamiento: fila.razonamiento.present ? fila.razonamiento.value : null,
      fuente: fila.fuente.present ? fila.fuente.value : FuenteHallazgo.audio,
    );

    await into(hallazgos).insert(
      fila.copyWith(certeza: Value(resuelta.certeza)),
      mode: InsertMode.insertOrReplace,
    );
    return resuelta.certeza;
  }

  Future<List<Hallazgo>> hallazgosDeVisita(String visitaId) =>
      (select(hallazgos)
            ..where((h) => h.visitaId.equals(visitaId))
            ..orderBy([(h) => OrderingTerm(expression: h.claveTecnica)]))
          .get();

  /// Corrige un hallazgo sin perder lo que el modelo habia dicho.
  Future<void> corregirHallazgo({
    required String hallazgoId,
    required String valorCorregido,
    required String validadoPorLocalId,
  }) =>
      (update(hallazgos)..where((h) => h.id.equals(hallazgoId))).write(
        HallazgosCompanion(
          valorCorregido: Value(valorCorregido),
          estado: const Value(EstadoHallazgo.corregido),
          validadoPorLocalId: Value(validadoPorLocalId),
          validadoEn: Value(DateTime.now()),
        ),
      );

  // ---------------------------------------------------------------- trazados

  /// Los puntos de un trazado, en el orden en que se caminaron.
  ///
  /// El orden se pide explicito y no se confia en el de insercion: el
  /// visitador borra un punto malo del medio y los que quedan tienen que
  /// seguir describiendo la misma figura.
  Future<List<PuntoTrazado>> puntosDeTrazado(String trazadoId) =>
      (select(puntosTrazado)
            ..where((p) => p.trazadoId.equals(trazadoId))
            ..orderBy([(p) => OrderingTerm(expression: p.orden)]))
          .get();

  Stream<List<PuntoTrazado>> observarPuntos(String trazadoId) =>
      (select(puntosTrazado)
            ..where((p) => p.trazadoId.equals(trazadoId))
            ..orderBy([(p) => OrderingTerm(expression: p.orden)]))
          .watch();

  Future<List<Trazado>> trazadosDeVisita(String visitaId) =>
      (select(trazados)
            ..where((t) => t.visitaId.equals(visitaId))
            ..orderBy([(t) => OrderingTerm(expression: t.creadoEn)]))
          .get();

  Stream<List<Trazado>> observarTrazados(String visitaId) =>
      (select(trazados)
            ..where((t) => t.visitaId.equals(visitaId))
            ..orderBy([(t) => OrderingTerm(expression: t.creadoEn)]))
          .watch();

  /// Recalcula area y perimetro y los deja guardados. Devuelve los puntos, que
  /// es lo que el que llama casi siempre necesita despues.
  ///
  /// Se llama tras CADA cambio de puntos. Un area guardada que no corresponde
  /// a los puntos que tiene al lado es peor que no tener area: el visitador la
  /// lee en la finca y decide con ella.
  Future<List<PuntoTrazado>> refrescarGeometria(String trazadoId) async {
    final puntos = await puntosDeTrazado(trazadoId);
    final trazado = await (select(trazados)..where((t) => t.id.equals(trazadoId)))
        .getSingleOrNull();
    if (trazado == null) return puntos;

    final geos = [
      for (final p in puntos) PuntoGeo(p.latitud, p.longitud),
    ];
    // El area solo tiene sentido en un anillo cerrado. En una ruta se deja en
    // null en vez de en 0: null es «no aplica», 0 seria «mide cero».
    final esAnillo = trazado.tipo.esPoligono && trazado.cerrado;

    await (update(trazados)..where((t) => t.id.equals(trazadoId))).write(
      TrazadosCompanion(
        areaM2: Value(esAnillo && geos.length >= 3 ? areaM2(geos) : null),
        perimetroM: Value(longitudMetros(geos, cerrado: esAnillo)),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
    return puntos;
  }

  // -------------------------------------------------------------- sync queue

  Future<void> encolar({
    required String id,
    required String entidad,
    required String entidadId,
    required String operacion,
    String? payload,
    String? archivoPath,
    int bytesTotales = 0,
    int prioridad = 100,
  }) =>
      into(syncQueue).insert(
        SyncQueueCompanion.insert(
          id: id,
          entidad: entidad,
          entidadId: entidadId,
          operacion: operacion,
          payload: Value(payload),
          archivoPath: Value(archivoPath),
          bytesTotales: Value(bytesTotales),
          prioridad: Value(prioridad),
          proximoIntentoEn: DateTime.now(),
          creadoEn: DateTime.now(),
        ),
        mode: InsertMode.insertOrReplace,
      );

  /// Lo siguiente que toca subir: pendiente o fallido, con el reintento ya
  /// vencido, el audio antes que las fotos y lo mas viejo primero.
  Future<List<SyncItem>> proximosItems({int limite = 5}) =>
      (select(syncQueue)
            ..where(
              (q) =>
                  q.estado.isIn([
                    EstadoSync.pendiente.airtable,
                    EstadoSync.fallida.airtable,
                  ]) &
                  q.proximoIntentoEn.isSmallerOrEqualValue(DateTime.now()),
            )
            ..orderBy([
              (q) => OrderingTerm(expression: q.prioridad),
              (q) => OrderingTerm(expression: q.creadoEn),
            ])
            ..limit(limite))
          .get();

  /// Retroceso exponencial con techo de 1 hora: 2s, 4s, 8s... En campo la red
  /// aparece y desaparece, y reintentar cada segundo solo gasta bateria.
  static Duration esperaTrasFallo(int intentos) {
    final segundos = 1 << intentos.clamp(1, 12);
    const techo = Duration(hours: 1);
    final espera = Duration(seconds: segundos);
    return espera > techo ? techo : espera;
  }

  Future<void> marcarFallo(String itemId, String error) async {
    final item = await (select(syncQueue)..where((q) => q.id.equals(itemId)))
        .getSingleOrNull();
    if (item == null) return;

    final intentos = item.intentos + 1;
    await (update(syncQueue)..where((q) => q.id.equals(itemId))).write(
      SyncQueueCompanion(
        estado: const Value(EstadoSync.fallida),
        intentos: Value(intentos),
        ultimoError: Value(error),
        proximoIntentoEn: Value(DateTime.now().add(esperaTrasFallo(intentos))),
      ),
    );
  }

  /// Avance de una subida por partes, para poder retomar sin repetir bytes.
  Future<void> registrarAvance(String itemId, int bytesSubidos) =>
      (update(syncQueue)..where((q) => q.id.equals(itemId)))
          .write(SyncQueueCompanion(bytesSubidos: Value(bytesSubidos)));

  Future<void> marcarCompletado(String itemId) =>
      (update(syncQueue)..where((q) => q.id.equals(itemId))).write(
        SyncQueueCompanion(
          estado: const Value(EstadoSync.completada),
          ultimoError: const Value(null),
        ),
      );

  /// Lo que la pantalla de estado muestra: cuanto falta por subir, por visita.
  Future<List<SyncItem>> pendientesDeVisita(String visitaId) =>
      (select(syncQueue)
            ..where(
              (q) =>
                  q.entidadId.equals(visitaId) &
                  q.estado.isNotValue(EstadoSync.completada.airtable),
            ))
          .get();
}
