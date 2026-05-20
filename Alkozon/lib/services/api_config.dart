class ApiConfig {
  // Domyślnie produkcyjny backend na Render.
  // Lokalnie można nadpisać przez --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-alcozon.onrender.com/api',
  );

  // Lokalnie można nadpisać przez --dart-define=WS_URL=...
  static const String webSocketUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api-alcozon.onrender.com/ws',
  );
}
