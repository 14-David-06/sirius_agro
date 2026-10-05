import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';

/// La politica que acepta quien envia el registro. Una sola constante: el
/// texto del aviso, el enlace que se abre y lo que queda guardado en Airtable
/// tienen que ser la misma direccion.
const terminosAsistenciaUrl = 'https://www.siriusregenerative.co/privacypolicy';

/// Entidad de la cola para los registros de asistencia.
const entidadAsistencia = 'asistencia';

class AsistenciaRepository {
  AsistenciaRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<Asistencia>> observarAsistencias() =>
      (_db.select(_db.asistencias)..orderBy([
            (a) => OrderingTerm(
              expression: a.registradoEn,
              mode: OrderingMode.desc,
            ),
          ]))
          .watch();

  // ------------------------------------------------------------- eventos

  /// Los eventos, el mas reciente primero.
  Stream<List<EventoAsistencia>> observarEventos() =>
      (_db.select(_db.eventosAsistencia)..orderBy([
            (e) => OrderingTerm(expression: e.fecha, mode: OrderingMode.desc),
            (e) =>
                OrderingTerm(expression: e.creadoEn, mode: OrderingMode.desc),
          ]))
          .watch();

  Future<String> crearEvento({
    required String nombre,
    required DateTime fecha,
    DateTime? ahora,
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      throw ArgumentError('El evento necesita un nombre.');
    }
    final id = _uuid.v4();
    await _db
        .into(_db.eventosAsistencia)
        .insert(
          EventosAsistenciaCompanion.insert(
            id: id,
            nombre: limpio,
            fecha: DateTime(fecha.year, fecha.month, fecha.day),
            creadoEn: ahora ?? DateTime.now(),
          ),
        );
    return id;
  }

