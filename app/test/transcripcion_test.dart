import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// Lo del Dia 4 que vive en la app: armar el vocabulario de refuerzo de esta
/// visita y guardar la transcripcion con sus marcas de tiempo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VisitaRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
  });

  tearDown(() => db.close());

  Future<String> visitaCon(String nombre, {String? finca}) async {
    final vereda = (await db.select(db.veredas).get())
        .firstWhere((v) => v.vereda == 'Guaicaramo');
    return repo.crearVisitaConProductor(
      inicio: DateTime(2026, 9, 6, 9),
      nombreProductor: nombre,
      nombreFinca: finca,
      veredaLocalId: vereda.id,
    );
  }

  group('vocabulario de refuerzo de la visita', () {
    test('el nombre va completo y partido en palabras', () async {
      final id = await visitaCon('Pedro Rodriguez Estupinan');
      final terminos = await repo.terminosDeVisita(id);

      // El agricultor dice "Pedro" a secas; el visitador, el nombre completo.
      expect(terminos.take(4), [
        'Pedro Rodriguez Estupinan',
        'Pedro',
        'Rodriguez',
        'Estupinan',
      ]);
    });

    test('incluye vereda y municipio', () async {
      final id = await visitaCon('Pedro Rodriguez');
      final terminos = await repo.terminosDeVisita(id);

      expect(terminos, contains('Guaicaramo'));
      expect(terminos, contains('Barranca de Upia'));
    });

    test('incluye el nombre de la finca cuando lo hay', () async {
      final id = await visitaCon('Pedro Rodriguez', finca: 'La Esperanza');
      expect(await repo.terminosDeVisita(id), contains('La Esperanza'));
    });

    test('descarta las palabras de una o dos letras', () async {
      final id = await visitaCon('Maria de la Cruz Nino');
      final terminos = await repo.terminosDeVisita(id);

      // "de" y "la" no aportan y gastan cupo del limite del proveedor.
      expect(terminos, isNot(contains('de')));
      expect(terminos, isNot(contains('la')));
      expect(terminos, contains('Cruz'));
      expect(terminos.first, 'Maria Cruz Nino');
    });

    test('no repite: si la finca se llama como la vereda, va una vez',
        () async {
      final id = await visitaCon('Pedro Rodriguez', finca: 'Guaicaramo');
      final terminos = await repo.terminosDeVisita(id);

      expect(terminos.where((t) => t.toLowerCase() == 'guaicaramo').length, 1);
    });

    test('una visita que no existe devuelve lista vacia, no explota', () async {
      expect(await repo.terminosDeVisita('no-existe'), isEmpty);
    });
  });

  group('guardar la transcripcion', () {
    Future<(String, String)> conTramo() async {
      final visitaId = await visitaCon('Pedro Rodriguez');
      final grabacionId = await repo.registrarGrabacion(
        visitaId: visitaId,
        orden: 1,
        archivoPath: '/data/tramo-1.m4a',
        inicio: DateTime(2026, 9, 6, 9, 5),
        tamanoBytes: 1200000,
      );
      return (visitaId, grabacionId);
    }

    test('con marcas de tiempo queda Transcrita', () async {
      final (_, grabacionId) = await conTramo();

      await repo.guardarTranscripcion(
        grabacionId: grabacionId,
        texto: 'Buenos dias. Mucho gusto, Pedro.',
        textoConMarcas: '[00:00] Hablante 1: Buenos dias.\n'
            '[00:03] Hablante 2: Mucho gusto, Pedro.',
        motor: 'nova-2',
        duracionSeg: 300,
      );

      final g = (await repo.grabacionesDeVisita(
        (await db.select(db.visitas).get()).single.id,
      )).single;

      expect(g.estado, 'Transcrita');
      expect(g.motorTranscripcion, 'nova-2');
      expect(g.duracionSeg, 300);
      expect(g.transcripcionMarcas, contains('[00:03] Hablante 2'));
    });

    test('sin marcas de tiempo queda Sin diarizar, no Transcrita', () async {
      // Sirve para leer pero no para citar, asi que no se puede dar por lista.
      final (_, grabacionId) = await conTramo();

      await repo.guardarTranscripcion(
        grabacionId: grabacionId,
        texto: 'texto plano sin turnos',
        motor: 'nova-2',
      );

      final g = (await repo.grabacionesDeVisita(
        (await db.select(db.visitas).get()).single.id,
      )).single;
      expect(g.estado, 'Sin diarizar');
    });
  });

  group('transcripcion completa de la visita', () {
    test('concatena las marcas de los tramos en orden', () async {
      final visitaId = await visitaCon('Pedro Rodriguez');

      for (var i = 1; i <= 3; i++) {
        final gid = await repo.registrarGrabacion(
          visitaId: visitaId,
          orden: i,
          archivoPath: '/data/tramo-$i.m4a',
          inicio: DateTime(2026, 9, 6, 9, i),
        );
        await repo.guardarTranscripcion(
          grabacionId: gid,
          texto: 'plano $i',
          textoConMarcas: '[00:0$i] Hablante 2: parte $i',
        );
      }

      final completa = await repo.transcripcionCompleta(visitaId);

      expect(completa.indexOf('Tramo 1'), lessThan(completa.indexOf('Tramo 2')));
      expect(completa.indexOf('Tramo 2'), lessThan(completa.indexOf('Tramo 3')));
      expect(completa, contains('[00:02] Hablante 2: parte 2'));
    });

    test('salta los tramos que todavia no se transcribieron', () async {
      final visitaId = await visitaCon('Pedro Rodriguez');

      final conTexto = await repo.registrarGrabacion(
        visitaId: visitaId,
        orden: 1,
        archivoPath: '/data/tramo-1.m4a',
        inicio: DateTime(2026, 9, 6, 9, 1),
      );
      await repo.guardarTranscripcion(
        grabacionId: conTexto,
        texto: 'algo',
        textoConMarcas: '[00:01] Hablante 2: algo',
      );
      await repo.registrarGrabacion(
        visitaId: visitaId,
        orden: 2,
        archivoPath: '/data/tramo-2.m4a',
        inicio: DateTime(2026, 9, 6, 9, 2),
      );

      final completa = await repo.transcripcionCompleta(visitaId);

      expect(completa, contains('Tramo 1'));
      expect(completa, isNot(contains('Tramo 2')));
    });

    test('sin nada transcrito devuelve vacio', () async {
      final visitaId = await visitaCon('Pedro Rodriguez');
      expect(await repo.transcripcionCompleta(visitaId), '');
    });
  });
}
