import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirius_agro/core/api_client.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';
import 'package:sirius_agro/state/sincronizador.dart';

/// Lo que la app tiene que hacer para que la visita llegue a Airtable: armar
/// el payload desde la base local y vaciar la cola.
///
/// La cola existia desde el principio y nadie la vaciaba, asi que el audio, las
/// fotos y la visita se quedaban en el telefono. Estas pruebas son sobre eso.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VisitaRepository repo;
  late Directory temp;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
    temp = await Directory.systemTemp.createTemp('sync_test');
  });

  tearDown(() async {
    await db.close();
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  Future<String> visitaBase() async {
    final vereda = (await db.select(db.veredas).get())
        .firstWhere((v) => v.vereda == 'Guaicaramo');
    return repo.crearVisitaConProductor(
      inicio: DateTime(2026, 9, 2, 8),
      nombreProductor: 'Pedro Rodriguez',
      nombreFinca: 'La Esperanza',
      veredaLocalId: vereda.id,
    );
  }

  Future<File> archivoFalso(String nombre, {int bytes = 32}) async {
    final f = File('${temp.path}${Platform.pathSeparator}$nombre');
    await f.writeAsBytes(List.filled(bytes, 7));
    return f;
  }

  group('payload de la visita', () {
    test('lleva el codigo, el productor, la finca y la vereda', () async {
      final id = await visitaBase();
      final payload = await repo.payloadDeVisita(id);

      expect(payload['codigo_visita'], id);
      expect(payload['productor']['nombre_completo'], 'Pedro Rodriguez');
      expect(payload['finca']['nombre'], 'La Esperanza');
      expect(payload['vereda'], 'Guaicaramo');
    });

    test('lleva la transcripcion literal y la de marcas', () async {
      final id = await visitaBase();
      final archivo = await archivoFalso('tramo-1.m4a');
      final gid = await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: archivo.path,
        inicio: DateTime(2026, 9, 2, 8, 5),
        duracionSeg: 300,
      );
      await repo.guardarTranscripcion(
        grabacionId: gid,
        texto: 'Buenos dias don Pedro.',
        textoConMarcas: '[00:04] Hablante 1: Buenos dias don Pedro.',
        motor: 'scribe_v2',
      );

      final grabaciones =
          (await repo.payloadDeVisita(id))['grabaciones'] as List;

      expect(grabaciones, hasLength(1));
      expect(grabaciones.first['transcripcion'], 'Buenos dias don Pedro.');
      expect(
        grabaciones.first['transcripcion_marcas'],
        startsWith('[00:04] Hablante 1:'),
      );
    });

    test('los consentimientos viajan siempre, tambien en falso', () async {
      final id = await visitaBase();
      final payload = await repo.payloadDeVisita(id);

      expect(payload['consiente_audio'], isFalse);
      expect(payload['consiente_fotos'], isFalse);
      expect(payload['consiente_uso_datos'], isFalse);
    });

    test('sin enlace subido no inventa la clave', () async {
      final id = await visitaBase();
      final archivo = await archivoFalso('tramo-1.m4a');
      await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: archivo.path,
        inicio: DateTime(2026, 9, 2, 8, 5),
      );

      final g = ((await repo.payloadDeVisita(id))['grabaciones'] as List).first;
      expect(g.containsKey('enlace_audio'), isFalse);
    });

    test('el payload se arma aunque la visita este a medias', () async {
      // Un telefono que se moja en el potrero no puede llevarse la visita:
      // se manda lo que haya.
      final id = await repo.crearVisita(inicio: DateTime(2026, 9, 2, 8));
      final payload = await repo.payloadDeVisita(id);

      expect(payload['codigo_visita'], id);
      expect(payload.containsKey('productor'), isFalse);
      expect(payload['grabaciones'], isEmpty);
    });
  });

  group('cola de sincronizacion', () {
    test('sube el audio y guarda la URL en la grabacion', () async {
      final id = await visitaBase();
      final archivo = await archivoFalso('tramo-1.m4a');
      await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: archivo.path,
        inicio: DateTime(2026, 9, 2, 8, 5),
      );

      final api = ApiClient(
        client: MockClient((req) async {
          expect(req.url.path, '/v1/archivos');
          return http.Response(
            jsonEncode({
              'url': 'https://cdn/visitas/$id/audio/tramo-1.m4a',
              'clave': 'x',
              'bytes': 32,
            }),
            200,
          );
        }),
      );

      final completados = await Sincronizador(db, repo, api).procesar();

      expect(completados, 1);
      final g = (await repo.grabacionesDeVisita(id)).single;
      expect(g.enlaceAudio, endsWith('tramo-1.m4a'));
    });

    test('un fallo deja el motivo en la cola y no tumba nada', () async {
      final id = await visitaBase();
      final archivo = await archivoFalso('tramo-1.m4a');
      await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: archivo.path,
        inicio: DateTime(2026, 9, 2, 8, 5),
      );

      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'El bucket no esta configurado.'}),
            500,
          ),
        ),
      );

      final completados = await Sincronizador(db, repo, api).procesar();

      expect(completados, 0);
      final item = (await db.pendientesDeVisita(id)).single;
      expect(item.ultimoError, contains('bucket'));
      expect(item.intentos, 1);
      // El proximo intento queda en el futuro: reintentar cada segundo desde
      // el campo solo gasta bateria.
      expect(item.proximoIntentoEn.isAfter(DateTime.now()), isTrue);
    });

    test('el upsert marca la visita como sincronizada', () async {
      final id = await visitaBase();
      await repo.encolarVisita(id);

      final api = ApiClient(
        client: MockClient((req) async {
          expect(req.url.path, '/v1/visitas');
          return http.Response(
            jsonEncode({
              'codigo_visita': id,
              'record_id': 'recX',
              'url': 'https://airtable.com/x',
              'grabaciones': 0,
              'evidencias': 0,
              'hallazgos': 0,
            }),
            200,
          );
        }),
      );

      await Sincronizador(db, repo, api).procesar();

      final visita = (await db.select(db.visitas).get()).single;
      expect(visita.sincronizada, isTrue);
      expect(visita.sincronizadaEn, isNotNull);
    });

    test('encolar dos veces la misma visita no deja dos upserts', () async {
      // El visitador toca Sincronizar varias veces.
      final id = await visitaBase();
      await repo.encolarVisita(id);
      await repo.encolarVisita(id);

      final upserts = (await db.pendientesDeVisita(id))
          .where((i) => i.operacion == 'upsert');
      expect(upserts, hasLength(1));
    });

    test('un archivo que ya no esta en disco falla con su motivo', () async {
      final id = await visitaBase();
      final archivo = await archivoFalso('tramo-1.m4a');
      await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: archivo.path,
        inicio: DateTime(2026, 9, 2, 8, 5),
      );
      await archivo.delete();

      final api = ApiClient(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      await Sincronizador(db, repo, api).procesar();

      final item = (await db.pendientesDeVisita(id)).single;
      expect(item.ultimoError, contains('ya no esta en disco'));
    });

    test('el audio se sube antes que las fotos', () async {
      // El audio es lo unico irrecuperable de una visita.
      final id = await visitaBase();
      final audio = await archivoFalso('tramo-1.m4a');
      final foto = await archivoFalso('foto-1.jpg');

      await repo.registrarEvidencia(
        visitaId: id,
        archivoPath: foto.path,
        tomadaEn: DateTime(2026, 9, 2, 8, 3),
      );
      await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: audio.path,
        inicio: DateTime(2026, 9, 2, 8, 5),
      );

      final orden = <String>[];
      final api = ApiClient(
        client: MockClient((req) async {
          orden.add(req.url.path);
          return http.Response(
            jsonEncode({'url': 'https://cdn/x', 'clave': 'x', 'bytes': 1}),
            200,
          );
        }),
      );

      await Sincronizador(db, repo, api).procesar();

      final items = await db.proximosItems(limite: 10);
      expect(items, isEmpty, reason: 'los dos se subieron');
      expect(orden, hasLength(2));
    });
  });

  group('estado del respaldo', () {
    test('marcarSincronizada solo se pone en verdadero al confirmar', () async {
      final id = await visitaBase();
      final antes = (await db.select(db.visitas).get()).single;
      expect(antes.sincronizada, isFalse);

      await repo.marcarSincronizada(id);

      final despues = (await db.select(db.visitas).get()).single;
      expect(despues.sincronizada, isTrue);
    });
  });
}
