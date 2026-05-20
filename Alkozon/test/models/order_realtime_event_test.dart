import 'package:alkozon/features/orders_realtime/domain/entities/order_realtime_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderRealtimeEvent.tryParse', () {
    test('parses orderSubmitted payload', () {
      const body =
          '{"type":"ORDER_SUBMITTED","orderId":42,"clientOrderNumber":"A-42","status":"SUBMITTED"}';

      final event = OrderRealtimeEvent.tryParse(body);
      expect(event, isNotNull);
      expect(event!.type, OrderRealtimeEventType.orderSubmitted);
      expect(event.orderId, 42);
      expect(event.affectsStaffOrderList, isTrue);
      expect(event.shouldShowInNotificationCenter, isTrue);
    });

    test('returns null for invalid JSON', () {
      expect(OrderRealtimeEvent.tryParse('{'), isNull);
      expect(OrderRealtimeEvent.tryParse(''), isNull);
    });
  });
}
