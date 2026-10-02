import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/state/asistencia.dart';
import 'package:sirius_agro/state/nota_voz.dart';

/// La nota del registro de asistencia solo se graba: no se procesa en el
/// telefono, y el audio se conserva para el registro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporal;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => temporal.path,
        );
  });

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('nota-asistencia-');
  });

  tearDown(() async {
    if (temporal.existsSync()) await temporal.delete(recursive: true);
  });

  test('al detener queda la nota en disco, lista para el registro', () async {
    final c = NotaAsistenciaController(_GrabadoraFalsa());

    await c.iniciar();
    expect(c.state.grabando, isTrue);
    await c.detener();

    expect(c.state.tieneNota, isTrue);
    expect(c.state.error, isNull);
    expect(File(c.state.path!).existsSync(), isTrue);
    c.entregada();
    c.dispose();
  });

  test('descartar borra el audio', () async {
    final c = NotaAsistenciaController(_GrabadoraFalsa());
    await c.iniciar();
    await c.detener();
    final path = c.state.path!;

    await c.descartar();

    expect(c.state.tieneNota, isFalse);
    expect(File(path).existsSync(), isFalse);
    c.dispose();
  });

  test('sin permiso de microfono lo dice', () async {
    final c = NotaAsistenciaController(_GrabadoraFalsa(permiso: false));
    await c.iniciar();
    expect(c.state.error, contains('permiso'));
    c.dispose();
  });
}

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
