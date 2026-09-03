import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El informe que se le entrega al agricultor.
///
/// Lo que se protege: que el contexto que se le manda al modelo lleve nombres
/// legibles y no claves tecnicas, que regenerar no borre el que ya se le
/// mostro al productor, y que el informe viaje en la cola offline.
void main() {
  late AppDatabase db;
  late VisitaRepository repo;
  const visitaId = 'v-informe-1';

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

  Future<void> conHallazgo({Certeza certeza = Certeza.confirmado}) =>
      db.insertarHallazgo(
        HallazgosCompanion.insert(
          id: 'h-1',
          visitaId: visitaId,
          claveTecnica: 'fuente_agua',
          valorTexto: const Value('Pozo'),
          // Con cita: sin ella, la regla dura baja cualquier certeza a
          // Pendiente y el test estaria midiendo esa regla, no esta.
          citaTextual: const Value('Tengo tres pozos.'),
          certeza: Value(certeza),
          creadoEn: DateTime(2026, 9, 2, 8, 15),
        ),
      );

  group('el contexto que recibe el modelo', () {
    test('traduce la clave tecnica al nombre legible y su modulo', () async {
      // El informe lo lee el productor, no un desarrollador: si le llega
      // `fuente_agua` al modelo, tiene chance de escribirlo tal cual.
      await conHallazgo();

      final ctx = await repo.contextoInforme(visitaId);
      final h = (ctx['hallazgos'] as List).single as Map;

      expect(h['campo'], 'Fuente de agua');
      expect(h['modulo'], 'Agua');
      expect(h['clave_tecnica'], 'fuente_agua');
    });

    test('la certeza viaja como texto, no como enum de Dart', () async {
      // Se serializa a JSON: un enum de Dart no sobrevive el jsonEncode.
      await conHallazgo(certeza: Certeza.estimado);

      final ctx = await repo.contextoInforme(visitaId);
      expect(((ctx['hallazgos'] as List).single as Map)['certeza'], 'Estimado');
    });

    test('sin transcripcion el campo no se manda, no va vacio', () async {
      await conHallazgo();

      final ctx = await repo.contextoInforme(visitaId);
      // El backend distingue "no hay grabacion" de "la grabacion vino vacia".
      expect(ctx.containsKey('transcripcion'), isFalse);
    });
  });

  group('versionado', () {
    test('el primer informe es la version 1', () async {
      final i = await repo.guardarInforme(
        visitaId: visitaId,
        titulo: 'Informe La Soledad',
        contenido: '# Informe',
        tipo: 'Resumen para el agricultor',
      );

      expect(i.version, 1);
      expect(i.entregado, isFalse);
    });

    test('regenerar NO borra el que ya se le mostro al productor', () async {
      await repo.guardarInforme(
        visitaId: visitaId,
        titulo: 'Informe v1',
        contenido: '# Primero',
        tipo: 'Resumen para el agricultor',
      );
      final segundo = await repo.guardarInforme(
        visitaId: visitaId,
        titulo: 'Informe v2',
        contenido: '# Segundo',
        tipo: 'Resumen para el agricultor',
      );

      final todos = await repo.informesDeVisita(visitaId);
      expect(segundo.version, 2);
      expect(todos, hasLength(2));
      // El mas nuevo primero, y el viejo sigue ahi.
      expect(todos.first.contenido, '# Segundo');
      expect(todos.last.contenido, '# Primero');
    });

    test('entregar marca el informe, no la visita', () async {
      final i = await repo.guardarInforme(
        visitaId: visitaId,
        titulo: 'Informe',
        contenido: '# Informe',
        tipo: 'Resumen para el agricultor',
      );

      await repo.marcarInformeEntregado(i.id, medio: 'WhatsApp');

      final guardado = (await repo.informesDeVisita(visitaId)).single;
      expect(guardado.entregado, isTrue);
      expect(guardado.medioEntrega, 'WhatsApp');
    });
  });

  group('el informe viaja por la cola offline', () {
    test('generarlo encola la visita', () async {
      await repo.guardarInforme(
        visitaId: visitaId,
        titulo: 'Informe',
        contenido: '# Informe',
        tipo: 'Resumen para el agricultor',
      );

      final cola = await db.select(db.syncQueue).get();
      expect(cola, isNotEmpty);
    });

    test('el payload lo lleva completo, no solo el titulo', () async {
      // Desde el markdown se regenera el PDF sin volver a pagarle al modelo.
      await repo.guardarInforme(
        visitaId: visitaId,
        titulo: 'Informe La Soledad',
        contenido: '# Informe de su visita\n\nUsted tiene tres pozos.',
        tipo: 'Resumen para el agricultor',
      );

      final payload = await repo.payloadDeVisita(visitaId);
      final informes = payload['informes'] as List;

      expect(informes, hasLength(1));
      final i = informes.single as Map;
      expect(i['tipo'], 'Resumen para el agricultor');
      expect(i['version'], 1);
      expect(i['contenido'], contains('tres pozos'));
      expect(i['entregado'], isFalse);
    });
  });
}
