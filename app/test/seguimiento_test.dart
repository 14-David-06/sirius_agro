import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/informe_tecnico.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';
import 'package:sirius_agro/ui/visita_page.dart' show esDeHoy;

/// Las visitas de seguimiento: volver a ver al mismo agricultor otro dia.
///
/// Lo que se protege aca es que cada reunion quede como su propia visita, con
/// su fecha y su consecutivo dentro de la historia del agricultor, y que el
/// seguimiento arranque donde quedo la visita anterior en vez de volver a
/// pedir las 85 preguntas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VisitaRepository repo;
  late Directory documentos;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => documentos.path,
    );
  });

  setUp(() async {
    documentos = await Directory.systemTemp.createTemp('docs-seguimiento-');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (documentos.existsSync()) await documentos.delete(recursive: true);
  });

  /// La primera visita a Pedro. Las siguientes se cuelgan de su ficha con
  /// [seguimiento], igual que hace la pantalla de la visita de seguimiento.
  Future<String> primera(DateTime inicio) => repo.crearVisitaConProductor(
        inicio: inicio,
        nombreProductor: 'Pedro Rodriguez',
        nombreFinca: 'La Esperanza',
      );

  Future<String> seguimiento(String anterior, DateTime inicio) async {
    final pedro = (await repo.productorDeVisita(anterior))!;
    return repo.crearVisitaConProductor(
      inicio: inicio,
      nombreProductor: pedro.nombreCompleto,
      productorLocalId: pedro.id,
      nombreFinca: 'La Esperanza',
    );
  }

  Future<void> resolver(String visitaId, String clave, {String? id}) =>
      db.insertarHallazgo(
        HallazgosCompanion.insert(
          id: id ?? '$visitaId-$clave',
          visitaId: visitaId,
          claveTecnica: clave,
          certeza: const Value(Certeza.confirmado),
          hablante: const Value(Hablante.agricultor),
          citaTextual: const Value('lo dijo el agricultor'),
          creadoEn: DateTime(2026, 9, 4),
        ),
      );

  Future<Visita> visita(String id) =>
      (db.select(db.visitas)..where((v) => v.id.equals(id))).getSingle();

  group('cada reunion es su propia visita', () {
    test('el seguimiento queda con su fecha, su tipo y la misma ficha',
        () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));

      final segunda = await visita(v2);
      expect(segunda.inicio, DateTime(2026, 9, 18, 10));
      expect(segunda.tipoVisita, 'Seguimiento');
      expect(segunda.productorLocalId, (await visita(v1)).productorLocalId);
      // Una sola persona y una sola finca: la historia no se parte en dos.
      expect(await db.select(db.productores).get(), hasLength(1));
      expect(await db.select(db.fincas).get(), hasLength(1));
    });
  });

  group('el consecutivo por agricultor', () {
    test('sale del orden de las fechas, no del orden en que se crearon',
        () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      final v3 = await seguimiento(v1, DateTime(2026, 10, 2, 8));
      // Registrada despues pero ocurrida antes: una visita que se cargo tarde.
      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));

      expect(await db.numeroDeVisita(v1), 1);
      expect(await db.numeroDeVisita(v2), 2);
      expect(await db.numeroDeVisita(v3), 3);

      // La lista agrupada da los mismos numeros sin consultar de nuevo.
      final grupo = (await repo.observarVisitasPorAgricultor().first).single;
      expect(
        [for (final v in grupo.visitas) grupo.numeroDe(v)],
        [3, 2, 1],
      );
      expect(grupo.visitas.first.id, v3);
    });

    test('cada agricultor cuenta desde 1', () async {
      final pedro = await primera(DateTime(2026, 9, 4, 9));
      final ana = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 5, 9),
        nombreProductor: 'Ana Perez',
      );

      expect(await db.numeroDeVisita(pedro), 1);
      expect(await db.numeroDeVisita(ana), 1);
    });

    test('una visita sin agricultor no tiene numero', () async {
      final suelta = await repo.crearVisita(inicio: DateTime(2026, 9, 4));

      expect(await db.numeroDeVisita(suelta), isNull);
      final grupo = (await repo.observarVisitasPorAgricultor().first).single;
      expect(grupo.numeroDe(grupo.visitas.single), isNull);
    });

    test('una visita mas vieja que baja de Airtable corre los numeros',
        () async {
      final propia = await primera(DateTime(2026, 9, 20, 9));
      expect(await db.numeroDeVisita(propia), 1);

      await repo.importarHistorial({
        'productor': 'Pedro Rodriguez',
        'visitas': [
          {
            'codigo_visita': 'remota-1',
            'inicio': '2026-09-10T09:30:00.000',
            'finca': 'La Esperanza',
            'hallazgos': const [],
          },
        ],
      });

      expect(await db.numeroDeVisita('remota-1'), 1);
      expect(await db.numeroDeVisita(propia), 2);
    });

    test('el informe tecnico lleva el consecutivo', () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));

      final datos = await repo.datosInformeTecnico(v2);

      expect(datos.numeroVisita, 2);
      expect(numeroVisitaLegible(datos.numeroVisita), 'N.º 2');
      expect(numeroVisitaLegible(null), '—');
    });
  });

  group('la cobertura acumulada', () {
    test('el seguimiento no vuelve a pedir lo que ya se resolvio', () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      await resolver(v1, 'fuente_agua');
      await resolver(v1, 'municipio_vereda');
      await db.refrescarCompletitud(v1);

      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));
      final faltan = {for (final c in await db.faltantes(v2)) c.claveTecnica};

      expect(faltan, isNot(contains('fuente_agua')));
      expect(faltan, isNot(contains('municipio_vereda')));
      expect(faltan, hasLength(84));
      // 2 de 86 redondea a 2%: el seguimiento no arranca en cero.
      expect(await db.calcularCompletitud(v2), 2);
      expect(await db.obligatoriosResueltosAntes(v2), 2);
    });

    test('lo que se resuelve despues no cambia la visita anterior', () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      await resolver(v1, 'fuente_agua');
      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));
      await resolver(v2, 'tenencia');

      // La visita 1 mide lo que se sabia ESE dia.
      expect(await db.calcularCompletitud(v1), 1);
      expect(await db.obligatoriosResueltosAntes(v1), 0);
      // La 2 suma las dos.
      expect(await db.calcularCompletitud(v2), 2);
    });

    test('completar la visita anterior recalcula el seguimiento guardado',
        () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));
      await db.refrescarCompletitud(v2);
      expect((await visita(v2)).completitudPct, 0);

      // El dato llega despues a la visita 1, por ejemplo desde el complemento.
      await repo.guardarExtraccion(
        visitaId: v1,
        extraidos: const [
          HallazgoExtraido(
            claveTecnica: 'fuente_agua',
            certeza: Certeza.confirmado,
            hablante: Hablante.agricultor,
            citaTextual: 'de la quebrada',
          ),
          HallazgoExtraido(
            claveTecnica: 'tenencia',
            certeza: Certeza.confirmado,
            hablante: Hablante.agricultor,
            citaTextual: 'es propia',
          ),
        ],
      );

      expect((await visita(v1)).completitudPct, 2);
      expect((await visita(v2)).completitudPct, 2);
    });

    test('lo pendiente de la visita anterior se vuelve a pedir', () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      await db.insertarHallazgo(
        HallazgosCompanion.insert(
          id: 'h-sin-cita',
          visitaId: v1,
          claveTecnica: 'fuente_agua',
          // Sin cita la regla dura lo deja Pendiente: no cuenta como resuelto.
          certeza: const Value(Certeza.confirmado),
          hablante: const Value(Hablante.agricultor),
          creadoEn: DateTime(2026, 9, 4),
        ),
      );

      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));
      final faltan = {for (final c in await db.faltantes(v2)) c.claveTecnica};

      expect(faltan, contains('fuente_agua'));
    });

    test('una visita que el productor revoco no aporta', () async {
      final v1 = await primera(DateTime(2026, 9, 4, 9));
      await resolver(v1, 'fuente_agua');
      await (db.update(db.visitas)..where((v) => v.id.equals(v1))).write(
        const VisitasCompanion(marcadaParaEliminacion: Value(true)),
      );

      final v2 = await seguimiento(v1, DateTime(2026, 9, 18, 10));

      expect(await db.calcularCompletitud(v2), 0);
      expect(await db.obligatoriosResueltosAntes(v2), 0);
    });

    test('lo que resolvio otro visitador, traido de Airtable, tambien cuenta',
        () async {
      final propia = await primera(DateTime(2026, 9, 20, 9));
      await db.refrescarCompletitud(propia);
      expect((await visita(propia)).completitudPct, 0);

      await repo.importarHistorial({
        'productor': 'Pedro Rodriguez',
        'visitas': [
          {
            'codigo_visita': 'remota-1',
            'inicio': '2026-09-10T09:30:00.000',
            'finca': 'La Esperanza',
            'hallazgos': [
              {
                'clave_tecnica': 'fuente_agua',
                'valor_texto': 'quebrada',
                'certeza': 'Confirmado',
                'hablante': 'Agricultor',
                'cita_textual': 'de la quebrada',
                'estado': 'Confirmado',
              },
            ],
          },
        ],
      });

      final faltan = {
        for (final c in await db.faltantes(propia)) c.claveTecnica,
      };
      expect(faltan, isNot(contains('fuente_agua')));
      // El porcentaje guardado se recalcula al entrar el historial, no solo
      // la lista que se calcula al abrir la visita.
      expect((await visita(propia)).completitudPct, 1);
    });

    test('una visita sin agricultor solo cuenta lo suyo', () async {
      final a = await repo.crearVisita(inicio: DateTime(2026, 9, 4));
      await resolver(a, 'fuente_agua');
      final b = await repo.crearVisita(inicio: DateTime(2026, 9, 5));

      expect(await db.calcularCompletitud(a), 1);
      expect(await db.calcularCompletitud(b), 0);
    });
  });

  group('la visita de otro dia', () {
    test('se reconoce por la fecha del telefono', () {
      final ahora = DateTime(2026, 11, 23, 10);

      expect(esDeHoy(DateTime(2026, 11, 23, 7, 30), ahora: ahora), isTrue);
      expect(esDeHoy(DateTime(2026, 11, 22, 23, 59), ahora: ahora), isFalse);
      expect(esDeHoy(DateTime(2025, 11, 23, 10), ahora: ahora), isFalse);
    });
  });
}
