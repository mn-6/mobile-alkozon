class ApiConfig {
  // APP_ENV:
  // - prod  -> Render (domyślnie)
  // - local -> localhost:8080 (pod adb reverse dla fizycznego telefonu)
  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  // Można też wymusić własny URL przez --dart-define=API_BASE_URL=...
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Można też wymusić własny WS URL przez --dart-define=WS_URL=...
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
}
