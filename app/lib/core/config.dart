/// Configuracion inyectada en tiempo de compilacion:
///   flutter run --dart-define=API_BASE_URL=https://... --dart-define=API_KEY=...
class AppConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const apiKey = String.fromEnvironment('API_KEY');

  static bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;
}
