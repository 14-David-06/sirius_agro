import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El flujo del Dia 2: llegar a la finca, crear la visita con GPS y vereda,
/// pedir el consentimiento, y solo entonces poder grabar.
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

  Future<String> crear({String? finca}) async {
    final veredas = await db.select(db.veredas).get();
    final guaicaramo = veredas.firstWhere((v) => v.vereda == 'Guaicaramo');

    return repo.crearVisitaConProductor(
      inicio: DateTime(2026, 9, 4, 9, 20),
      nombreProductor: 'Pedro Rodriguez',
      nombreFinca: finca,
      veredaLocalId: guaicaramo.id,
      latitud: 4.5709,
      longitud: -72.9612,
      precisionGps: 7.5,
    );
  }

  group('crear la visita al llegar a la finca', () {
    test('deja productor, finca y visita ligados y sin sincronizar', () async {
      final id = await crear(finca: 'La Esperanza');

      final v = await (db.select(db.visitas)..where((x) => x.id.equals(id)))
          .getSingle();

      expect(v.latitud, 4.5709);
      expect(v.precisionGps, 7.5);
      expect(v.sincronizada, isFalse);
      expect(v.estado, 'En curso');
      expect(v.tipoVisita, 'Primera visita');

      final productor = (await db.select(db.productores).get()).single;
      expect(productor.nombreCompleto, 'Pedro Rodriguez');
      expect(productor.sincronizado, isFalse);
      // El consecutivo BU-0001 lo asigna el backend: dos telefonos offline
      // generarian el mismo numero.
      expect(productor.codigoProductor, null);

      final finca = (await db.select(db.fincas).get()).single;
      expect(finca.nombre, 'La Esperanza');
      expect(finca.productorLocalId, productor.id);
      expect(v.fincaLocalId, finca.id);
      expect(v.veredaLocalId, finca.veredaLocalId);
    });

    test('sin nombre de finca la visita se crea igual, sin finca', () async {
      final id = await crear();

      expect(await db.select(db.fincas).get(), isEmpty);
      final v = await (db.select(db.visitas)..where((x) => x.id.equals(id)))
          .getSingle();
      expect(v.fincaLocalId, null);
      // La vereda si queda en la visita aunque no haya finca todavia.
      expect(v.veredaLocalId, isA<String>());
    });

    test('el id de la visita es un UUID v4 del dispositivo', () async {
      final id = await crear();

      expect(id, matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      )));
    });

    test('dos visitas al mismo agricultor cuelgan de la MISMA ficha', () async {
      // Antes esto creaba dos productores, y era la fuga de trazabilidad mas
      // tonta que tenia la app: dos visitas a don Pedro escritas a mano
      // quedaban colgadas de dos don Pedro, cada uno con su finca y ninguno
      // con la historia del otro.
      //
      // Lo que sigue siendo cierto es que cada VISITA es un evento propio con
      // su propio id: la visita es el evento, el agricultor es permanente.
      final a = await crear();
      final b = await crear();

      expect(a, isNot(b));
      expect((await db.select(db.productores).get()).length, 1);

      final visitas = await db.select(db.visitas).get();
      expect(visitas.length, 2);
      expect(visitas.first.productorLocalId, visitas.last.productorLocalId);
    });
  });

  group('el candado del consentimiento', () {
    test('una visita recien creada NO puede grabar', () async {
      final id = await crear();
      expect(await repo.puedeGrabar(id), isFalse);
    });

    test('solo el permiso de audio habilita la grabacion', () async {
      final id = await crear();

      // Fotos y datos si, audio no: sigue sin poder grabar.
      await repo.registrarConsentimiento(
        id,
        audio: false,
        fotos: true,
        usoDatos: true,
      );
      expect(await repo.puedeGrabar(id), isFalse);

      await repo.registrarConsentimiento(
        id,
        audio: true,
        fotos: true,
        usoDatos: true,
        segundoDelAudio: 28,
      );
      expect(await repo.puedeGrabar(id), isTrue);
    });

    test('el segundo del consentimiento queda como prueba auditable', () async {
      final id = await crear();
      await repo.registrarConsentimiento(
        id,
        audio: true,
        fotos: true,
        usoDatos: true,
        segundoDelAudio: 28,
      );

      final v = await (db.select(db.visitas)..where((x) => x.id.equals(id)))
          .getSingle();
      expect(v.segundoConsentimiento, 28);
    });

    test('un no inicial se puede revertir a mitad de la visita', () async {
      final id = await crear();

      // El productor dice que no al principio.
      await repo.registrarConsentimiento(
        id,
        audio: false,
        fotos: false,
        usoDatos: false,
      );
      expect(await repo.puedeGrabar(id), isFalse);

      // Cambia de opinion conversando: se le vuelve a pedir el permiso sobre
      // LA MISMA visita, sin tener que botarla y crear otra.
      await repo.registrarConsentimiento(
        id,
        audio: true,
        fotos: true,
        usoDatos: true,
        segundoDelAudio: 95,
      );

      expect(await repo.puedeGrabar(id), isTrue);
      final v = await (db.select(db.visitas)..where((x) => x.id.equals(id)))
          .getSingle();
      expect(v.consienteFotos, isTrue);
      expect(v.segundoConsentimiento, 95);
    });

    test('volver a pedir el permiso no borra la prueba anterior', () async {
      final id = await crear();
      await repo.registrarConsentimiento(
        id,
        audio: true,
        fotos: false,
        usoDatos: true,
        segundoDelAudio: 28,
      );

      // Segunda pasada sin segundo: se autoriza tambien la camara. El segundo
      // donde consta la voz del productor tiene que sobrevivir.
      await repo.registrarConsentimiento(
        id,
        audio: true,
        fotos: true,
        usoDatos: true,
      );

      final v = await (db.select(db.visitas)..where((x) => x.id.equals(id)))
          .getSingle();
      expect(v.consienteFotos, isTrue);
      expect(v.segundoConsentimiento, 28);
    });

    test('revocar el consentimiento vuelve a bloquear la grabacion', () async {
      final id = await crear();
      await repo.registrarConsentimiento(
        id,
        audio: true,
        fotos: true,
        usoDatos: true,
      );
      expect(await repo.puedeGrabar(id), isTrue);

      await repo.registrarConsentimiento(
        id,
        audio: false,
        fotos: false,
        usoDatos: false,
      );
      expect(await repo.puedeGrabar(id), isFalse);
    });
  });

  group('completitud sobre el catalogo real', () {
    test('una visita nueva arranca en 0% de 27 obligatorios', () async {
      final id = await crear();

      expect(await db.calcularCompletitud(id), 0);
      expect((await db.faltantes(id)).length, 27);
      expect((await db.faltantesSugeribles(id)).length, 26);
    });

    test('un obligatorio resuelto mueve el semaforo', () async {
      final id = await crear();

      await db.insertarHallazgo(
        HallazgosCompanion.insert(
          id: 'h1',
          visitaId: id,
          claveTecnica: 'nombre_productor',
          certeza: const Value(Certeza.confirmado),
          hablante: const Value(Hablante.agricultor),
          citaTextual: const Value('yo soy Pedro Rodriguez'),
          creadoEn: DateTime(2026, 9, 4, 9, 25),
        ),
      );
      final pct = await db.refrescarCompletitud(id);

      // 1 de 27 redondea a 4%.
      expect(pct, 4);
      expect((await db.faltantes(id)).length, 26);
    });
  });

  group('el tramo de grabacion se registra y se encola', () {
    test('el audio entra a la cola con prioridad 0', () async {
      final id = await crear();
      await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: '/data/visitas/$id/tramo-1.m4a',
        inicio: DateTime(2026, 9, 4, 9, 30),
        duracionSeg: 1800,
        tamanoBytes: 7340032,
      );

      final grabacion = (await db.select(db.grabaciones).get()).single;
      expect(grabacion.orden, 1);
      expect(grabacion.visitaId, id);
      expect(grabacion.enlaceAudio, null); // lo llena el backend al subir

      final item = (await db.pendientesDeVisita(id)).single;
      expect(item.operacion, 'upload_audio');
      expect(item.prioridad, 0);
      expect(item.bytesTotales, 7340032);
      expect(item.bytesSubidos, 0);
    });

    test('varios tramos conviven en orden', () async {
      final id = await crear();
      for (var i = 1; i <= 3; i++) {
        await repo.registrarGrabacion(
          visitaId: id,
          orden: i,
          archivoPath: '/data/visitas/$id/tramo-$i.m4a',
          inicio: DateTime(2026, 9, 4, 9, 30 + i),
          tamanoBytes: 1024 * i,
        );
      }

      final ordenes =
          (await db.select(db.grabaciones).get()).map((g) => g.orden).toList()
            ..sort();
      expect(ordenes, [1, 2, 3]);
      expect((await db.pendientesDeVisita(id)).length, 3);
    });
  });
}
