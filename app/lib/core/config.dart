/// Configuracion inyectada en tiempo de compilacion:
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://... \
///     --dart-define=API_KEY=...
///
/// Se fija al COMPILAR, no en tiempo de ejecucion: cambiarla exige reinstalar
/// el APK, no basta con reabrir la app.
class AppConfig {
  /// Por defecto apunta al PC por `adb reverse`, que es lo que sirve para
  /// desarrollar. En un APK que se reparte esto es un error, y por eso
  /// [problemaDeCompilacion] lo dice en voz alta en vez de dejar que el
  /// visitador descubra en una finca que nada sincroniza.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const apiKey = String.fromEnvironment('API_KEY');

  static const _porDefecto = 'http://localhost:8000';

  static bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;

  /// Que esta mal en como se compilo este APK, o null si esta bien.
  ///
  /// Se revisa contra `kReleaseMode` en la UI: en debug apuntar a localhost es
  /// lo correcto y no hay que molestar con avisos.
  static String? get problemaDeCompilacion {
    if (apiKey.isEmpty) {
      return 'Este APK se compilo sin --dart-define=API_KEY. El servidor va a '
          'rechazar todo con 401. Hay que compilarlo de nuevo e instalarlo: '
          'la llave se fija al compilar.';
    }
    if (baseUrl == _porDefecto) {
      return 'Este APK apunta a localhost, que desde el celular no existe. Se '
          'compilo sin --dart-define=API_BASE_URL. Nada va a sincronizar.';
    }
    if (!baseUrl.startsWith('https://')) {
      return 'Este APK apunta a $baseUrl, sin HTTPS. En release Android bloquea '
          'el trafico en claro: no va a poder hablar con el servidor.';
    }
    return null;
  }
}
