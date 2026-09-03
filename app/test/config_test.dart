import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/config.dart';

/// La configuracion de compilacion.
///
/// Se fija al compilar y no se puede cambiar despues. Un APK mal compilado que
/// no lo dice se descubre en una finca, a una hora del pueblo, cuando ya se
/// grabo la conversacion y nada sube.
void main() {
  test('sin --dart-define el APK se delata en vez de fallar callado', () {
    // Asi corren los tests: sin dart-defines, o sea como un APK compilado mal.
    expect(AppConfig.isConfigured, isFalse);

    final problema = AppConfig.problemaDeCompilacion;
    expect(problema, isNotNull);
    // Y dice QUE hacer, no solo que algo esta mal.
    expect(problema, contains('API_KEY'));
  });

  test('el default es localhost, que sirve para desarrollar y no para repartir',
      () {
    expect(AppConfig.baseUrl, 'http://localhost:8000');
  });
}
