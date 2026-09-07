import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirius_agro/core/api_client.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El directorio de agricultores ya registrados.
///
/// Existe por una sola razon: en la vereda, «Pedro Gomez», «pedro gomez» y
/// «don Pedro» son la misma persona, y sin una lista contra la cual
/// reconocerlo cada visita creaba un productor nuevo —con su propia finca y
/// sin la historia de las visitas anteriores.
///
/// La regla que ningun test de aca puede dejar pasar: el directorio es una
/// AYUDA. Sin senal, sin servidor o sin la llave del APK, el visitador tiene
/// que poder escribir el nombre y registrar la visita igual. Una finca no
/// deja de existir porque el telefono no tenga cobertura.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VisitaRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
  });

  tearDown(() async => db.close());

  Map<String, dynamic> remoto({
    String id = 'recPEDRO',
    String nombre = 'Pedro Gomez Ruiz',
    String? documento = '1090123456',
    String? telefono = '3001234567',
    String? codigo = 'BU-0007',
    bool consentimiento = false,
    String? foto,
  }) =>
      {
        'id': id,
        'nombre_completo': nombre,
        'documento': documento,
        'tipo_documento': documento == null ? null : 'CC',
        'telefono': telefono,
        'codigo_productor': codigo,
        'consentimiento_datos': consentimiento,
        'foto_url': foto,
      };

  Future<Productor> unico() async =>
      (await db.select(db.productores).get()).single;

  group('buscar sin red', () {
    test('encuentra por apellido, sin tildes y sin mayusculas', () async {
      await repo.refrescarDirectorioProductores([
        remoto(nombre: 'José Gómez Ruiz'),
      ]);

      // Asi se busca en campo: se oyo el apellido, no el nombre completo.
      final r = await repo.buscarProductores('gomez');

      expect(r.single.nombreCompleto, 'José Gómez Ruiz');
    });

    test('la ñ no se toca: Muñoz no es Munoz', () async {
      // Quitarle la tilde a la ñ fusionaria dos apellidos que conviven en la
      // misma vereda.
      expect(normalizarBusqueda('Muñoz'), 'muñoz');
      expect(normalizarBusqueda('  José   PÉREZ '), 'jose perez');
    });

    test('todas las palabras tienen que aparecer, en cualquier orden', () async {
      await repo.refrescarDirectorioProductores([
        remoto(id: 'r1', nombre: 'Pedro Gomez', documento: '1'),
        remoto(id: 'r2', nombre: 'Pedro Diaz', documento: '2'),
      ]);

      final r = await repo.buscarProductores('gomez pedro');

      expect(r.single.nombreCompleto, 'Pedro Gomez');
    });

    test('tambien busca por documento', () async {
      // Es lo que se hace cuando el nombre esta escrito de tres maneras.
      await repo.refrescarDirectorioProductores([remoto()]);

      final r = await repo.buscarProductores('1090123456');

      expect(r.single.documento, '1090123456');
    });

    test('una sola letra o texto vacio no devuelve nada', () async {
      await repo.refrescarDirectorioProductores([remoto()]);

      expect(await repo.buscarProductores(''), isEmpty);
      expect(await repo.buscarProductores('   '), isEmpty);
    });

    test('el espejo local responde aunque el backend no exista', () async {
      // No hay ApiClient en este test a proposito: buscar no habla con la red.
      await repo.refrescarDirectorioProductores([remoto()]);

      expect(await repo.buscarProductores('pedro'), hasLength(1));
      expect(await repo.cuantosProductoresConocidos(), 1);
    });
  });

  group('refrescar el espejo', () {
    test('reconoce a la misma persona por su record id', () async {
      await repo.refrescarDirectorioProductores([remoto()]);
      await repo.refrescarDirectorioProductores([
        remoto(nombre: 'Pedro Gomez Ruiz (corregido)'),
      ]);

      final p = await unico();
      // El nombre canonico de Airtable manda cuando la llave es fuerte.
      expect(p.nombreCompleto, 'Pedro Gomez Ruiz (corregido)');
      expect(p.remoteId, 'recPEDRO');
    });

    test('reconoce por documento a quien se creo en una visita', () async {
      final visita = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 7, 8),
        nombreProductor: 'don Pedro',
      );
      await repo.guardarDatosAgricultor(
        visitaId: visita,
        documento: '1090123456',
        tipoDocumento: 'CC',
      );

      await repo.refrescarDirectorioProductores([remoto()]);

      expect(await db.select(db.productores).get(), hasLength(1));
      final p = await unico();
      expect(p.remoteId, 'recPEDRO');
      expect(p.codigoProductor, 'BU-0007');
      // La visita sigue colgando de la misma ficha, no de una nueva.
      final v = await (db.select(db.visitas)
            ..where((t) => t.id.equals(visita)))
          .getSingle();
      expect(v.productorLocalId, p.id);
    });

    test('dos homonimos con documentos distintos NO se funden', () async {
      // Es la razon de ser del documento: fundirlos les mezclaria las fincas.
      await repo.refrescarDirectorioProductores([
        remoto(id: 'r1', nombre: 'Pedro Gomez', documento: '111'),
        remoto(id: 'r2', nombre: 'Pedro Gomez', documento: '222'),
      ]);

      expect(await db.select(db.productores).get(), hasLength(2));
    });

    test('lo que el visitador tecleo en la finca no se pisa', () async {
      final visita = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 7, 8),
        nombreProductor: 'Pedro Gomez Ruiz',
      );
      // El telefono tiene un numero mas nuevo que el de Airtable y todavia no
      // lo ha subido: el directorio no puede borrarlo.
      await repo.guardarDatosAgricultor(
        visitaId: visita,
        telefono: '3109999999',
      );

      await repo.refrescarDirectorioProductores([remoto()]);

      final p = await unico();
      expect(p.telefono, '3109999999');
      // Y lo que faltaba si se llena.
      expect(p.documento, '1090123456');
    });

    test('la autorizacion se prende, nunca se apaga', () async {
      await repo.refrescarDirectorioProductores([
        remoto(consentimiento: true),
      ]);
      expect((await unico()).consentimientoDatos, isTrue);

      // Una sincronizacion posterior sin el dato no puede borrar un permiso
      // que la persona dio delante de alguien.
      await repo.refrescarDirectorioProductores([remoto()]);
      expect((await unico()).consentimientoDatos, isTrue);
    });

    test('la miniatura se reemplaza: las URL de Airtable caducan', () async {
      await repo.refrescarDirectorioProductores([
        remoto(foto: 'https://airtable/vieja.jpg'),
      ]);
      await repo.refrescarDirectorioProductores([
        remoto(foto: 'https://airtable/nueva.jpg'),
      ]);

      expect((await unico()).fotoRemota, 'https://airtable/nueva.jpg');
    });

    test('una ficha sin nombre o sin id se ignora', () async {
      final tocados = await repo.refrescarDirectorioProductores([
        {'id': 'recX', 'nombre_completo': '  '},
        {'nombre_completo': 'Sin record id'},
      ]);

      expect(tocados, 0);
      expect(await db.select(db.productores).get(), isEmpty);
    });
  });

  group('crear la visita', () {
    test('reconocido: se cuelga de la ficha y es un seguimiento', () async {
      await repo.refrescarDirectorioProductores([remoto()]);
      final p = await unico();

      final visita = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 7, 8),
        nombreProductor: p.nombreCompleto,
        productorLocalId: p.id,
        nombreFinca: 'La Esperanza',
      );

      // Ni un productor de mas: es la segunda visita de la misma persona.
      expect(await db.select(db.productores).get(), hasLength(1));
      final v = await (db.select(db.visitas)
            ..where((t) => t.id.equals(visita)))
          .getSingle();
      expect(v.productorLocalId, p.id);
      expect(v.tipoVisita, 'Seguimiento');
    });

    test('sin reconocer: crea la persona y es primera visita', () async {
      final visita = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 7, 8),
        nombreProductor: 'Alguien que nadie ha visitado',
      );

      final v = await (db.select(db.visitas)
            ..where((t) => t.id.equals(visita)))
          .getSingle();
      expect(v.tipoVisita, 'Primera visita');
      expect((await unico()).remoteId, isNull);
    });

    test('un id que ya no existe no impide registrar la visita', () async {
      // La ficha se borro entre que se eligio y se toco el boton. Quedarse sin
      // poder registrar seria peor que un duplicado.
      final visita = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 7, 8),
        nombreProductor: 'Pedro Gomez',
        productorLocalId: 'un-id-que-no-existe',
      );

      final v = await (db.select(db.visitas)
            ..where((t) => t.id.equals(visita)))
          .getSingle();
      expect(v.productorLocalId, isNotNull);
      expect(v.tipoVisita, 'Primera visita');
    });
  });

  group('el cliente del directorio', () {
    test('lee la lista que devuelve el backend', () async {
      final api = ApiClient(
        client: MockClient((r) async {
          expect(r.url.path, '/v1/productores');
          return http.Response(
            jsonEncode({
              'productores': [remoto()],
              'truncado': false,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final lista = await api.productoresRegistrados();

      expect(lista.single['nombre_completo'], 'Pedro Gomez Ruiz');
    });

    test('manda el termino de busqueda cuando se le da uno', () async {
      final api = ApiClient(
        client: MockClient((r) async {
          expect(r.url.queryParameters['buscar'], 'gomez');
          return http.Response(
            jsonEncode({'productores': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      expect(await api.productoresRegistrados(buscar: '  gomez '), isEmpty);
    });

    test('un servidor caido explota aca, no en la pantalla', () async {
      // La pantalla atrapa esto y sigue con el espejo local: el contrato es
      // que el metodo falle rapido y claro, no que devuelva una lista vacia
      // que se veria igual que "no hay nadie registrado".
      final api = ApiClient(
        client: MockClient((_) async => http.Response('{"detail":"caido"}', 502)),
      );

      expect(
        () => api.productoresRegistrados(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('sin red no se detiene el registro', () {
    test('el espejo vacio deja crear productor y visita', () async {
      // El caso de una vereda sin cobertura y un telefono recien instalado:
      // no hay directorio, no hay sugerencias, y la visita tiene que salir.
      expect(await repo.cuantosProductoresConocidos(), 0);
      expect(await repo.buscarProductores('pedro'), isEmpty);

      final vereda = (await db.select(db.veredas).get()).first;
      final visita = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 7, 8),
        nombreProductor: 'Pedro Gomez',
        nombreFinca: 'La Esperanza',
        veredaLocalId: vereda.id,
      );

      final v = await (db.select(db.visitas)
            ..where((t) => t.id.equals(visita)))
          .getSingle();
      expect(v.productorLocalId, isNotNull);
      expect(v.fincaLocalId, isNotNull);
    });

    test('el productor local sigue subiendo con la visita', () async {
      // Que la ficha venga del directorio no la exime de sincronizar: el
      // telefono pudo agregarle el documento que Airtable no tenia.
      await repo.refrescarDirectorioProductores([
        remoto(documento: null, telefono: null),
      ]);
      final p = await unico();
      final visita = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 7, 8),
        nombreProductor: p.nombreCompleto,
        productorLocalId: p.id,
      );
      await repo.guardarDatosAgricultor(
        visitaId: visita,
        documento: '1090123456',
        tipoDocumento: 'CC',
      );

      final payload = await repo.payloadDeVisita(visita);

      expect(payload['productor'], isNotNull);
      expect((payload['productor'] as Map)['documento'], '1090123456');
      expect((payload['productor'] as Map)['codigo_productor'], 'BU-0007');
    });
  });
}
