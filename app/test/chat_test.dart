import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El contexto que el chat de campo le manda al modelo.
///
/// Lo que se protege: que un Pendiente no viaje como si fuera un dato — el
/// asistente le responde al visitador y el visitador se lo repite al productor,
/// asi que un dato que nadie confirmo se convertiria en algo "que dijimos".
void main() {
  late AppDatabase db;
  late VisitaRepository repo;
  const visitaId = 'v-chat-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VisitaRepository(db);

    await db.into(db.catalogoCampos).insert(
          CatalogoCamposCompanion.insert(
            claveTecnica: 'fuente_agua',
            campo: 'Fuente de agua',
            modulo: 'Agua',
          ),
        );
    await db.into(db.visitas).insert(
          VisitasCompanion.insert(
            id: visitaId,
            inicio: DateTime(2026, 9, 2, 8),
            consienteAudio: const Value(true),
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> conHallazgo({
    String id = 'h-1',
    Certeza certeza = Certeza.confirmado,
  }) =>
      db.insertarHallazgo(
        HallazgosCompanion.insert(
          id: id,
          visitaId: visitaId,
          claveTecnica: 'fuente_agua',
          valorTexto: const Value('Pozo'),
          citaTextual: const Value('Tengo tres pozos.'),
          certeza: Value(certeza),
          creadoEn: DateTime(2026, 9, 2, 8, 15),
        ),
      );

  test('sin visitas el contexto va vacio', () async {
    await db.delete(db.visitas).go();
    expect(await repo.contextoChat(), isEmpty);
  });

  test('lleva el nombre legible del campo, no la clave tecnica', () async {
    await conHallazgo();

    final ctx = await repo.contextoChat();
    expect(ctx, contains('Fuente de agua'));
    expect(ctx, isNot(contains('fuente_agua')));
    expect(ctx, contains('Confirmado'));
  });

  test('un Pendiente no entra como dato', () async {
    await conHallazgo(certeza: Certeza.pendiente);

    final ctx = await repo.contextoChat();
    expect(ctx, contains('Sin datos registrados todavia'));
    expect(ctx, isNot(contains('Pozo')));
  });

  test('el contexto se acota: no crece con cada dato de la finca', () async {
    for (var i = 0; i < 20; i++) {
      await conHallazgo(id: 'h-$i');
    }

    final ctx = await repo.contextoChat(maxDatos: 5);
    expect('Pozo'.allMatches(ctx).length, 5);
  });

  test('cada visita es un bloque y solo entran las mas recientes', () async {
    await conHallazgo();
    for (var i = 0; i < 3; i++) {
      await db.into(db.visitas).insert(
            VisitasCompanion.insert(
              id: 'v-extra-$i',
              inicio: DateTime(2026, 9, 3, 8 + i),
              consienteAudio: const Value(true),
            ),
          );
    }

    final ctx = await repo.contextoChat(maxVisitas: 2);
    expect('% del cuestionario'.allMatches(ctx).length, 2);
    // Las dos ultimas son de septiembre 3: la del hallazgo quedo fuera.
    expect(ctx, isNot(contains('Pozo')));
  });
}
