class ApiConfig {
  // Fizyczny Android (USB): adb reverse tcp:8080 tcp:8080
  // Emulator Android: http://10.0.2.2:8080/api
  // Ta sama sieć Wi‑Fi (bez adb): http://<IP_PC>:8080/api (np. 192.168.0.101)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  // WebSocket URL dla real-time updates
  static const String webSocketUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );
}
