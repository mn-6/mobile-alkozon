class ApiConfig {
  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _wsUrlOverride = String.fromEnvironment(
    'WS_URL',
    defaultValue: '',
  );

  static const String baseUrl =
      _apiBaseUrlOverride != ''
          ? _apiBaseUrlOverride
          : (_appEnv == 'local'
              ? 'http://localhost:8080/api'
              : 'https://api-alcozon.onrender.com/api');

  static const String webSocketUrl =
      _wsUrlOverride != ''
          ? _wsUrlOverride
          : (_appEnv == 'local'
              ? 'ws://localhost:8080/ws'
              : 'wss://api-alcozon.onrender.com/ws');

  static bool get isLocal =>
      _apiBaseUrlOverride.isEmpty && _appEnv == 'local';

  static bool get isProduction => !isLocal;

  static bool get requiresHttps => isProduction;
}