  /// Renombrar no toca los registros que ya subieron: en Airtable quedan con
  /// el nombre que tenia el evento cuando se tomaron.
  Future<void> renombrarEvento(String id, String nombre) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return;
    await (_db.update(_db.eventosAsistencia)..where((e) => e.id.equals(id)))
        .write(EventosAsistenciaCompanion(nombre: Value(limpio)));
  }

  Future<EventoAsistencia?> evento(String id) => (_db.select(
    _db.eventosAsistencia,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  // -------------------------------------------------------------- borrado

  /// Borra el registro de ESTE telefono: la fila, su nota, su firma y su item
  /// en la cola. En Airtable no se toca nada.
  ///
  /// Si todavia no habia subido, se pierde: es la persona que firmo y no va a
  /// llegar a ninguna parte. Por eso la pantalla lo advierte antes.
  Future<void> eliminarAsistencia(String id) async {
    final a = await (_db.select(
      _db.asistencias,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    if (a == null) return;
    await _db.transaction(() async {
      await (_db.delete(_db.syncQueue)..where(
            (q) => q.entidad.equals(entidadAsistencia) & q.entidadId.equals(id),
          ))
          .go();
      await (_db.delete(_db.asistencias)..where((x) => x.id.equals(id))).go();
    });
    // Los archivos despues de la fila: una fila sin archivos no puede subir,
    // pero unos archivos sin fila solo ocupan espacio.
    try {
      final carpeta = File(a.firmaPath).parent;
      if (p.basename(carpeta.path) == id && await carpeta.exists()) {
        await carpeta.delete(recursive: true);
      } else {
        for (final ruta in [a.firmaPath, a.notaVozPath]) {
          if (ruta != null && await File(ruta).exists()) {
            await File(ruta).delete();
          }
        }
      }
    } catch (_) {
      // Un archivo que no se pudo borrar no deshace el borrado.
    }
  }

  /// Borra el evento y todos sus registros del telefono. Con [eventoId] null
  /// borra los registros «Sin evento»: los de antes de los eventos y los de un
  /// evento que ya no esta.
  Future<void> eliminarEvento(String? eventoId) async {
    final eventos = {
      for (final e in await _db.select(_db.eventosAsistencia).get()) e.id,
    };
    final registros = (await _db.select(_db.asistencias).get()).where(
      (a) => eventoId == null
          ? a.eventoId == null || !eventos.contains(a.eventoId)
          : a.eventoId == eventoId,
    );
    for (final a in registros) {
      await eliminarAsistencia(a.id);
    }
    if (eventoId != null) {
      await (_db.delete(
        _db.eventosAsistencia,
      )..where((e) => e.id.equals(eventoId))).go();
    }
  }

  /// Los registros de [ids] que todavia no subieron a Airtable. Es lo que hay
  /// que advertir antes de borrar: lo demas ya esta a salvo alla.
  Future<int> sinSubir(Iterable<String> ids) async {
    final lista = ids.toList();
    if (lista.isEmpty) return 0;
    final filas =
        await (_db.select(_db.syncQueue)..where(
              (q) =>
                  q.entidad.equals(entidadAsistencia) &
                  q.entidadId.isIn(lista) &
                  q.estado.isNotValue(EstadoSync.completada.airtable),
            ))
            .get();
    return filas.length;
  }

  /// Guarda la nota y la firma en el telefono y deja el registro en la cola.
  ///
  /// Nada de esto necesita red ni procesa nada: los datos de la persona estan
  /// en la nota y los saca el backend al subir. Los archivos se copian a la
  /// carpeta del registro antes de escribir la fila: una fila que apunta a una
  /// nota que no esta en disco seria un registro que nunca puede subir.
  Future<String> registrar({
    required String notaVozTemporal,
    required int duracionNotaSeg,
    required Uint8List firmaPng,
    String? eventoId,
    double? latitud,
    double? longitud,
    String? visitadorIdEmpleado,
    String? visitadorNombre,
    DateTime? ahora,
    Directory? carpetaBase,
  }) async {
    final temporal = File(notaVozTemporal);
    if (!await temporal.exists()) {
      throw StateError('La nota de voz ya no esta en disco.');
    }

    final evento = eventoId == null ? null : await this.evento(eventoId);

    final id = _uuid.v4();
    final base = carpetaBase ?? await getApplicationDocumentsDirectory();
    final carpeta = Directory(p.join(base.path, 'asistencias', id));
    await carpeta.create(recursive: true);

    final firmaPath = p.join(carpeta.path, 'firma.png');
    await File(firmaPath).writeAsBytes(firmaPng, flush: true);

    final notaPath = p.join(carpeta.path, 'nota-voz.m4a');
    await temporal.copy(notaPath);
    try {
      await temporal.delete();
    } catch (_) {
      // Es un temporal: que quede no rompe nada.
    }

    await _db
        .into(_db.asistencias)
        .insert(
          AsistenciasCompanion.insert(
            id: id,
            registradoEn: ahora ?? DateTime.now(),
            eventoId: Value(evento?.id),
            evento: Value(evento?.nombre),
            // Enviar es aceptar: el boton solo existe debajo del aviso.
            aceptaTerminos: const Value(true),
            terminosUrl: const Value(terminosAsistenciaUrl),
            firmaPath: firmaPath,
            notaVozPath: Value(notaPath),
            duracionNotaSeg: Value(duracionNotaSeg),
            latitud: Value(latitud),
            longitud: Value(longitud),
            visitadorIdEmpleado: Value(visitadorIdEmpleado),
            visitadorNombre: Value(visitadorNombre),
          ),
        );

    await encolar(id);
    return id;
  }

  /// Id derivado del registro: volver a encolar reemplaza el item en vez de
  /// dejar dos subidas de la misma persona.
  Future<void> encolar(String asistenciaId) => _db.encolar(
    id: 'asistencia-$asistenciaId',
    entidad: entidadAsistencia,
    entidadId: asistenciaId,
    operacion: 'upsert_asistencia',
    // Despues de la visita (10) y antes del audio y las fotos: es poco
    // peso y es lo que el coordinador espera ver el mismo dia.
    prioridad: 20,
  );

  Future<Asistencia> asistencia(String id) =>
      (_db.select(_db.asistencias)..where((a) => a.id.equals(id))).getSingle();

  /// Lo que viaja en el campo `datos` del multipart: solo el contexto. Los
  /// datos de la persona van en el audio.
  Map<String, dynamic> payloadDe(Asistencia a) => {
    'codigo_registro': a.id,
    'registrado_en': a.registradoEn.toIso8601String(),
    'acepta_terminos': a.aceptaTerminos,
    'terminos_url': a.terminosUrl,
    'evento': a.evento,
    'duracion_nota_seg': a.duracionNotaSeg,
    'latitud': a.latitud,
    'longitud': a.longitud,
    'visitador_id_empleado': a.visitadorIdEmpleado,
    'visitador_nombre': a.visitadorNombre,
  };

  /// Guarda lo que el backend saco de la nota, para que la lista diga quien
  /// es cada registro.
  Future<void> marcarSincronizada(
    String id,
    Map<String, dynamic> resultado,
  ) async {
    final datos = resultado['datos'] as Map<String, dynamic>?;
    final nombreVereda = datos?['vereda'] as String?;
    final vereda = nombreVereda == null
        ? null
        : await (_db.select(_db.veredas)
                ..where((v) => v.vereda.equals(nombreVereda))
                ..limit(1))
              .getSingleOrNull();
    final cultivos = (datos?['cultivos'] as List?)?.cast<String>() ?? const [];
    final area = datos?['area_sembrada_ha'];

    await (_db.update(_db.asistencias)..where((a) => a.id.equals(id))).write(
      AsistenciasCompanion(
        remoteId: Value(resultado['record_id'] as String?),
        enlaceFirma: Value(resultado['enlace_firma'] as String?),
        enlaceNotaVoz: Value(resultado['enlace_nota_voz'] as String?),
        transcripcionNota: Value(resultado['transcripcion'] as String?),
        procesado: Value(resultado['procesado'] == true),
        nombreCompleto: Value(datos?['nombre_completo'] as String?),
        cedula: Value(datos?['cedula'] as String?),
        telefono: Value(datos?['telefono'] as String?),
        cultivos: Value(cultivos.join('\n')),
        veredaLocalId: Value(vereda?.id),
        quiereVisita: Value(datos?['quiere_visita'] == true),
        areaSembradaHa: Value(area is num ? area.toDouble() : null),
        sincronizado: const Value(true),
        sincronizadoEn: Value(DateTime.now()),
      ),
    );
  }

  /// Cuantos registros faltan por subir, con el ultimo error si lo hay.
  Stream<List<SyncItem>> observarPendientes() => _pendientes().watch();

  Future<List<SyncItem>> pendientes() => _pendientes().get();

  SimpleSelectStatement<$SyncQueueTable, SyncItem> _pendientes() =>
      _db.select(_db.syncQueue)..where(
        (q) =>
            q.entidad.equals(entidadAsistencia) &
            q.estado.isNotValue(EstadoSync.completada.airtable),
      );
}

/// Lo que el sincronizador necesita leer del disco para subir un registro.
Future<({Uint8List firma, Uint8List nota})> archivosDeAsistencia(
  Asistencia a,
) async {
  final firma = File(a.firmaPath);
  final notaPath = a.notaVozPath;
  final nota = notaPath == null ? null : File(notaPath);
  // Sin firma o sin nota el registro no vale, y reintentar no los va a traer
  // de vuelta. Se deja el motivo en la cola, que es lo que se ve.
  if (!await firma.exists()) {
    throw StateError('La firma ya no esta en disco: ${a.firmaPath}');
  }
  if (nota == null || !await nota.exists()) {
    throw StateError('La nota de voz ya no esta en disco: $notaPath');
  }
  return (firma: await firma.readAsBytes(), nota: await nota.readAsBytes());
}
