import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El personal viene de Sirius Nomina Core, no se administra en la app agro.
/// Estas pruebas cuidan dos cosas: que el selector funcione sin red, y que
/// ninguna credencial de nomina llegue al telefono.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
  });

  tearDown(() => db.close());

  Future<List<Visitador>> activos() => (db.select(db.visitadores)
        ..where((v) => v.activo.equals(true))
        ..orderBy([(v) => OrderingTerm(expression: v.nombre)]))
      .get();

  test('los 18 empleados activos quedan disponibles sin red', () async {
    expect((await activos()).length, 18);
  });

  test('nadie llega sin ID Empleado: es la llave hacia la nomina', () async {
    // Airtable no vincula registros entre bases, asi que este codigo es lo
    // unico que une a la persona con su registro de nomina.
    final sinCodigo = (await activos())
        .where((v) => (v.idEmpleado ?? '').isEmpty)
        .map((v) => v.nombre);

    expect(sinCodigo, isEmpty);
  });

  test('los codigos de empleado y los usuarios son unicos', () async {
    final lista = await activos();

    expect(lista.map((v) => v.idEmpleado).toSet().length, 18);
    expect(lista.map((v) => v.usuarioApp).toSet().length, 18);
  });

  test('el codigo de empleado tiene el formato de nomina', () async {
    for (final v in await activos()) {
      expect(v.idEmpleado, matches(RegExp(r'^SIRIUS-PER-\d{4}$')));
    }
  });

  test('los de baja y suspendidos NO se sembraron', () async {
    final nombres = (await activos()).map((v) => v.nombre).toList();

    // De baja en nomina.
    expect(nombres, isNot(contains('Yeison Querubin  Nieto Cogua ')));
    expect(nombres.any((n) => n.contains('Yeferson')), isFalse);
    // Cuenta generica de la empresa, suspendida: no es una persona.
    expect(nombres.any((n) => n.contains('Sirius Regenerative Solutions')), isFalse);
  });

  test('cada uno trae su cargo real de la nomina', () async {
    final polania = (await activos())
        .firstWhere((v) => v.nombre.contains('Polania'));

    expect(polania.cargo, 'LIDER EN REGENERACION AMBIENTAL');
    expect(polania.idEmpleado, 'SIRIUS-PER-0013');
  });

  test('el rol de la app se derivo del nivel de acceso, y solo hay dos',
      () async {
    // Nadie en la nomina tiene cargo de visitador: el rol es una propuesta.
    expect((await activos()).map((v) => v.rol).toSet(), {'Visitador', 'Coordinador'});
  });

  test('la tabla local no tiene donde guardar una contrasena', () async {
    // Personal.Password de nomina esta en texto plano. Que no exista la
    // columna es la garantia estructural de que no se puede copiar por
    // descuido: no alcanza con acordarse de no leerla.
    final columnas = db.visitadores.$columns.map((c) => c.name.toLowerCase());

    expect(columnas, isNot(contains('password')));
    expect(columnas, isNot(contains('contrasena')));
    expect(columnas.any((c) => c.contains('pass')), isFalse);
    expect(columnas.any((c) => c.contains('hash')), isFalse);
  });

  test('la semilla no contiene la palabra password ni un hash', () async {
    final crudo = await rootBundle.loadString(Semilla.rutaVisitadores);

    // El asset menciona el problema en una nota, pero no puede traer el dato.
    expect(crudo.contains('"password"'), isFalse);
    expect(crudo.contains('"contrasena"'), isFalse);
  });

  test('una visita queda ligada a quien la hizo', () async {
    final repo = VisitaRepository(db);
    final vereda = (await db.select(db.veredas).get()).first;
    final quien = (await activos()).firstWhere((v) => v.usuarioApp == 'santiago');

    final id = await repo.crearVisitaConProductor(
      inicio: DateTime(2026, 9, 7, 8),
      nombreProductor: 'Pedro Rodriguez',
      veredaLocalId: vereda.id,
      visitadorLocalId: quien.id,
    );

    final visita = await (db.select(db.visitas)..where((v) => v.id.equals(id)))
        .getSingle();
    expect(visita.visitadorLocalId, quien.id);
  });

  test('sembrar dos veces no duplica el personal', () async {
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    expect((await activos()).length, 18);
  });
}
