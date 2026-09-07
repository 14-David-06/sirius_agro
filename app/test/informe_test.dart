import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/services.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VisitaRepository repo;
  late Directory documentos;
  const visitaId = 'v-informe-1';

  // El PDF se guarda donde la app guarda el audio y las fotos, y eso lo
  // resuelve path_provider, que en un test no tiene plataforma detras. Se le
  // da una carpeta temporal para poder verificar que el archivo queda escrito
  // de verdad: que la fila diga `pdf_path` y en disco no haya nada es
  // exactamente el fallo que esto tiene que atrapar.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => documentos.path,
    );
  });

  setUp(() async {
    documentos = await Directory.systemTemp.createTemp('docs-informe-');
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

  tearDown(() async {
    await db.close();
    if (await documentos.exists()) await documentos.delete(recursive: true);
  });

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

    group('el PDF va al bucket', () {
      test('se guarda en disco y se encola con la version en el nombre',
          () async {
        // El nombre lleva la version porque las versiones no se borran: sin
        // eso, regenerar sobreescribiria en el bucket el informe que ya se le
        // entrego al productor.
        final informe = await repo.guardarInforme(
          visitaId: visitaId,
          titulo: 'Informe',
          contenido: '# Informe',
          tipo: 'Resumen para el agricultor',
        );

        final ruta = await repo.guardarPdfInforme(informe.id, [1, 2, 3, 4]);

        expect(ruta, endsWith('informe-01.pdf'));
        expect(File(ruta).existsSync(), isTrue);
        expect(await File(ruta).length(), 4);

        final item = await (db.select(db.syncQueue)
              ..where((q) => q.operacion.equals('upload_informe')))
            .getSingle();
        expect(item.archivoPath, ruta);
        // La cola sube por visita, igual que el audio y las fotos.
        expect(item.entidadId, visitaId);
        expect(item.bytesTotales, 4);
      });

      test('el PDF va detras del audio y de las fotos en la cola', () async {
        // El audio es irrecuperable; el PDF se puede volver a armar desde el
        // markdown. En una vereda con una barra, la ventana de red es para lo
        // que no se recupera.
        final informe = await repo.guardarInforme(
          visitaId: visitaId,
          titulo: 'Informe',
          contenido: '# Informe',
          tipo: 'Resumen para el agricultor',
        );
        await repo.guardarPdfInforme(informe.id, [1]);

        final item = await (db.select(db.syncQueue)
              ..where((q) => q.operacion.equals('upload_informe')))
            .getSingle();
        expect(item.prioridad, greaterThan(200));
      });

      test('entregar dos veces no encola dos subidas del mismo byte', () async {
        final informe = await repo.guardarInforme(
          visitaId: visitaId,
          titulo: 'Informe',
          contenido: '# Informe',
          tipo: 'Resumen para el agricultor',
        );

        await repo.guardarPdfInforme(informe.id, [1, 2]);
        await repo.guardarPdfInforme(informe.id, [1, 2]);

        final items = await (db.select(db.syncQueue)
              ..where((q) => q.operacion.equals('upload_informe')))
            .get();
        expect(items, hasLength(1));
      });

      test('regenerar deja el PDF del anterior donde estaba', () async {
        // El que ya se le mostro al productor no se puede pisar.
        final v1 = await repo.guardarInforme(
          visitaId: visitaId,
          titulo: 'Informe',
          contenido: '# Uno',
          tipo: 'Resumen para el agricultor',
        );
        final ruta1 = await repo.guardarPdfInforme(v1.id, [1]);

        final v2 = await repo.guardarInforme(
          visitaId: visitaId,
          titulo: 'Informe',
          contenido: '# Dos',
          tipo: 'Resumen para el agricultor',
        );
        final ruta2 = await repo.guardarPdfInforme(v2.id, [2, 2]);

        expect(ruta1, isNot(ruta2));
        expect(ruta2, endsWith('informe-02.pdf'));
        expect(File(ruta1).existsSync(), isTrue);
        expect(await repo.versionDeInformePorPdf(ruta1), 1);
        expect(await repo.versionDeInformePorPdf(ruta2), 2);
      });

      test('el enlace del bucket llega al payload cuando ya subio', () async {
        // Antes de subir va vacio a proposito: el PDF tiene su propio item de
        // la cola y el upsert de la visita corre antes. Vacio significa
        // «todavia no subio», no «no existe».
        final informe = await repo.guardarInforme(
          visitaId: visitaId,
          titulo: 'Informe',
          contenido: '# Informe',
          tipo: 'Resumen para el agricultor',
        );
        final ruta = await repo.guardarPdfInforme(informe.id, [1]);

        var payload = await repo.payloadDeVisita(visitaId);
        expect((payload['informes'] as List).single, isNot(contains('enlace_pdf')));

        await repo.registrarEnlaceInforme(
          ruta,
          'https://b.s3.us-east-1.amazonaws.com/visitas/$visitaId/informes/informe-01.pdf',
        );

        payload = await repo.payloadDeVisita(visitaId);
        final i = (payload['informes'] as List).single as Map;
        expect(i['enlace_pdf'], contains('/informes/informe-01.pdf'));
      });
    });
  });
}
