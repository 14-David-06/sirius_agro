import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirius_agro/core/api_client.dart';
import 'package:sirius_agro/data/asistencia_repository.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/visita_repository.dart';
import 'package:sirius_agro/state/sincronizador.dart';

/// En el campo solo se guardan la nota y la firma; los datos de la persona
/// llegan del backend cuando el registro sube.
void main() {
  late AppDatabase db;
  late AsistenciaRepository repo;
  late Directory temp;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AsistenciaRepository(db);
    temp = await Directory.systemTemp.createTemp('asistencia_test');
  });

  tearDown(() async {
    await db.close();
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  final png = Uint8List.fromList(List.filled(40, 1));

  Future<String> registrar() async {
    final f = File('${temp.path}${Platform.pathSeparator}tmp-nota.m4a');
    await f.writeAsBytes(List.filled(64, 9));
    return repo.registrar(
      notaVozTemporal: f.path,
      duracionNotaSeg: 42,
      firmaPng: png,
      evento: 'Taller de bioinsumos',
      visitadorIdEmpleado: 'SIRIUS-PER-0001',
      visitadorNombre: 'Ana',
      ahora: DateTime(2026, 10, 2, 9, 30),
      carpetaBase: temp,
    );
  }

  group('registrar sin red', () {
    test('guarda nota y firma, sin datos de la persona, y encola', () async {
      final id = await registrar();
      final a = await repo.asistencia(id);

      expect(a.nombreCompleto, isNull);
      expect(a.cedula, isNull);
      expect(a.procesado, isFalse);
      expect(a.aceptaTerminos, isTrue);
      expect(a.terminosUrl, terminosAsistenciaUrl);
      expect(File(a.firmaPath).existsSync(), isTrue);
      expect(File(a.notaVozPath!).existsSync(), isTrue);
      expect(a.notaVozPath, contains(id));
      expect(a.duracionNotaSeg, 42);
      // El temporal de la grabadora ya no esta: la nota vive con el registro.
      expect(
        File('${temp.path}${Platform.pathSeparator}tmp-nota.m4a').existsSync(),
        isFalse,
      );

      final cola = await repo.pendientes();
      expect(cola.single.operacion, 'upsert_asistencia');
      expect(cola.single.entidadId, id);
    });

    test('sin la nota en disco no se registra', () async {
      expect(
        () => repo.registrar(
          notaVozTemporal: '${temp.path}/no-existe.m4a',
          duracionNotaSeg: 1,
          firmaPng: png,
          evento: null,
          carpetaBase: temp,
        ),
        throwsStateError,
      );
    });

    test('el siguiente registro propone el ultimo evento', () async {
      await registrar();
      expect(await repo.ultimoEvento(), 'Taller de bioinsumos');
    });
  });

  group('subida', () {
    test('manda nota, firma y contexto, y guarda lo que saco el backend', () async {
      await db.into(db.veredas).insert(
            VeredasCompanion.insert(
              id: 'ver-1',
              vereda: 'Guaicaramo',
              municipio: 'Barranca de Upia',
            ),
          );
      final id = await registrar();
      late String cuerpo;
      final api = ApiClient(
        client: MockClient((req) async {
          expect(req.url.path, '/v1/asistencias');
          cuerpo = req.body;
          return http.Response(
            jsonEncode({
              'record_id': 'recAsis',
              'creado': true,
              'procesado': true,
              'enlace_firma': 'https://cdn/asistencias/$id/firma.png',
              'enlace_nota_voz': 'https://cdn/asistencias/$id/nota-voz.m4a',
              'transcripcion': 'Me llamo Maria Lopez...',
              'datos': {
                'nombre_completo': 'Maria Lopez',
                'cedula': '1234567',
                'telefono': '3001234567',
                'vereda': 'Guaicaramo',
                'cultivos': ['Cafe', 'Platano'],
                'area_sembrada_ha': 3.5,
                'quiere_visita': true,
                'por_confirmar': [],
              },
            }),
            200,
          );
        }),
      );

      final subidos = await Sincronizador(
        db,
        VisitaRepository(db),
        api,
      ).procesar(entidad: entidadAsistencia);

      expect(subidos, 1);
      expect(cuerpo, contains('name="datos"'));
      expect(cuerpo, contains('name="firma"'));
      expect(cuerpo, contains('name="nota_voz"'));
      expect(cuerpo, contains('"codigo_registro":"$id"'));
      // Los datos de la persona no salen del telefono: estan en el audio.
      expect(cuerpo, isNot(contains('nombre_completo')));

      final a = await repo.asistencia(id);
      expect(a.procesado, isTrue);
      expect(a.remoteId, 'recAsis');
      expect(a.nombreCompleto, 'Maria Lopez');
      expect(a.cedula, '1234567');
      expect(a.cultivos, 'Cafe\nPlatano');
      expect(a.veredaLocalId, 'ver-1');
      expect(a.areaSembradaHa, 3.5);
      expect(a.quiereVisita, isTrue);
      expect(await repo.pendientes(), isEmpty);
    });

    test('si el backend no pudo procesar, queda en la cola con el motivo', () async {
      final id = await registrar();
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'detail':
                  'La asistencia quedo guardada pero sin procesar: Claude no responde',
            }),
            502,
          ),
        ),
      );

      await Sincronizador(
        db,
        VisitaRepository(db),
        api,
      ).procesar(entidad: entidadAsistencia);

      final item = (await repo.pendientes()).single;
      expect(item.estado, EstadoSync.fallida);
      expect(item.ultimoError, contains('sin procesar'));
      expect((await repo.asistencia(id)).procesado, isFalse);
    });

    test('sin red queda en la cola con el motivo', () async {
      await registrar();
      final api = ApiClient(
        client: MockClient((_) async => throw const SocketException('sin red')),
      );

      await Sincronizador(
        db,
        VisitaRepository(db),
        api,
      ).procesar(entidad: entidadAsistencia);

      final item = (await repo.pendientes()).single;
      expect(item.estado, EstadoSync.fallida);
      expect(item.ultimoError, contains('sin red'));
    });

    test('subir asistencias no arrastra la cola de las visitas', () async {
      await db.encolar(
        id: 'upsert-v1',
        entidad: 'visita',
        entidadId: 'v1',
        operacion: 'upsert',
      );
      final pedidas = <String>[];
      final api = ApiClient(
        client: MockClient((req) async {
          pedidas.add(req.url.path);
          return http.Response(jsonEncode({'record_id': 'r'}), 200);
        }),
      );

      await Sincronizador(
        db,
        VisitaRepository(db),
        api,
      ).procesar(entidad: entidadAsistencia);

      expect(pedidas, isEmpty);
    });
  });
}
