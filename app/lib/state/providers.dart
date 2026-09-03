import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../data/db/app_database.dart';
import '../data/exportador_visita.dart';
import '../data/semilla.dart';
import '../data/visita_repository.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repoProvider =
    Provider<VisitaRepository>((ref) => VisitaRepository(ref.watch(dbProvider)));

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

final exportadorProvider = Provider<ExportadorVisitas>(
  (ref) => ExportadorVisitas(ref.watch(dbProvider), ref.watch(repoProvider)),
);

/// Siembra veredas y catalogo desde los assets del APK. Es lo primero que
/// corre: sin esto la app no sabe que preguntar ni en que vereda esta.
final semillaProvider = FutureProvider<void>((ref) async {
  await Semilla(ref.watch(dbProvider), rootBundle).sembrarSiHaceFalta();
});

/// Las visitas del dispositivo, mas recientes primero. Es un stream: al
/// guardar una extraccion o cerrar una visita, la lista se refresca sola.
final visitasProvider = StreamProvider<List<Visita>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.visitas)
        ..orderBy([
          (v) => OrderingTerm(expression: v.inicio, mode: OrderingMode.desc),
        ]))
      .watch();
});

final visitaProvider = StreamProvider.family<Visita?, String>((ref, id) {
  final db = ref.watch(dbProvider);
  return (db.select(db.visitas)..where((v) => v.id.equals(id)))
      .watchSingleOrNull();
});

/// Los empleados activos, para el selector de quien hace la visita.
///
/// No hay tres visitadores fijos: nadie en la nomina tiene ese cargo, asi que
/// quien visita se elige al crear la visita.
final visitadoresProvider = FutureProvider<List<Visitador>>((ref) async {
  await ref.watch(semillaProvider.future);
  final db = ref.watch(dbProvider);
  return (db.select(db.visitadores)
        ..where((v) => v.activo.equals(true))
        ..orderBy([(v) => OrderingTerm(expression: v.nombre)]))
      .get();
});

final veredasProvider = FutureProvider<List<Vereda>>((ref) async {
  await ref.watch(semillaProvider.future);
  final db = ref.watch(dbProvider);
  return (db.select(db.veredas)
        ..orderBy([(v) => OrderingTerm(expression: v.vereda)]))
      .get();
});

/// Obligatorios que faltan y que SI se le pueden preguntar al agricultor.
/// `motivo_llegada` no entra aqui aunque cuente para la completitud.
final faltantesProvider =
    FutureProvider.family<List<CatalogoCampo>, String>((ref, visitaId) async {
  // Se reevalua cuando cambia la visita, que es lo que pasa al recalcular
  // la completitud despues de guardar hallazgos.
  ref.watch(visitaProvider(visitaId));
  return ref.watch(dbProvider).faltantesSugeribles(visitaId);
});

final hallazgosProvider =
    StreamProvider.family<List<Hallazgo>, String>((ref, visitaId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.hallazgos)
        ..where((h) => h.visitaId.equals(visitaId))
        ..orderBy([(h) => OrderingTerm(expression: h.claveTecnica)]))
      .watch();
});

final evidenciasProvider =
    StreamProvider.family<List<Evidencia>, String>((ref, visitaId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.evidencias)
        ..where((e) => e.visitaId.equals(visitaId))
        ..orderBy([(e) => OrderingTerm(expression: e.tomadaEn)]))
      .watch();
});

/// Lo que le queda por subir a una visita. Alimenta la pantalla de estado.
final pendientesSyncProvider =
    StreamProvider.family<List<SyncItem>, String>((ref, visitaId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.syncQueue)
        ..where((q) =>
            q.entidadId.equals(visitaId) &
            q.estado.isNotValue(EstadoSync.completada.airtable)))
      .watch();
});
