import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/order_realtime_event.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// STOMP WebSocket — zgodnie z backendem (OrderRealtimeDestinations).
class OrderRealtimeService extends ChangeNotifier {
  OrderRealtimeService._internal();

  static final OrderRealtimeService instance = OrderRealtimeService._internal();

  static const String staffTopic = '/topic/orders/staff';
  static const String courierQueue = '/user/queue/courier-deliveries';

  StompClient? _client;
  StompUnsubscribe? _staffSubscription;
  StompUnsubscribe? _courierSubscription;
  bool _subscribeCourier = false;
  bool _isConnected = false;

  final Set<VoidCallback> _orderReloadListeners = {};

  bool get isConnected => _isConnected;

  void addOrderReloadListener(VoidCallback listener) {
    _orderReloadListeners.add(listener);
  }

  void removeOrderReloadListener(VoidCallback listener) {
    _orderReloadListeners.remove(listener);
  }

  Future<void> connectForCurrentUser({AuthService? authService}) async {
    final auth = authService ?? AuthService();
    final token = await auth.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final profile = await auth.getCurrentUserProfile();
    final role = (profile?.role ?? '').trim().toUpperCase();
    final isStaff = role == 'EMPLOYEE' || role == 'MANAGER';
    if (!isStaff) {
      return;
    }

    await connect(
      accessToken: token,
      subscribeCourier: profile?.courier ?? false,
    );
  }

  Future<void> connect({
    required String accessToken,
    required bool subscribeCourier,
  }) async {
    await disconnect();

    _subscribeCourier = subscribeCourier;
    final client = StompClient(
      config: StompConfig(
        url: ApiConfig.webSocketUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        stompConnectHeaders: {
          'Authorization': 'Bearer $accessToken',
        },
        onConnect: _onStompConnect,
        onDisconnect: _onStompDisconnect,
        onStompError: (frame) {
          debugPrint(
            'STOMP error: ${frame.headers['message'] ?? frame.body ?? 'unknown'}',
          );
        },
        onWebSocketError: (error) {
          debugPrint('WebSocket error: $error');
        },
        onDebugMessage: (message) {
          if (kDebugMode) {
            debugPrint(message);
          }
        },
      ),
    );

    _client = client;
    client.activate();
  }

  Future<void> disconnect() async {
    _staffSubscription?.call();
    _courierSubscription?.call();
    _staffSubscription = null;
    _courierSubscription = null;

    _client?.deactivate();
    _client = null;
    _subscribeCourier = false;

    if (_isConnected) {
      _isConnected = false;
      notifyListeners();
    }
  }

  void _onStompConnect(StompFrame frame) {
    final client = _client;
    if (client == null) {
      return;
    }

    _staffSubscription = client.subscribe(
      destination: staffTopic,
      callback: _onStaffMessage,
    );

    if (_subscribeCourier) {
      _courierSubscription = client.subscribe(
        destination: courierQueue,
        callback: _onCourierMessage,
      );
    }

    _isConnected = true;
    notifyListeners();
    debugPrint('STOMP connected (${ApiConfig.webSocketUrl})');
  }

  void _onStompDisconnect(StompFrame frame) {
    _isConnected = false;
    notifyListeners();
    debugPrint('STOMP disconnected');
  }

  void _onStaffMessage(StompFrame frame) {
    final event = OrderRealtimeEvent.tryParse(frame.body);
    if (event == null) {
      return;
    }
    unawaited(
      NotificationService.instance.ingestRealtimeEvent(
        event,
        showForegroundBanner: true,
      ),
    );
    if (event.affectsStaffOrderList) {
      _notifyOrderReload(event);
    }
  }

  void _onCourierMessage(StompFrame frame) {
    final event = OrderRealtimeEvent.tryParse(frame.body);
    if (event == null) {
      return;
    }
    unawaited(
      NotificationService.instance.ingestRealtimeEvent(
        event,
        showForegroundBanner: true,
      ),
    );
    if (event.affectsCourierDeliveryList) {
      _notifyOrderReload(event);
    }
  }

  void _notifyOrderReload(OrderRealtimeEvent event) {
    debugPrint(
      'STOMP ${event.type.name} order=${event.orderId} status=${event.status}',
    );
    for (final listener in List<VoidCallback>.from(_orderReloadListeners)) {
      listener();
    }
    notifyListeners();
  }
}
