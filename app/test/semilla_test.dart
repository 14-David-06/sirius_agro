import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';

/// Verifica que la semilla empaquetada en el APK sea la de verdad: si alguien
/// activa un modulo en Airtable y no regenera los assets, estas pruebas fallan
/// antes de que un visitador salga al campo con un catalogo viejo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
  });

  tearDown(() => db.close());

  test('las 7 veredas de Barranca de Upia quedan disponibles sin red', () async {
    final veredas = await db.select(db.veredas).get();

    expect(veredas.length, 7);
    expect(veredas.map((v) => v.vereda).toSet(), {
      'Carutal',
      'El Algarrobo',
      'El Hijoa',
      'Guaicaramo',
      'Las Moras',
      'Los Pavitos',
      'San Ignacio',
    });
    expect(veredas.every((v) => v.municipio == 'Barranca de Upia'), isTrue);
    // El id local es el record id de Airtable: al sincronizar no se duplican.
    expect(veredas.every((v) => v.remoteId == v.id), isTrue);
  });

  test('el catalogo trae 55 activos y 27 obligatorios', () async {
    expect((await db.camposActivos()).length, 55);
    expect((await db.obligatoriosActivos()).length, 27);
  });

  test('todo obligatorio tiene pregunta guia: sin ella no hay que preguntar',
      () async {
    final sinPregunta = (await db.obligatoriosActivos())
        .where((c) => (c.preguntaGuia ?? '').trim().isEmpty)
        .map((c) => c.claveTecnica);

    expect(sinPregunta, isEmpty);
  });

  test('los 4 modulos nuevos del Dia 0 estan en la semilla', () async {
    final modulos = (await db.camposActivos()).map((c) => c.modulo).toSet();

    expect(modulos, contains('Conectividad'));
    expect(modulos, contains('Historia y origen'));
    // Ganaderia sobrevive solo con `animales`.
    final ganaderia = (await db.camposActivos())
        .where((c) => c.modulo == 'Ganaderia y animales')
        .map((c) => c.claveTecnica);
    expect(ganaderia, ['animales']);
  });

  test('los modulos fuera del alcance V1 no estan en la semilla', () async {
    final modulos = (await db.camposActivos()).map((c) => c.modulo).toSet();

    expect(modulos, isNot(contains('Mano de obra')));
    expect(modulos, isNot(contains('Creditos y apoyos')));
    expect(modulos, isNot(contains('Practicas regenerativas')));
    expect(modulos, isNot(contains('Ambiente y biodiversidad')));
    expect(modulos, isNot(contains('Maquinaria e infraestructura')));
  });

  test('motivo_llegada cuenta para la completitud pero no se sugiere',
      () async {
    const visitaId = 'v-semilla-1';
    await db.into(db.visitas).insert(
          VisitasCompanion.insert(id: visitaId, inicio: DateTime(2026, 9, 3)),
        );

    final faltan = await db.faltantes(visitaId);
    final sugeribles = await db.faltantesSugeribles(visitaId);

    expect(faltan.length, 27);
    expect(faltan.map((c) => c.claveTecnica), contains('motivo_llegada'));

    expect(sugeribles.length, 26);
    expect(
      sugeribles.map((c) => c.claveTecnica),
      isNot(contains('motivo_llegada')),
    );

    // Las otras tres de Historia y origen SI se pueden preguntar.
    expect(sugeribles.map((c) => c.claveTecnica), containsAll([
      'municipio_procedencia',
      'anios_en_territorio',
      'como_inicio_agricultura',
    ]));
  });

  test('sembrar dos veces no duplica ni pierde nada', () async {
    await Semilla(db, rootBundle).sembrarSiHaceFalta();

    expect((await db.select(db.veredas).get()).length, 7);
    expect((await db.camposActivos()).length, 55);
  });

  test('las listas cerradas traen sus opciones', () async {
    final tenencia = (await db.camposActivos())
        .firstWhere((c) => c.claveTecnica == 'tenencia');

    expect(tenencia.tipoDato, 'Lista');
    expect(tenencia.opciones?.split('\n'), contains('Propia sin titulo'));
  });
}
