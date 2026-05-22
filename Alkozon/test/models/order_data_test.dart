import 'package:alkozon/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderItem.fromJson', () {
    test('parses numeric fields and defaults', () {
      final item = OrderItem.fromJson({
        'productId': 10,
        'productName': 'Heineken',
        'quantity': 2,
        'unitPrice': 12.5,
      });

      expect(item.productId, 10);
      expect(item.productName, 'Heineken');
      expect(item.quantity, 2);
      expect(item.unitPrice, 12.5);
    });
  });

  group('OrderData.fromJson', () {
    test('parses shop order with items and delivery details', () {
      final order = OrderData.fromJson({
        'id': 42,
        'orderNumber': 'ORD-42',
        'clientOrderNumber': 'A-42',
        'customerId': 5,
        'status': 'submitted',
        'deliveryAddress': 'ul. Testowa 1',
        'deliveryDetails': {
          'recipientName': 'Jan Kowalski',
          'city': 'Warszawa',
        },
        'totalAmount': 99.99,
        'createdAt': '2026-05-20T10:00:00.000Z',
        'items': [
          {
            'productId': 1,
            'productName': 'Piwo',
            'quantity': 1,
            'unitPrice': 9.99,
          },
        ],
      });

      expect(order.id, 42);
      expect(order.status, 'SUBMITTED');
      expect(order.deliveryDetails?.city, 'Warszawa');
      expect(order.items, hasLength(1));
      expect(order.displayNumber, 'ORD-42');
      expect(order.isCustomOrder, isFalse);
    });
  });

  group('OrderData.fromCustomJson', () {
    test('marks custom order and uses client order number', () {
      final order = OrderData.fromCustomJson({
        'id': 7,
        'clientOrderNumber': 'C-7',
        'customerId': 3,
        'status': 'DELIVERED',
        'createdAt': '2026-05-19T08:00:00.000Z',
        'updatedAt': '2026-05-19T12:00:00.000Z',
        'description': 'Whisky na zamówienie',
        'preferences': {'smokiness': 'high'},
      });

      expect(order.isCustomOrder, isTrue);
      expect(order.items, isEmpty);
      expect(order.totalAmount, 0);
      expect(order.displayNumber, 'C-7');
      expect(order.deliveredAt, isNotNull);
      expect(order.preferences?['smokiness'], 'high');
    });

    test('parses delivery from preferences.delivery', () {
      final order = OrderData.fromCustomJson({
        'id': 8,
        'customerId': 1,
        'status': 'IN_DELIVERY',
        'preferences': {
          'smokiness': 'high',
          'delivery': {
            'recipientName': 'Jan Kowalski',
            'streetAddress': 'Wrocławska 12',
            'city': 'Wrocław',
            'postalCode': '54-540',
            'country': 'Polska',
            'deliveryNotes': 'domofon 12',
          },
        },
      });

      expect(order.deliveryDetails?.city, 'Wrocław');
      expect(order.deliveryDetails?.streetAddress, 'Wrocławska 12');
      expect(order.deliveryAddress, contains('Wrocławska 12'));
      expect(order.deliveryAddress, contains('Wrocław'));
    });

    test('displayNumber falls back to id when numbers missing', () {
      final order = OrderData.fromCustomJson({
        'id': 99,
        'customerId': 1,
        'status': 'SUBMITTED',
      });

      expect(order.displayNumber, '#99');
    });
  });

  group('CourierCombinedOrders.all', () {
    test('merges lists and sorts by createdAt descending', () {
      final older = OrderData.fromJson({
        'id': 1,
        'customerId': 1,
        'status': 'SUBMITTED',
        'totalAmount': 0,
        'createdAt': '2026-05-18T10:00:00.000Z',
        'items': [],
      });
      final newer = OrderData.fromCustomJson({
        'id': 2,
        'customerId': 1,
        'status': 'SUBMITTED',
        'createdAt': '2026-05-20T10:00:00.000Z',
      });

      final combined = CourierCombinedOrders(
        shopOrders: [older],
        customOrders: [newer],
      );

      expect(combined.all.map((o) => o.id).toList(), [2, 1]);
    });
  });
}
