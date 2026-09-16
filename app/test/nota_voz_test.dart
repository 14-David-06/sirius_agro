import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirius_agro/core/api_client.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';
import 'package:sirius_agro/state/grabacion.dart';
import 'package:sirius_agro/state/nota_voz.dart';
import 'package:sirius_agro/state/providers.dart';

/// La nota de voz del chat que complementa la visita.
///
/// Lo que se protege es que dictar sea el mismo camino que teclear y no uno
/// paralelo: la nota se convierte en texto, el texto vuelve al campo de
/// escribir, y de ahi en adelante pasa por donde ya pasaba —con sus reglas de
/// procedencia intactas—. Una nota que se enviara sola seria un dato entrando
/// al registro sin que nadie lo haya leido.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporal;
  late AppDatabase db;
  late VisitaRepository repo;
  late String visitaId;

  // `getTemporaryDirectory` no tiene plataforma detras en un test.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => temporal.path,
    );
  });

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('nota-voz-');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
    visitaId = await repo.crearVisitaConProductor(
      inicio: DateTime(2026, 9, 15, 9),
      nombreProductor: 'Pedro Rodriguez',
      nombreFinca: 'La Esperanza',
    );
  });

  tearDown(() async {
    await db.close();
    if (temporal.existsSync()) await temporal.delete(recursive: true);
  });

  /// Escribe bytes en el archivo que le pidan, como haria el microfono.
  ///
  /// Sin esto no hay nada que probar: el controlador lee del disco, y una
  /// grabadora que no escriba haria pasar el test por el camino del error.
  final ultimaPeticion = <String, String>{};

  ProviderContainer contenedor({
    required GrabadoraNota grabadora,
    required Future<http.Response> Function(http.BaseRequest) responder,
  }) =>
      ProviderContainer(
        overrides: [
          dbProvider.overrideWithValue(db),
          // Sin esto se despertaria el grabador de la visita entero, con su
          // plugin de microfono detras, solo para preguntarle un bool.
          visitaGrabandoProvider(visitaId).overrideWithValue(false),
          grabadoraNotaProvider.overrideWithValue(grabadora),
          apiProvider.overrideWithValue(
            ApiClient(
              client: MockClient.streaming((req, _) async {
                final respuesta = await responder(req);
                return http.StreamedResponse(
                  Stream.value(respuesta.bodyBytes),
                  respuesta.statusCode,
                );
              }),
            ),
          ),
        ],
      );

  Future<http.Response> transcribeOk(http.BaseRequest req) async {
    if (req is http.MultipartRequest) {
      ultimaPeticion.addAll(req.fields);
    }
    return http.Response(
      '{"text": "El arriendo del lote son 600 mil al mes"}',
      200,
    );
  }

  group('dictar en vez de teclear', () {
    test('la nota vuelve como texto para revisar, no enviada', () async {
      final grabadora = _GrabadoraFalsa();
      final container = contenedor(
        grabadora: grabadora,
        responder: transcribeOk,
      );
      addTearDown(container.dispose);

      final ctrl = container.read(notaVozProvider(visitaId).notifier);
      await ctrl.iniciar();
      expect(container.read(notaVozProvider(visitaId)).grabando, isTrue);

      final texto = await ctrl.detenerYTranscribir();

      expect(texto, 'El arriendo del lote son 600 mil al mes');
      // Vuelve a reposo: ni grabando ni esperando al servidor.
      expect(container.read(notaVozProvider(visitaId)).ocupada, isFalse);
      expect(container.read(notaVozProvider(visitaId)).error, isNull);
    });

    test('el audio de la nota no queda en el telefono', () async {
      final grabadora = _GrabadoraFalsa();
      final container = contenedor(
        grabadora: grabadora,
        responder: transcribeOk,
      );
      addTearDown(container.dispose);

      final ctrl = container.read(notaVozProvider(visitaId).notifier);
      await ctrl.iniciar();
      await ctrl.detenerYTranscribir();

      // La procedencia de lo que entra por el chat la lleva el chat: el
      // archivo no es evidencia de nada y no tiene por que sobrevivir ni
      // ocupar una cola de subida.
      expect(File(grabadora.ultimoPath!).existsSync(), isFalse);
    });

    test('descartar no transcribe ni deja archivo', () async {
      final grabadora = _GrabadoraFalsa();
      var llamadas = 0;
      final container = contenedor(
        grabadora: grabadora,
        responder: (req) async {
          llamadas++;
          return transcribeOk(req);
        },
      );
      addTearDown(container.dispose);

      final ctrl = container.read(notaVozProvider(visitaId).notifier);
      await ctrl.iniciar();
      await ctrl.descartar();

      expect(llamadas, 0);
      expect(File(grabadora.ultimoPath!).existsSync(), isFalse);
      expect(container.read(notaVozProvider(visitaId)).ocupada, isFalse);
    });

    test('va sin diarizar y con los terminos de la visita', () async {
      ultimaPeticion.clear();
      final container = contenedor(
        grabadora: _GrabadoraFalsa(),
        responder: transcribeOk,
      );
      addTearDown(container.dispose);

      await container.read(notaVozProvider(visitaId).notifier).iniciar();
      await container
          .read(notaVozProvider(visitaId).notifier)
          .detenerYTranscribir();

      // Habla uno solo: separar voces no aporta y ensucia el texto.
      expect(ultimaPeticion['diarizar'], 'false');
      // El apellido del productor es justo lo que un motor generico escribe
      // mal, y en una nota se dictan nombres igual que en la conversacion.
      expect(ultimaPeticion['terminos'], contains('Rodriguez'));
      expect(ultimaPeticion['terminos'], contains('La Esperanza'));
    });
  });

  group('cuando no se puede', () {
    test('sin permiso de microfono no empieza', () async {
      final container = contenedor(
        grabadora: _GrabadoraFalsa(permiso: false),
        responder: transcribeOk,
      );
      addTearDown(container.dispose);

      await container.read(notaVozProvider(visitaId).notifier).iniciar();

      final estado = container.read(notaVozProvider(visitaId));
      expect(estado.grabando, isFalse);
      expect(estado.error, contains('microfono'));
    });

    test('sin señal lo dice y sugiere escribirla', () async {
      final container = contenedor(
        grabadora: _GrabadoraFalsa(),
        responder: (_) async => throw const SocketException('sin red'),
      );
      addTearDown(container.dispose);

      final ctrl = container.read(notaVozProvider(visitaId).notifier);
      await ctrl.iniciar();
      final texto = await ctrl.detenerYTranscribir();

      expect(texto, isNull);
      // El error tiene que decir que hacer, no el codigo HTTP: en campo la
      // salida es teclearlo.
      expect(container.read(notaVozProvider(visitaId)).error,
          contains('escribirla'));
    });

    test('si no se entendio nada, no devuelve texto vacio', () async {
      final container = contenedor(
        grabadora: _GrabadoraFalsa(),
        responder: (_) async => http.Response('{"text": "   "}', 200),
      );
      addTearDown(container.dispose);

      final ctrl = container.read(notaVozProvider(visitaId).notifier);
      await ctrl.iniciar();

      expect(await ctrl.detenerYTranscribir(), isNull);
      expect(container.read(notaVozProvider(visitaId)).error, isNotNull);
    });
  });
}

/// Un microfono de mentira que si escribe el archivo.
class _GrabadoraFalsa implements GrabadoraNota {
  _GrabadoraFalsa({this.permiso = true});

  final bool permiso;
  String? ultimoPath;

  @override
  Future<bool> tienePermiso() async => permiso;

  @override
  Future<void> iniciar(String path) async {
    ultimoPath = path;
    await File(path).writeAsBytes(List.filled(64, 7));
  }

  @override
  Future<String?> detener() async => ultimoPath;

  @override
  Future<void> liberar() async {}
}
