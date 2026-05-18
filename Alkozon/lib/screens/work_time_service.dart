import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/work_log_service.dart';

class QrActionResult {
  const QrActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class WorkTimerService extends ChangeNotifier {
  static final WorkTimerService _instance = WorkTimerService._internal();
  factory WorkTimerService() => _instance;

  WorkTimerService._internal() {
    _initNotifications();
    loadPersistedState();
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final WorkLogService _workLogService = WorkLogService();

  final _storage = const FlutterSecureStorage();

  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  List<WorkLogEntry> _history = [];
  bool _isSyncing = false;
  bool _isHistoryLoading = false;
  String? _historyError;

  int get seconds => _seconds;
  bool get isRunning => _isRunning;
  DateTime? get startTime => _startTime;
  List<WorkLogEntry> get history => _history;
  bool get isSyncing => _isSyncing;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;

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

  Future<void> refreshFromBackend() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final openSession = await _workLogService.getCurrentOpenSession();

      if (openSession != null) {
        if (!_isRunning) {
          // Restore timer from server (e.g. after app restart).
          // Do NOT overwrite if already running locally (e.g. just scanned START)
          // to avoid server/device clock drift showing wrong elapsed time.
          _startTime = openSession.clockInAt.toLocal();
          _isRunning = true;
          _seconds = DateTime.now()
              .difference(_startTime!)
              .inSeconds
              .clamp(0, 86400);
          await _storage.write(
            key: 'start_time',
            value: _startTime!.toIso8601String(),
          );
          _startTimerLoop();
          await _updateNotification();
        }
        // If already running locally, keep existing _startTime (avoids clock drift)
      } else {
        _timer?.cancel();
        _notificationsPlugin.cancel(888);
        _isRunning = false;
        _seconds = 0;
        _startTime = null;
        await _storage.delete(key: 'start_time');
      }
    } catch (_) {
      // Brak sieci/serwera - zostaw lokalny stan timera bez zmian.
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    await refreshHistoryFromBackend();
  }

  Future<void> refreshHistoryFromBackend() async {
    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();

    try {
      final now = DateTime.now().toUtc();
      final logs = await _workLogService.getMyLogs(
        from: DateTime.utc(2000, 1, 1),
        to: now.add(const Duration(days: 1)),
      );
      _history = logs;
    } on DioException catch (e) {
      _historyError =
          e.response?.data?['message']?.toString() ??
          'Nie udało się pobrać logów z serwera.';
    } catch (_) {
      _historyError = 'Nie udało się pobrać logów z serwera.';
    } finally {
      _isHistoryLoading = false;
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

  Future<QrActionResult> processQrCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.startsWith("work_start/")) {
      if (_isRunning) {
        return const QrActionResult(
          success: false,
          message: 'Sesja pracy jest już aktywna.',
        );
      }
      return _startWork();
    } else if (cleanCode.startsWith("work_stop/")) {
      if (!_isRunning) {
        await refreshFromBackend();
      }

      if (!_isRunning) {
        return const QrActionResult(
          success: false,
          message: 'Brak aktywnej sesji do zakończenia.',
        );
      }

      return stopAndSaveWork();
    }

    return const QrActionResult(success: false, message: 'Nieznany kod QR.');
  }

  Future<QrActionResult> _startWork() async {
    try {
      await _workLogService.clockIn();
      // Start local stopwatch from scan moment to avoid backend/device clock drift.
      _startTime = DateTime.now();
      _isRunning = true;
      _seconds = 0;

      await _storage.write(
        key: 'start_time',
        value: _startTime!.toIso8601String(),
      );

      _startTimerLoop();
      await _updateNotification();
      await refreshHistoryFromBackend();
      notifyListeners();
      return const QrActionResult(
        success: true,
        message: 'Start pracy zapisany w bazie.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        return const QrActionResult(
          success: false,
          message: 'Nie można rozpocząć pracy (sesja już aktywna).',
        );
      }
      return const QrActionResult(
        success: false,
        message:
            'Brak połączenia z internetem lub serwerem. QR start zablokowany.',
      );
    } catch (_) {
      return const QrActionResult(
        success: false,
        message: 'Nie udało się rozpocząć pracy.',
      );
    }
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

  Future<QrActionResult> stopAndSaveWork() async {
    if (_startTime == null) {
      return const QrActionResult(
        success: false,
        message: 'Brak aktywnej sesji do zakończenia.',
      );
    }

    try {
      await _workLogService.clockOut();

      _timer?.cancel();
      _notificationsPlugin.cancel(888);

      await _storage.delete(key: 'start_time');

      await refreshHistoryFromBackend();

      _isRunning = false;
      _seconds = 0;
      _startTime = null;
      notifyListeners();
      return const QrActionResult(
        success: true,
        message: 'Koniec pracy zapisany w bazie.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        return const QrActionResult(
          success: false,
          message: 'Nie można zakończyć pracy (brak otwartej sesji).',
        );
      }
      return const QrActionResult(
        success: false,
        message:
            'Brak połączenia z internetem lub serwerem. QR stop zablokowany.',
      );
    } catch (_) {
      return const QrActionResult(
        success: false,
        message: 'Nie udało się zakończyć pracy.',
      );
    }
  }

  String formatDateTime(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  String formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
