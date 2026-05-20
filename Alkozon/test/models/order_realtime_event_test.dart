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

    test('parses deliveryAssigned with optional ids', () {
      const body =
          '{"type":"DELIVERY_ASSIGNED","orderId":7,"clientOrderNumber":"A-7","status":"assigned","deliveryId":"15","courierUserId":3}';

      final event = OrderRealtimeEvent.tryParse(body);
      expect(event, isNotNull);
      expect(event!.type, OrderRealtimeEventType.deliveryAssigned);
      expect(event.deliveryId, 15);
      expect(event.courierUserId, 3);
      expect(event.affectsCourierDeliveryList, isTrue);
      expect(event.affectsStaffOrderList, isFalse);
      expect(event.shouldShowInNotificationCenter, isTrue);
    });

    test('returns null when orderId or status is missing', () {
      expect(
        OrderRealtimeEvent.tryParse(
          '{"type":"ORDER_SUBMITTED","status":"SUBMITTED"}',
        ),
        isNull,
      );
      expect(
        OrderRealtimeEvent.tryParse(
          '{"type":"ORDER_SUBMITTED","orderId":1}',
        ),
        isNull,
      );
    });

    test('returns null for invalid JSON', () {
      expect(OrderRealtimeEvent.tryParse('{'), isNull);
      expect(OrderRealtimeEvent.tryParse(''), isNull);
      expect(OrderRealtimeEvent.tryParse(null), isNull);
    });
  });

  group('OrderRealtimeEvent flags', () {
    test('orderDelivered affects staff list but not notification center', () {
      const body =
          '{"type":"ORDER_DELIVERED","orderId":1,"clientOrderNumber":"A-1","status":"DELIVERED"}';
      final event = OrderRealtimeEvent.tryParse(body)!;

      expect(event.affectsStaffOrderList, isTrue);
      expect(event.affectsCourierDeliveryList, isTrue);
      expect(event.shouldShowInNotificationCenter, isFalse);
    });
  });
}
