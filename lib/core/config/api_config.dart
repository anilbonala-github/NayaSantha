/// Backend location. Never hard-code secrets; the base URL is supplied at build
/// time via `--dart-define=API_BASE_URL=...` (Vol2 §2.2). Defaults suit local dev:
/// Android emulator reaches the host machine at 10.0.2.2.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String apiPrefix = '/api/v1';
}
