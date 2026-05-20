import 'package:alkozon/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig', () {
    test('default environment uses production API and WSS', () {
      expect(ApiConfig.baseUrl, contains('api-alcozon'));
      expect(ApiConfig.webSocketUrl, startsWith('wss://'));
      expect(ApiConfig.isProduction, isTrue);
      expect(ApiConfig.requiresHttps, isTrue);
    });
  });
}
