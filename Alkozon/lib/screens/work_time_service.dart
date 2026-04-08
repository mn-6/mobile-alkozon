import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // NOWOŚĆ

class WorkTimerService extends ChangeNotifier {
  static final WorkTimerService _instance = WorkTimerService._internal();
  factory WorkTimerService() => _instance;

  WorkTimerService._internal() {
    _initNotifications();
    loadPersistedState();
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final _storage = const FlutterSecureStorage();

  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  final List<Map<String, String>> _history = [];

  int get seconds => _seconds;
  bool get isRunning => _isRunning;
  DateTime? get startTime => _startTime;
  List<Map<String, String>> get history => _history;

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> loadPersistedState() async {
    final String? storedStartTime = await _storage.read(key: 'start_time');

    if (storedStartTime != null) {
      _startTime = DateTime.parse(storedStartTime);
      _isRunning = true;
      _startTimerLoop();
      _updateNotification();
      notifyListeners();
    }
  }

  Future<void> _updateNotification() async {
    if (!_isRunning || _startTime == null) return;

    final int startTimeInMs = _startTime!.millisecondsSinceEpoch;

    final androidDetails = AndroidNotificationDetails(
      'work_timer_channel',
      'Monitor Pracy',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: true,
      usesChronometer: true,
      when: startTimeInMs,
    );

    await _notificationsPlugin.show(
      888,
      'Praca w toku',
      'Twoja sesja jest bezpiecznie zapisana',
      NotificationDetails(android: androidDetails),
    );
  }

  void processQrCode(String code) {
    final cleanCode = code.trim();
    if (cleanCode.startsWith("work_start/")) {
      if (!_isRunning) _startWork();
    } else if (cleanCode.startsWith("work_stop/")) {
      if (_isRunning) stopAndSaveWork();
    }
  }

  Future<void> _startWork() async {
    _startTime = DateTime.now();
    _isRunning = true;

    await _storage.write(key: 'start_time', value: _startTime!.toIso8601String());

    _startTimerLoop();
    _updateNotification();
    notifyListeners();
  }

  void _startTimerLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        _seconds = DateTime.now().difference(_startTime!).inSeconds;
        notifyListeners();
      }
    });
  }

  Future<void> stopAndSaveWork() async {
    if (_startTime == null) return;

    _timer?.cancel();
    _notificationsPlugin.cancel(888);

    await _storage.delete(key: 'start_time');

    DateTime endTime = DateTime.now();
    _history.insert(0, {
      'start': formatDateTime(_startTime!),
      'end': formatDateTime(endTime),
      'duration': formatTime(_seconds),
    });

    _isRunning = false;
    _seconds = 0;
    _startTime = null;
    notifyListeners();
  }

  String formatDateTime(DateTime dt) => "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  String formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}