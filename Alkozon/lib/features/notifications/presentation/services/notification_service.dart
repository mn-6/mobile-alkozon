import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../orders/presentation/pages/order_page.dart';
import '../../../orders_realtime/domain/entities/order_realtime_event.dart';

enum AppNotificationType { newOrder, deliveryAssignment, unknown }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.orderId,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final int? orderId;

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    int? orderId,
    bool clearOrderId = false,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      orderId: clearOrderId ? null : (orderId ?? this.orderId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'orderId': orderId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').trim();
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: AppNotificationType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => AppNotificationType.unknown,
      ),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      orderId: _parseInt(json['orderId']),
    );
  }

  static AppNotification? fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final title =
        (message.notification?.title ?? data['title'] ?? '').toString().trim();
    final body =
        (message.notification?.body ?? data['body'] ?? '').toString().trim();
    final orderId = _parseInt(
      data['orderId'] ?? data['order_id'] ?? data['entityId'] ?? data['id'],
    );
    final type = _resolveType(
      data['type']?.toString(),
      title: title,
      body: body,
    );

    if (title.isEmpty && body.isEmpty && orderId == null) {
      return null;
    }

    final normalizedTitle = title.isNotEmpty ? title : _defaultTitle(type);
    final normalizedBody = body.isNotEmpty ? body : _defaultBody(type);
    final createdAt = DateTime.now();

    return AppNotification(
      id:
          message.messageId ??
          '${type.name}-${orderId ?? 'general'}-${createdAt.millisecondsSinceEpoch}',
      type: type,
      title: normalizedTitle,
      body: normalizedBody,
      createdAt: createdAt,
      isRead: false,
      orderId: orderId,
    );
  }

  static AppNotificationType _resolveType(
    String? rawType, {
    required String title,
    required String body,
  }) {
    final normalized = (rawType ?? '').trim().toUpperCase();
    if ({
      'NEW_ORDER',
      'ORDER_CREATED',
      'ORDER_SUBMITTED',
      'NEWORDER',
      'ORDER_NEW',
    }.contains(normalized)) {
      return AppNotificationType.newOrder;
    }
    if ({
      'DELIVERY_ASSIGNED',
      'ORDER_ASSIGNED',
      'NEW_DELIVERY',
      'ASSIGNMENT',
      'IN_DELIVERY_ASSIGNED',
    }.contains(normalized)) {
      return AppNotificationType.deliveryAssignment;
    }

    final haystack = '$title $body'.toLowerCase();
    if (haystack.contains('nowe zam') || haystack.contains('wpłynęło nowe')) {
      return AppNotificationType.newOrder;
    }
    if (haystack.contains('wysyłk') || haystack.contains('dostaw')) {
      return AppNotificationType.deliveryAssignment;
    }
    return AppNotificationType.unknown;
  }

  static String _defaultTitle(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newOrder:
        return 'Wpłynęło nowe zamówienie!';
      case AppNotificationType.deliveryAssignment:
        return 'Nowa wysyłka czeka!';
      case AppNotificationType.unknown:
        return 'Nowe powiadomienie';
    }
  }

  static String _defaultBody(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newOrder:
        return 'Sprawdź szczegóły nowego zamówienia.';
      case AppNotificationType.deliveryAssignment:
        return 'Masz nowe przypisane zamówienie do dostawy.';
      case AppNotificationType.unknown:
        return 'Otwórz aplikację, aby zobaczyć szczegóły.';
    }
  }
}

int? _parseInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  final ready = await NotificationService.ensureFirebaseInitialized();
  if (!ready) {
    return;
  }

  await NotificationService.persistRemoteMessage(message);
}

class NotificationService extends ChangeNotifier {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  static const String _apiUrl = ApiConfig.baseUrl;
  static const String _notificationsStorageKey = 'app_notifications_v1';
  static const String _pendingOpenKey = 'pending_notification_open_v1';
  static const String _tokenRegisterPath = String.fromEnvironment(
    'FCM_TOKEN_REGISTER_PATH',
    defaultValue: '/devices/fcm',
  );

