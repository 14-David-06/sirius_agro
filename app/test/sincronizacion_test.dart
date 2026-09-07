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

    /// Regresion de campo: en Airtable aparecian «Foto 01» a «Foto 03» con
    /// imagen y «Foto 04» a «Foto 07» sin nada, todas de la misma visita.
    ///
    /// La causa no era el bucket —las fotos estaban ahi y su URL respondia
    /// 200 sin credenciales— sino el orden de la cola: el upsert tiene
    /// prioridad 10 y las fotos 200, asi que la visita viaja a Airtable antes
    /// de que exista una sola URL de foto. Si nada vuelve a encolar el upsert,
    /// el enlace se queda guardado en el telefono para siempre.
    ///
    /// En `Evidencias` el adjunto es el UNICO lugar donde vive la foto: no hay
    /// campo de enlace del que rescatarla despues.
    test('subir una foto deja la visita encolada para que el enlace llegue',
        () async {
      final id = await visitaBase();
      final foto = await archivoFalso('foto-01.jpg');
      await repo.registrarEvidencia(
        visitaId: id,
        archivoPath: foto.path,
        tomadaEn: DateTime(2026, 9, 2, 8, 10),
      );

      // Se vacia la cola dejando SOLO la subida de la foto pendiente, que es
      // el estado en el que quedaba la visita ya sincronizada.
      await (db.delete(db.syncQueue)
            ..where((q) => q.operacion.equals('upsert')))
          .go();

      final api = ApiClient(
        client: MockClient((req) async {
          expect(req.url.path, '/v1/archivos');
          return http.Response(
            jsonEncode({
              'url': 'https://cdn/visitas/$id/fotos/foto-01.jpg',
              'clave': 'x',
              'bytes': 32,
            }),
            200,
          );
        }),
      );

      await Sincronizador(db, repo, api).procesar();

      expect(
        (await repo.evidenciasDeVisita(id)).single.enlaceArchivo,
        endsWith('foto-01.jpg'),
      );

      final pendientes = await db.pendientesDeVisita(id);
      expect(
        pendientes.where((p) => p.operacion == 'upsert').length,
        1,
        reason: 'sin un upsert nuevo, la URL de la foto no llega a Airtable',
      );
    });

    test('diez fotos dejan un solo upsert pendiente, no diez', () async {
      // Encolar de mas no puede convertirse en diez sincronizaciones completas
      // de la visita: `encolar` reemplaza por el id `upsert-<visita>`.
      final id = await visitaBase();
      for (var i = 1; i <= 10; i++) {
        final foto = await archivoFalso('foto-0$i.jpg');
        await repo.registrarEvidencia(
          visitaId: id,
          archivoPath: foto.path,
          tomadaEn: DateTime(2026, 9, 2, 8, 10 + i),
        );
      }

      final api = ApiClient(
        client: MockClient((req) async {
          if (req.url.path == '/v1/archivos') {
            return http.Response(
              jsonEncode({'url': 'https://cdn/x.jpg', 'clave': 'x', 'bytes': 32}),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'codigo_visita': id,
              'record_id': 'recV',
              'url': 'https://airtable/recV',
            }),
            200,
          );
        }),
      );

      await Sincronizador(db, repo, api).procesar();

      final upserts = (await db.pendientesDeVisita(id))
          .where((p) => p.operacion == 'upsert')
          .length;
      expect(upserts, lessThanOrEqualTo(1));
    });

    /// La otra mitad de la regresion: cuando el upsert finalmente corre, el
    /// payload tiene que llevar la URL de la foto.
    test('el payload lleva el enlace de la foto una vez subida', () async {
      final id = await visitaBase();
      final foto = await archivoFalso('foto-01.jpg');
      await repo.registrarEvidencia(
        visitaId: id,
        archivoPath: foto.path,
        tomadaEn: DateTime(2026, 9, 2, 8, 10),
      );

      Map<String, dynamic>? enviado;
      final api = ApiClient(
        client: MockClient((req) async {
          if (req.url.path == '/v1/archivos') {
            return http.Response(
              jsonEncode({
                'url': 'https://cdn/visitas/$id/fotos/foto-01.jpg',
                'clave': 'x',
                'bytes': 32,
              }),
              200,
            );
          }
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'codigo_visita': id,
              'record_id': 'recV',
              'url': 'https://airtable/recV',
            }),
            200,
          );
        }),
      );

      final sinc = Sincronizador(db, repo, api);
      // Dos vueltas: la primera sube la foto y deja el upsert encolado; la
      // segunda es la que manda la visita. Es exactamente lo que pasa en campo.
      await sinc.procesar();
      await sinc.procesar();

      final evidencias = (enviado?['evidencias'] as List?) ?? const [];
      expect(evidencias, hasLength(1));
      expect(
        (evidencias.single as Map<String, dynamic>)['enlace_archivo'],
        endsWith('foto-01.jpg'),
      );
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

      // El nombre del archivo viaja en el cuerpo multipart, y es lo unico que
      // distingue una subida de otra: las dos van al mismo `/v1/archivos`.
      // Antes se guardaba solo la ruta de la URL, asi que esta prueba llevaba
      // el nombre de un orden que en realidad no comprobaba.
      final orden = <String>[];
      final api = ApiClient(
        client: MockClient((req) async {
          if (req.body.contains('tramo-1.m4a')) orden.add('audio');
          if (req.body.contains('foto-1.jpg')) orden.add('foto');
          return http.Response(
            jsonEncode({'url': 'https://cdn/x', 'clave': 'x', 'bytes': 1}),
            200,
          );
        }),
      );

      await Sincronizador(db, repo, api).procesar();

      expect(orden, ['audio', 'foto']);

      // Lo que queda en la cola es el upsert, no una subida: las dos se
      // hicieron. Ese upsert es el que lleva los enlaces recien guardados a
      // Airtable — sin el, la foto queda en el bucket y la evidencia en
      // Airtable sin imagen.
      final items = await db.proximosItems(limite: 10);
      expect(items.map((i) => i.operacion), ['upsert']);
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
