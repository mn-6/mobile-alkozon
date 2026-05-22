import 'package:alkozon/features/orders/presentation/utils/custom_order_preferences_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomOrderPreferencesFormatter', () {
    test('formats nested delivery and skips clientOrderNumber', () {
      final rows = CustomOrderPreferencesFormatter.displayRows({
        'clientOrderNumber': '123456',
        'smokiness': 'high',
        'delivery': {
          'streetAddress': 'Wrocławska 12',
          'city': 'Wrocław',
        },
        'mix': {
          'wheat': 40,
          'rye': 60,
        },
      });

      expect(rows.any((r) => r.key == 'Numer klienta'), isFalse);
      expect(rows.any((r) => r.key == 'Intensywność dymu' && r.value == 'high'),
          isTrue);
      expect(
        rows.any((r) => r.key == 'Dostawa' && r.value.contains('Wrocławska 12')),
        isTrue,
      );
      expect(
        rows.any((r) => r.key == 'Mix' && r.value.contains('40')),
        isTrue,
      );
    });
  });
}