  static const AndroidNotificationChannel _ordersChannel =
      AndroidNotificationChannel(
        'orders_push',
        'Powiadomienia zamówień',
        description: 'Nowe zamówienia i przypisania dostaw.',
        importance: Importance.max,
      );

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  AuthRepository get _authRepository => InjectionContainer.I.authRepository;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _firebaseReady = false;
  final List<AppNotification> _notifications = [];

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageTapSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((item) => !item.isRead).length;
  bool get isPushConfigured => true;
  bool get isPushActive => _firebaseReady;

  static Future<bool> ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }

    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _loadPersistedNotifications();
    await _initializeLocalNotifications();

    final ready = await ensureFirebaseInitialized();
    if (!ready) {
      notifyListeners();
      return;
    }

    _firebaseReady = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _ensureAndroidNotificationChannel();
    await _requestNotificationPermissions();
    await _restoreLaunchNotification();

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((message) async {
      final notification = await ingestRemoteMessage(
        message,
        showForegroundBanner: true,
      );
      if (notification != null) {
        notifyListeners();
      }
    });

    _messageTapSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      final notification = await ingestRemoteMessage(message);
      if (notification != null) {
        await openNotification(notification.id);
      }
    });

    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      await _syncMessagingToken();
    });

    if (await _authRepository.isAuthenticated()) {
      await onAuthenticated();
    }

    notifyListeners();
  }

  Future<void> onAuthenticated() async {
    if (!_firebaseReady) {
      return;
    }

    await _syncMessagingToken();
  }

  Future<void> processPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingId = prefs.getString(_pendingOpenKey);
    if (pendingId == null || pendingId.isEmpty) {
      return;
    }

    if (!await _authRepository.isAuthenticated()) {
      return;
    }

    await prefs.remove(_pendingOpenKey);
    await Future<void>.delayed(Duration.zero);
    await openNotification(pendingId);
  }

  Future<void> markAllAsRead() async {
    var changed = false;
    for (var index = 0; index < _notifications.length; index += 1) {
      final notification = _notifications[index];
      if (!notification.isRead) {
        _notifications[index] = notification.copyWith(isRead: true);
        changed = true;
      }
    }

    if (!changed) {
      return;
    }

    await _persistNotifications();
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    if (_notifications.isEmpty) {
      return;
    }

    _notifications.clear();
    await _persistNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) {
      return;
    }

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    await _persistNotifications();
    notifyListeners();
  }

  Future<void> openNotification(String id) async {
    final notification = _notifications.cast<AppNotification?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );
    if (notification == null) {
      return;
    }

    await markAsRead(id);

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingOpenKey, id);
      return;
    }

    if (!await _authRepository.isAuthenticated()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingOpenKey, id);
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    final initialTabIndex =
        notification.type == AppNotificationType.deliveryAssignment ? 2 : 0;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => OrdersScreen(
          initialTabIndex: initialTabIndex,
          initialOrderId: notification.orderId,
        ),
      ),
    );
  }

  Future<AppNotification?> ingestRemoteMessage(
    RemoteMessage message, {
    bool showForegroundBanner = false,
  }) async {
    final incoming = AppNotification.fromRemoteMessage(message);
    if (incoming == null) {
      return null;
    }

    final stored = await _storeNotification(incoming);
    if (showForegroundBanner) {
      await _showLocalNotification(stored);
    }
    return stored;
  }

  Future<AppNotification?> ingestRealtimeEvent(
    OrderRealtimeEvent event, {
    bool showForegroundBanner = false,
  }) async {
    final incoming = _notificationFromRealtimeEvent(event);
    if (incoming == null) {
      return null;
    }

    final stored = await _storeNotification(incoming);
    if (showForegroundBanner) {
      await _showLocalNotification(stored);
    }
    notifyListeners();
    return stored;
  }

  AppNotification? _notificationFromRealtimeEvent(OrderRealtimeEvent event) {
    if (!event.shouldShowInNotificationCenter) {
      return null;
    }

    final AppNotificationType type;
    final String title;
    final String body;

    switch (event.type) {
      case OrderRealtimeEventType.orderSubmitted:
        type = AppNotificationType.newOrder;
        title = 'Wpłynęło nowe zamówienie!';
        body = 'Zamówienie ${event.clientOrderNumber} — do realizacji';
      case OrderRealtimeEventType.deliveryAssigned:
        type = AppNotificationType.deliveryAssignment;
        title = 'Nowa wysyłka czeka!';
        body = 'Zamówienie ${event.clientOrderNumber} — adres w aplikacji';
      case OrderRealtimeEventType.dispatchPending:
        type = AppNotificationType.unknown;
        title = 'Gotowe do wysyłki';
        body = 'Zamówienie ${event.clientOrderNumber} — przypisz kuriera';
      case OrderRealtimeEventType.orderStatusChanged:
      case OrderRealtimeEventType.orderDelivered:
      case OrderRealtimeEventType.orderCancelled:
      case OrderRealtimeEventType.unknown:
        return null;
    }

    final createdAt = DateTime.now();
    return AppNotification(
      id: 'stomp-${event.type.name}-${event.orderId}-${createdAt.millisecondsSinceEpoch}',
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: false,
      orderId: event.orderId,
    );
  }

  static Future<void> persistRemoteMessage(RemoteMessage message) async {
    final incoming = AppNotification.fromRemoteMessage(message);
    if (incoming == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_notificationsStorageKey);
    final decoded = existing == null || existing.isEmpty
        ? <dynamic>[]
        : (jsonDecode(existing) as List<dynamic>);
    final items = decoded
        .map(
          (item) => AppNotification.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final existingIndex = items.indexWhere((item) => item.id == incoming.id);
    if (existingIndex >= 0) {
      final previous = items[existingIndex];
      items[existingIndex] = incoming.copyWith(isRead: previous.isRead);
    } else {
      items.insert(0, incoming);
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final trimmed = items.take(100).map((item) => item.toJson()).toList();
    await prefs.setString(_notificationsStorageKey, jsonEncode(trimmed));
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        final json = jsonDecode(payload) as Map<String, dynamic>;
        final notificationId = json['notificationId'] as String?;
        if (notificationId != null && notificationId.isNotEmpty) {
          await openNotification(notificationId);
        }
      },
    );
  }

  Future<void> _restoreLaunchNotification() async {
    final details = await _localNotificationsPlugin
        .getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final notificationId = json['notificationId'] as String?;
      if (notificationId != null && notificationId.isNotEmpty) {
        await openNotification(notificationId);
      }
    }

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final notification = await ingestRemoteMessage(initialMessage);
      if (notification != null) {
        await openNotification(notification.id);
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _ensureAndroidNotificationChannel() async {
    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(_ordersChannel);
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    final notificationId = notification.createdAt.millisecondsSinceEpoch
        .remainder(1 << 31);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _ordersChannel.id,
        _ordersChannel.name,
        channelDescription: _ordersChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _localNotificationsPlugin.show(
      notificationId,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode({'notificationId': notification.id}),
    );
  }

  Future<AppNotification> _storeNotification(AppNotification incoming) async {
    final index = _notifications.indexWhere((item) => item.id == incoming.id);
    if (index >= 0) {
      final previous = _notifications[index];
      _notifications[index] = incoming.copyWith(isRead: previous.isRead);
    } else {
      _notifications.insert(0, incoming);
    }

    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    await _persistNotifications();
    notifyListeners();
    return _notifications.firstWhere((item) => item.id == incoming.id);
  }

  Future<void> _loadPersistedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    _notifications
      ..clear()
      ..addAll(
        decoded.map(
          (item) => AppNotification.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      )
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persistNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _notifications.map((item) => item.toJson()).toList();
    await prefs.setString(_notificationsStorageKey, jsonEncode(encoded));
  }

  Future<void> _syncMessagingToken() async {
    if (!_firebaseReady || _tokenRegisterPath.isEmpty) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final authToken = await _authRepository.getAccessToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    final payload = <String, Object>{
      'token': token,
      'platform': 'android',
    };

    try {
      final response = await _dio.post(
        _tokenRegisterPath,
        data: payload,
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('FCM token zarejestrowany na backendzie.');
      } else {
        debugPrint(
          'FCM token: backend zwrocil ${response.statusCode} (sprawdz FIREBASE_SERVICE_ACCOUNT_JSON po stronie API).',
        );
      }
    } catch (error) {
      debugPrint('FCM token: rejestracja nieudana: $error');
    }
  }

  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    _messageTapSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}