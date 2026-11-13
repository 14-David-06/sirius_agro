import 'package:drift/drift.dart' show Value;
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

  // 55 campos del catalogo de Airtable, 6 que ya existian alla apagados y
  // cubren preguntas de la encuesta de caracterizacion, y 61 temas nuevos de
  // la encuesta (56 se sugieren en la lista y 5 son sensibles).
  test('el catalogo trae 122 activos y 89 obligatorios', () async {
    expect((await db.camposActivos()).length, 122);
    expect((await db.obligatoriosActivos()).length, 89);
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

    expect(modulos, isNot(contains('Practicas regenerativas')));
    expect(modulos, isNot(contains('Ambiente y biodiversidad')));
  });

  // Mano de obra, Creditos y apoyos y Maquinaria e infraestructura estaban
  // fuera del alcance V1. Entraron solo con los campos que la encuesta de
  // caracterizacion necesitaba y que ya existian, apagados, en Airtable: se
  // prendieron en vez de crear temas que dijeran lo mismo.
  test('de los modulos que se prendieron solo entran los campos de la encuesta',
      () async {
    final activos = await db.camposActivos();
    List<String> de(String modulo) => activos
        .where((c) => c.modulo == modulo)
        .map((c) => c.claveTecnica)
        .toList()
      ..sort();

    expect(de('Mano de obra'), ['contrata_jornaleros']);
    expect(de('Creditos y apoyos'), ['apoyos_recibidos', 'tiene_credito']);
    expect(
      de('Maquinaria e infraestructura'),
      ['acceso_vial', 'infraestructura', 'maquinaria'],
    );
  });

  test('motivo_llegada cuenta para la completitud pero no se sugiere',
      () async {
    const visitaId = 'v-semilla-1';
    await db.into(db.visitas).insert(
          VisitasCompanion.insert(id: visitaId, inicio: DateTime(2026, 9, 3)),
        );

    final faltan = await db.faltantes(visitaId);
    final sugeribles = await db.faltantesSugeribles(visitaId);

    expect(faltan.length, 89);
    expect(faltan.map((c) => c.claveTecnica), contains('motivo_llegada'));

    expect(sugeribles.length, 88);
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
    expect((await db.camposActivos()).length, 122);
  });

  test('un campo que ya no viene en la semilla se apaga, no se borra',
      () async {
    // Un telefono que recibio un campo con una semilla anterior. Los
    // hallazgos de sus visitas siguen apuntando a esa clave.
    await db.guardarCatalogo([
      CatalogoCamposCompanion.insert(
        claveTecnica: 'tema_que_salio',
        campo: 'Tema que salio del catalogo',
        modulo: 'Cultivos',
        obligatorioMvp: const Value(true),
      ),
    ]);
    expect((await db.camposActivos()).length, 123);
    await db.guardarAjuste('semilla_version', 'una semilla anterior');

    await Semilla(db, rootBundle).sembrarSiHaceFalta();

    final viejo = (await db.select(db.catalogoCampos).get())
        .firstWhere((c) => c.claveTecnica == 'tema_que_salio');
    expect(viejo.activo, isFalse);
    expect((await db.camposActivos()).length, 122);
    expect((await db.obligatoriosActivos()).length, 89);
  });

  test('las listas cerradas traen sus opciones', () async {
    final tenencia = (await db.camposActivos())
        .firstWhere((c) => c.claveTecnica == 'tenencia');

    expect(tenencia.tipoDato, 'Lista');
    expect(tenencia.opciones?.split('\n'), contains('Propia sin titulo'));
  });
}
