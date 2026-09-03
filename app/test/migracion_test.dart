import 'package:drift/drift.dart' show Migrator, Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// La prueba que faltaba.
///
/// Durante el desarrollo se instalaron varios APK sin subir `schemaVersion`, y
/// drift solo crea el esquema la primera vez que abre el archivo. Resultado: la
/// app actualizada abrio una base vieja tal cual y fallo al primer INSERT con
/// «table visitadores has no column named id_empleado».
///
/// En el piloto eso significaria una visita ya grabada en un telefono que no
/// arranca. La base local NO se puede borrar para arreglarla: ahi vive lo unico
/// que no se puede volver a capturar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  /// Deja el archivo como lo dejaba la version anterior de la app: sin las
  /// columnas que se agregaron despues.
  Future<void> envejecer() async {
    await db.customStatement('ALTER TABLE catalogo_campos DROP COLUMN no_sugerir');
    for (final c in ['id_empleado', 'cargo', 'email', 'telefono']) {
      await db.customStatement('ALTER TABLE visitadores DROP COLUMN $c');
    }
    // Antes de la v3 no existia el login: no habia donde guardar el hash ni
    // que sesion estaba abierta.
    await db.customStatement('DROP TABLE sesiones');
    await db.customStatement('DROP TABLE credenciales_locales');
  }

  Future<bool> existeTabla(String nombre) async {
    final filas = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          variables: [Variable<String>(nombre)],
        )
        .get();
    return filas.isNotEmpty;
  }

  test('la version del esquema subio: sin eso ninguna migracion corre', () {
    // Si alguien agrega una columna y no sube este numero, drift no altera la
    // base y la app falla en el telefono, no en el CI.
    expect(db.schemaVersion, greaterThanOrEqualTo(5));
  });

  group('reponer columnas que faltan', () {
    test('agrega las cinco columnas de la v2', () async {
      await envejecer();
      expect(await db.columnasDe('visitadores'), isNot(contains('id_empleado')));

      await db.migration.onUpgrade(Migrator(db), 1, db.schemaVersion);

      final visitadores = await db.columnasDe('visitadores');
      expect(visitadores, containsAll(['id_empleado', 'cargo', 'email', 'telefono']));
      expect(await db.columnasDe('catalogo_campos'), contains('no_sugerir'));
    });

    test('crea las tablas del login de la v3', () async {
      await envejecer();
      expect(await existeTabla('credenciales_locales'), isFalse);

      await db.migration.onUpgrade(Migrator(db), 1, db.schemaVersion);

      expect(await existeTabla('credenciales_locales'), isTrue);
      expect(await existeTabla('sesiones'), isTrue);
    });

    test('la v4 recrea las tablas del login con la cedula como llave', () async {
      // Un telefono que quedo en v3 tiene las tablas con `identificador`
      // (correo o ID de empleado). El login ahora es por cedula.
      await db.customStatement('DROP TABLE sesiones');
      await db.customStatement('DROP TABLE credenciales_locales');
      await db.customStatement(
        'CREATE TABLE credenciales_locales ('
        'identificador TEXT NOT NULL PRIMARY KEY, id_empleado TEXT NOT NULL, '
        'nombre TEXT NOT NULL, hash_bcrypt TEXT NOT NULL, '
        'ultimo_login_online INTEGER NOT NULL, valido_hasta INTEGER NOT NULL)',
      );
      await db.customStatement(
        'CREATE TABLE sesiones (unica INTEGER NOT NULL PRIMARY KEY, '
        'identificador TEXT NOT NULL, abierta INTEGER NOT NULL)',
      );

      await db.migration.onUpgrade(Migrator(db), 3, db.schemaVersion);

      expect(await db.columnasDe('credenciales_locales'), contains('cedula'));
      expect(await db.columnasDe('sesiones'), contains('cedula'));
      expect(
        await db.columnasDe('credenciales_locales'),
        isNot(contains('identificador')),
      );
    });

    test('recrear el login NO toca lo que el visitador capturo', () async {
      // Borrar credenciales es barato: se recuperan con un login con señal.
      // Borrar una grabacion no: eso es lo unico irrecuperable de una visita.
      await db.into(db.visitas).insert(
            VisitasCompanion.insert(
              id: 'visita-v3',
              inicio: DateTime(2026, 9, 3, 8),
              consienteAudio: const Value(true),
            ),
          );
      await db.into(db.grabaciones).insert(
            GrabacionesCompanion.insert(
              id: 'grab-v3',
              visitaId: 'visita-v3',
              orden: 1,
              archivoPath: '/data/visitas/visita-v3/tramo-1.m4a',
              inicio: DateTime(2026, 9, 3, 8, 5),
            ),
          );

      await db.migration.onUpgrade(Migrator(db), 3, db.schemaVersion);

      expect(await db.select(db.visitas).get(), hasLength(1));
      expect(await db.select(db.grabaciones).get(), hasLength(1));
    });

    test('la v5 crea la tabla de informes', () async {
      await db.customStatement('DROP TABLE informes');
      expect(await existeTabla('informes'), isFalse);

      await db.migration.onUpgrade(Migrator(db), 4, db.schemaVersion);

      expect(await existeTabla('informes'), isTrue);
      expect(await db.columnasDe('informes'), containsAll(['contenido', 'version']));
    });

    test('correrla dos veces no rompe nada', () async {
      await envejecer();
      await db.migration.onUpgrade(Migrator(db), 1, db.schemaVersion);
      await db.migration.onUpgrade(Migrator(db), 1, db.schemaVersion);

      expect(await db.columnasDe('visitadores'), contains('id_empleado'));
    });

    test('sobre una base al dia no hace nada', () async {
      await db.migration.onUpgrade(Migrator(db), 1, db.schemaVersion);
      expect(await db.columnasDe('visitadores'), contains('id_empleado'));
    });

    test('no pierde lo que el visitador ya capturo', () async {
      // Lo que se juega en una migracion mal hecha.
      await db.into(db.visitas).insert(
            VisitasCompanion.insert(
              id: 'visita-vieja',
              inicio: DateTime(2026, 9, 1, 9),
              consienteAudio: const Value(true),
              segundoConsentimiento: const Value(34),
            ),
          );
      await db.into(db.grabaciones).insert(
            GrabacionesCompanion.insert(
              id: 'grab-1',
              visitaId: 'visita-vieja',
              orden: 1,
              archivoPath: '/data/visitas/visita-vieja/tramo-1.m4a',
              inicio: DateTime(2026, 9, 1, 9, 5),
              tamanoBytes: const Value(1200000),
            ),
          );

      await envejecer();
      await db.migration.onUpgrade(Migrator(db), 1, db.schemaVersion);

      final visita = await (db.select(db.visitas)
            ..where((v) => v.id.equals('visita-vieja')))
          .getSingle();
      expect(visita.consienteAudio, isTrue);
      expect(visita.segundoConsentimiento, 34);

      final grabacion = (await db.select(db.grabaciones).get()).single;
      expect(grabacion.archivoPath, endsWith('tramo-1.m4a'));
      expect(grabacion.tamanoBytes, 1200000);
    });

    test('despues de migrar, sembrar el personal ya no falla', () async {
      // Reproduce el error exacto del telefono: el INSERT con id_empleado
      // sobre una tabla que no tenia la columna.
      await envejecer();
      await db.migration.onUpgrade(Migrator(db), 1, db.schemaVersion);
      await Semilla(db, rootBundle).sembrarSiHaceFalta();

      expect((await db.select(db.visitadores).get()).length, 18);
    });
  });

  group('la semilla se re-aplica cuando el APK trae una nueva', () {
    test('un catalogo ya sembrado se actualiza, no se queda viejo', () async {
      // Antes, el sembrador solo actuaba si la tabla estaba vacia: al
      // actualizar la app, una variable nueva no aparecia nunca.
      await db.guardarCatalogo([
        CatalogoCamposCompanion.insert(
          claveTecnica: 'motivo_llegada',
          campo: 'Motivo de llegada',
          modulo: 'Historia y origen',
          obligatorioMvp: const Value(true),
          // Como quedaria en una base vieja: sin la marca.
          noSugerir: const Value(false),
        ),
      ]);
      expect((await db.select(db.catalogoCampos).get()).length, 1);

      await Semilla(db, rootBundle).sembrarSiHaceFalta();

      expect((await db.camposActivos()).length, 55);
      final motivo = (await db.select(db.catalogoCampos).get())
          .firstWhere((c) => c.claveTecnica == 'motivo_llegada');
      expect(motivo.noSugerir, isTrue);
    });

    test('no toca las visitas ni los hallazgos', () async {
      await Semilla(db, rootBundle).sembrarSiHaceFalta();
      final repo = VisitaRepository(db);
      final vereda = (await db.select(db.veredas).get()).first;

      final id = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 8, 9),
        nombreProductor: 'Pedro Rodriguez',
        veredaLocalId: vereda.id,
      );
      await db.insertarHallazgo(
        HallazgosCompanion.insert(
          id: 'h1',
          visitaId: id,
          claveTecnica: 'nombre_productor',
          certeza: const Value(Certeza.confirmado),
          hablante: const Value(Hablante.agricultor),
          citaTextual: const Value('yo soy Pedro'),
          creadoEn: DateTime(2026, 9, 8, 9, 10),
        ),
      );

      // Volver a sembrar es lo que pasa en cada arranque de la app.
      await Semilla(db, rootBundle).sembrarSiHaceFalta();

      expect((await db.select(db.visitas).get()).length, 1);
      expect((await db.hallazgosDeVisita(id)).length, 1);
    });
  });
}
