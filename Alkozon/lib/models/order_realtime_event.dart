import 'dart:convert';

/// Payload zgodny z backendem: OrderRealtimeEvent.java
enum OrderRealtimeEventType {
  orderSubmitted,
  orderStatusChanged,
  dispatchPending,
  deliveryAssigned,
  orderDelivered,
  orderCancelled,
  unknown,
}

class OrderRealtimeEvent {
  const OrderRealtimeEvent({
    required this.type,
    required this.orderId,
    required this.clientOrderNumber,
    required this.status,
    this.deliveryId,
    this.courierUserId,
  });

  final OrderRealtimeEventType type;
  final int orderId;
  final String clientOrderNumber;
  final String status;
  final int? deliveryId;
  final int? courierUserId;

  static OrderRealtimeEvent? tryParse(String? rawBody) {
    if (rawBody == null || rawBody.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is! Map) {
        return null;
      }
      final json = Map<String, dynamic>.from(decoded);
      final orderId = json['orderId'];
      final status = json['status']?.toString();
      if (orderId is! num || status == null || status.isEmpty) {
        return null;
      }

      return OrderRealtimeEvent(
        type: _parseType(json['type']?.toString()),
        orderId: orderId.toInt(),
        clientOrderNumber:
            json['clientOrderNumber']?.toString() ?? orderId.toString(),
        status: status.toUpperCase(),
        deliveryId: _parseOptionalInt(json['deliveryId']),
        courierUserId: _parseOptionalInt(json['courierUserId']),
      );
    } catch (_) {
      return null;
    }
  }

  bool get affectsStaffOrderList {
    switch (type) {
      case OrderRealtimeEventType.orderSubmitted:
      case OrderRealtimeEventType.orderStatusChanged:
      case OrderRealtimeEventType.orderCancelled:
      case OrderRealtimeEventType.orderDelivered:
        return true;
      case OrderRealtimeEventType.dispatchPending:
      case OrderRealtimeEventType.deliveryAssigned:
      case OrderRealtimeEventType.unknown:
        return false;
    }
  }

  bool get affectsCourierDeliveryList {
    switch (type) {
      case OrderRealtimeEventType.deliveryAssigned:
      case OrderRealtimeEventType.orderDelivered:
        return true;
      case OrderRealtimeEventType.orderSubmitted:
      case OrderRealtimeEventType.orderStatusChanged:
      case OrderRealtimeEventType.dispatchPending:
      case OrderRealtimeEventType.orderCancelled:
      case OrderRealtimeEventType.unknown:
        return false;
    }
  }

  /// Zdarzenia pokazywane w historii powiadomień (STOMP, gdy FCM wyłączone lokalnie).
  bool get shouldShowInNotificationCenter {
    switch (type) {
      case OrderRealtimeEventType.orderSubmitted:
      case OrderRealtimeEventType.deliveryAssigned:
      case OrderRealtimeEventType.dispatchPending:
        return true;
      case OrderRealtimeEventType.orderStatusChanged:
      case OrderRealtimeEventType.orderDelivered:
      case OrderRealtimeEventType.orderCancelled:
      case OrderRealtimeEventType.unknown:
        return false;
    }
  }

  static OrderRealtimeEventType _parseType(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'ORDER_SUBMITTED':
        return OrderRealtimeEventType.orderSubmitted;
      case 'ORDER_STATUS_CHANGED':
        return OrderRealtimeEventType.orderStatusChanged;
      case 'DISPATCH_PENDING':
        return OrderRealtimeEventType.dispatchPending;
      case 'DELIVERY_ASSIGNED':
        return OrderRealtimeEventType.deliveryAssigned;
      case 'ORDER_DELIVERED':
        return OrderRealtimeEventType.orderDelivered;
      case 'ORDER_CANCELLED':
        return OrderRealtimeEventType.orderCancelled;
      default:
        return OrderRealtimeEventType.unknown;
    }
  }

  static int? _parseOptionalInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
