import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:alkozon/core/di/injection_container.dart';
import 'package:alkozon/features/work_time/domain/entities/work_log_entry.dart';
import 'package:alkozon/features/work_time/domain/repositories/work_log_repository.dart';

String formatDurationSeconds(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class QrActionResult {
  const QrActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class WorkSessionStats {
  const WorkSessionStats({
    required this.workSeconds,
    required this.breakSeconds,
    required this.totalSeconds,
  });

  final int workSeconds;
  final int breakSeconds;
  final int totalSeconds;
}

class WorkTimerService extends ChangeNotifier {
  static final WorkTimerService _instance = WorkTimerService._internal();
  factory WorkTimerService() => _instance;

  WorkTimerService._internal() {
    _initFuture = _initialize();
  }

  late final Future<void> _initFuture;

  Future<void> ensureInitialized() => _initFuture;

  Future<void> _initialize() async {
    await _initNotifications();
    await loadPersistedState();
  }

  static const int breakWarningSeconds = 15 * 60;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final WorkLogRepository _workLogRepository =
      InjectionContainer.I.workLogRepository;

  final _storage = const FlutterSecureStorage();

  static const _startTimeKey = 'start_time';
  static const _sessionIdKey = 'work_session_id';
  static const _accumulatedBreakKey = 'work_break_accumulated_seconds';
  static const _onBreakKey = 'work_on_break';
  static const _breakStartKey = 'work_break_start_time';
  static const _breakTotalsCacheKey = 'work_log_break_totals_cache';

  Timer? _timer;
  bool _isRunning = false;
  DateTime? _startTime;
  int? _openSessionId;
  int _accumulatedBreakSeconds = 0;
  bool _isOnBreak = false;
  DateTime? _breakStartTime;
  Map<int, int> _breakTotalsByLogId = {};

  List<WorkLogEntry> _history = [];
  bool _isSyncing = false;
  bool _isHistoryLoading = false;
  String? _historyError;
  bool _isBreakActionInProgress = false;

  int get seconds => workSeconds;
  bool get isRunning => _isRunning;
  bool get isOnBreak => _isOnBreak;
  bool get isBreakActionInProgress => _isBreakActionInProgress;
  DateTime? get startTime => _startTime;
  List<WorkLogEntry> get history => _history;
  bool get isSyncing => _isSyncing;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;

  static int _clampInt(int value, int lower, int upper) {
    if (lower > upper) return lower;
    return value.clamp(lower, upper);
  }

  int get workSeconds {
    if (_startTime == null) return 0;
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    if (elapsed <= 0) return 0;
    final currentBreak = _currentBreakSegmentSeconds;
    return _clampInt(
      elapsed - _accumulatedBreakSeconds - currentBreak,
      0,
      elapsed,
    );
  }

  int get breakSeconds => _accumulatedBreakSeconds + _currentBreakSegmentSeconds;

  int get _currentBreakSegmentSeconds {
    if (!_isOnBreak || _breakStartTime == null) return 0;
    return _clampInt(
      DateTime.now().difference(_breakStartTime!).inSeconds,
      0,
      86400,
    );
  }

  bool get isCurrentBreakOverLimit =>
      _isOnBreak && _currentBreakSegmentSeconds > breakWarningSeconds;

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadBreakTotalsCache() async {
    final raw = await _storage.read(key: _breakTotalsCacheKey);
    if (raw == null || raw.isEmpty) {
      _breakTotalsByLogId = {};
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _breakTotalsByLogId = decoded.map(
        (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
      );
    } catch (_) {
      _breakTotalsByLogId = {};
    }
  }

  Future<void> _saveBreakTotalsCache() async {
    final encoded = jsonEncode(
      _breakTotalsByLogId.map((key, value) => MapEntry(key.toString(), value)),
    );
    await _storage.write(key: _breakTotalsCacheKey, value: encoded);
  }

  Future<void> _persistSessionState() async {
    if (_startTime != null) {
      await _storage.write(
        key: _startTimeKey,
        value: _startTime!.toIso8601String(),
      );
    }
    if (_openSessionId != null) {
      await _storage.write(
        key: _sessionIdKey,
        value: _openSessionId.toString(),
      );
    } else {
      await _storage.delete(key: _sessionIdKey);
    }
    await _storage.write(
      key: _accumulatedBreakKey,
      value: _accumulatedBreakSeconds.toString(),
    );
    await _storage.write(key: _onBreakKey, value: _isOnBreak.toString());
    if (_breakStartTime != null) {
      await _storage.write(
        key: _breakStartKey,
        value: _breakStartTime!.toIso8601String(),
      );
    } else {
      await _storage.delete(key: _breakStartKey);
    }
  }

  Future<void> _clearSessionState() async {
    _openSessionId = null;
    _accumulatedBreakSeconds = 0;
    _isOnBreak = false;
    _breakStartTime = null;
    _isRunning = false;
    _startTime = null;
    await _storage.delete(key: _startTimeKey);
    await _storage.delete(key: _sessionIdKey);
    await _storage.delete(key: _accumulatedBreakKey);
    await _storage.delete(key: _onBreakKey);
    await _storage.delete(key: _breakStartKey);
  }

  Future<void> _finalizeLocalSession({
    int? sessionId,
    int? finalBreakSeconds,
  }) async {
    _timer?.cancel();
    await _notificationsPlugin.cancel(888);

    if (sessionId != null && finalBreakSeconds != null) {
      _breakTotalsByLogId[sessionId] = finalBreakSeconds;
      await _saveBreakTotalsCache();
    }

    await _clearSessionState();
    notifyListeners();
  }

  void _mergeBreakStartFromServer(DateTime serverBreakStart) {
    final normalized = _normalizeBreakStart(serverBreakStart);
    if (_breakStartTime == null) {
      _breakStartTime = normalized;
      return;
    }
    if (normalized.isBefore(_breakStartTime!)) {
      _breakStartTime = normalized;
    }
  }

  int _breakSecondsBetween(DateTime? startedAt, DateTime? endedAt) {
    if (startedAt == null || endedAt == null) return 0;
    return _clampInt(endedAt.difference(startedAt).inSeconds, 0, 86400);
  }

  DateTime _normalizeSessionStart(DateTime serverStart) {
    final localStart = serverStart.toLocal();
    final now = DateTime.now();
    return localStart.isAfter(now) ? now : localStart;
  }

  DateTime _normalizeBreakStart(DateTime serverBreakStart) {
    final localStart = serverBreakStart.toLocal();
    final now = DateTime.now();
    return localStart.isAfter(now) ? now : localStart;
  }

  void _ensureBreakStartTime() {
    if (_isOnBreak && _breakStartTime == null) {
      _breakStartTime = DateTime.now();
    }
  }

  Future<void> _applyOpenSession(WorkLogEntry session) async {
    _openSessionId = session.id;
    if (!_isRunning) {
      _startTime = _normalizeSessionStart(session.clockInAt);
      _isRunning = true;
    }

    final breakActive =
        session.breakStartedAt != null && session.breakEndedAt == null;
    if (breakActive) {
      _isOnBreak = true;
      _mergeBreakStartFromServer(session.breakStartedAt!);
      _ensureBreakStartTime();
      return;
    }

    if (_isOnBreak &&
        session.breakStartedAt != null &&
        session.breakEndedAt != null) {
      _accumulatedBreakSeconds = _breakSecondsBetween(
        session.breakStartedAt,
        session.breakEndedAt,
      );
    } else if (!_isOnBreak &&
        session.breakStartedAt != null &&
        session.breakEndedAt != null) {
      final completedBreak = _breakSecondsBetween(
        session.breakStartedAt,
        session.breakEndedAt,
      );
      if (completedBreak > _accumulatedBreakSeconds) {
        _accumulatedBreakSeconds = completedBreak;
      }
    } else if (_isOnBreak && session.breakStartedAt == null) {
      _ensureBreakStartTime();
      return;
    }

    _isOnBreak = false;
    _breakStartTime = null;
  }

  Future<void> loadPersistedState() async {
    await _loadBreakTotalsCache();

    final storedStartTime = await _storage.read(key: _startTimeKey);
    final storedSessionId = await _storage.read(key: _sessionIdKey);
    final storedAccumulated = await _storage.read(key: _accumulatedBreakKey);
    final storedOnBreak = await _storage.read(key: _onBreakKey);
    final storedBreakStart = await _storage.read(key: _breakStartKey);

    if (storedStartTime != null) {
      _startTime = _normalizeSessionStart(DateTime.parse(storedStartTime));
      _isRunning = true;
      _openSessionId = int.tryParse(storedSessionId ?? '');
      _accumulatedBreakSeconds = int.tryParse(storedAccumulated ?? '') ?? 0;
      _isOnBreak = storedOnBreak == 'true';
      _breakStartTime = storedBreakStart != null
          ? _normalizeBreakStart(DateTime.parse(storedBreakStart))
          : null;
      _ensureBreakStartTime();
      _startTimerLoop();
      await _updateNotification();
      notifyListeners();
    }
  }

  Future<void> onAppResumed() async {
    await ensureInitialized();
    notifyListeners();
    await _updateNotification();
    await refreshFromBackend();
  }

  Future<void> refreshFromBackend() async {
    await ensureInitialized();
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final openSession = await _workLogRepository.getCurrentOpenSession();

      if (openSession != null) {
        await _applyOpenSession(openSession);
        await _persistSessionState();
        if (!(_timer?.isActive ?? false)) {
          _startTimerLoop();
        }
        await _updateNotification();
      } else {
        _timer?.cancel();
        await _notificationsPlugin.cancel(888);
        await _clearSessionState();
      }
    } catch (_) {
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
      final logs = await _workLogRepository.getMyLogs(
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

  int breakSecondsForLog(WorkLogEntry log) {
    final cached = _breakTotalsByLogId[log.id];
    if (cached != null) return cached;
    if (log.breakStartedAt != null && log.breakEndedAt != null) {
      return _clampInt(
          log.breakEndedAt!
              .difference(log.breakStartedAt!)
              .inSeconds,
          0,
          86400,
        );
    }
    return 0;
  }

  WorkSessionStats statsForLog(WorkLogEntry log) {
    final end = log.clockOutAt ?? DateTime.now().toUtc();
    final totalSeconds = _clampInt(
      end.difference(log.clockInAt).inSeconds,
      0,
      86400 * 365,
    );
    final breakSeconds = breakSecondsForLog(log);
    final workSeconds = _clampInt(totalSeconds - breakSeconds, 0, totalSeconds);
    return WorkSessionStats(
      workSeconds: workSeconds,
      breakSeconds: breakSeconds,
      totalSeconds: totalSeconds,
    );
  }

  Future<void> _updateNotification() async {
    if (!_isRunning || _startTime == null) return;

    final androidDetails = AndroidNotificationDetails(
      'work_timer_channel',
      'Monitor Pracy',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: !_isOnBreak,
      usesChronometer: !_isOnBreak,
      when: _startTime!.millisecondsSinceEpoch,
    );

    await _notificationsPlugin.show(
      888,
      _isOnBreak ? 'Przerwa w toku' : 'Praca w toku',
      _isOnBreak
          ? 'Przerwa: ${formatTime(breakSeconds)}'
          : 'Sesja: ${formatTime(workSeconds)}',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> endActiveSessionForLogout() async {
    await ensureInitialized();

    if (!_isRunning) {
      try {
        final openSession = await _workLogRepository.getCurrentOpenSession();
        if (openSession != null) {
          await _applyOpenSession(openSession);
        }
      } catch (_) {
        return;
      }
    }

    if (!_isRunning) {
      return;
    }

    final sessionId = _openSessionId;
    final finalBreakSeconds = _accumulatedBreakSeconds + _currentBreakSegmentSeconds;

    try {
      if (_isOnBreak) {
        try {
          await _workLogRepository.endBreak();
        } catch (_) {}
      }
      try {
        await _workLogRepository.clockOut();
      } catch (_) {}
    } finally {
      await _finalizeLocalSession(
        sessionId: sessionId,
        finalBreakSeconds: finalBreakSeconds,
      );
      unawaited(refreshHistoryFromBackend());
    }
  }

  Future<QrActionResult> processQrCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.startsWith('work_start/')) {
      await refreshFromBackend();
      if (_isRunning) {
        return const QrActionResult(
          success: false,
          message:
              'Sesja pracy jest już aktywna. Zeskanuj kod końca, aby ją zamknąć.',
        );
      }
      return _startWork();
    } else if (cleanCode.startsWith('work_stop/')) {
      if (!_isRunning) {
        await refreshFromBackend();
      }

      if (!_isRunning) {
        return const QrActionResult(
          success: false,
          message: 'Brak aktywnej sesji do zakończenia.',
        );
      }

      if (_isOnBreak) {
        return const QrActionResult(
          success: false,
          message: 'Zakończ przerwę przed zeskanowaniem końca zmiany.',
        );
      }

      return stopAndSaveWork();
    }

    return const QrActionResult(success: false, message: 'Nieznany kod QR.');
  }

  Future<QrActionResult> startBreak() async {
    if (!_isRunning || _startTime == null) {
      return const QrActionResult(
        success: false,
        message: 'Brak aktywnej sesji pracy.',
      );
    }
    if (_isOnBreak || _isBreakActionInProgress) {
      return const QrActionResult(
        success: false,
        message: 'Przerwa jest już aktywna.',
      );
    }

    _isBreakActionInProgress = true;
    notifyListeners();

    try {
      final session = await _workLogRepository.startBreak();
      _openSessionId = session.id;
      _isOnBreak = true;
      _breakStartTime = DateTime.now();
      if (session.breakStartedAt != null) {
        _mergeBreakStartFromServer(session.breakStartedAt!);
      }
      await _persistSessionState();
      await _updateNotification();
      notifyListeners();
      return const QrActionResult(success: true, message: 'Przerwa rozpoczęta.');
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString();
      return QrActionResult(
        success: false,
        message: message ?? 'Nie udało się rozpocząć przerwy.',
      );
    } catch (_) {
      return const QrActionResult(
        success: false,
        message: 'Nie udało się rozpocząć przerwy.',
      );
    } finally {
      _isBreakActionInProgress = false;
      notifyListeners();
    }
  }

  Future<QrActionResult> endBreak() async {
    if (!_isRunning) {
      return const QrActionResult(
        success: false,
        message: 'Brak aktywnej sesji pracy.',
      );
    }
    if (!_isOnBreak || _isBreakActionInProgress) {
      return const QrActionResult(
        success: false,
        message: 'Brak aktywnej przerwy.',
      );
    }

    _isBreakActionInProgress = true;
    notifyListeners();

    try {
      await _workLogRepository.endBreak();
      final segmentSeconds = _currentBreakSegmentSeconds;
      _accumulatedBreakSeconds += segmentSeconds;
      _isOnBreak = false;
      _breakStartTime = null;
      await _persistSessionState();
      await _updateNotification();
      notifyListeners();
      return const QrActionResult(success: true, message: 'Przerwa zakończona.');
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString();
      return QrActionResult(
        success: false,
        message: message ?? 'Nie udało się zakończyć przerwy.',
      );
    } catch (_) {
      return const QrActionResult(
        success: false,
        message: 'Nie udało się zakończyć przerwy.',
      );
    } finally {
      _isBreakActionInProgress = false;
      notifyListeners();
    }
  }

  Future<QrActionResult> _startWork() async {
    try {
      final session = await _workLogRepository.clockIn();
      _openSessionId = session.id;
      _accumulatedBreakSeconds = 0;
      _isOnBreak = false;
      _breakStartTime = null;
      _startTime = _normalizeSessionStart(session.clockInAt);
      _isRunning = true;

      await _persistSessionState();
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
        await refreshFromBackend();
        if (_isRunning) {
          return const QrActionResult(
            success: false,
            message:
                'Na serwerze jest już otwarta sesja. Zeskanuj kod końca, aby ją zamknąć.',
          );
        }
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        notifyListeners();
        if (_isOnBreak) {
          _updateNotification();
        }
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

    if (_isOnBreak) {
      return const QrActionResult(
        success: false,
        message: 'Zakończ przerwę przed zakończeniem zmiany.',
      );
    }

    try {
      final sessionId = _openSessionId;
      final finalBreakSeconds = _accumulatedBreakSeconds;
      final finalWorkSeconds = workSeconds;
      final finalTotalSeconds = finalWorkSeconds + finalBreakSeconds;

      await _workLogRepository.clockOut();

      final successMessage = QrActionResult(
        success: true,
        message:
            'Koniec pracy zapisany. '
            'Czas pracy: ${formatTime(finalWorkSeconds)}, '
            'Czas przerwy: ${formatTime(finalBreakSeconds)}, '
            'Całkowity czas: ${formatTime(finalTotalSeconds)}.',
      );

      await _finalizeLocalSession(
        sessionId: sessionId,
        finalBreakSeconds: finalBreakSeconds,
      );

      unawaited(refreshHistoryFromBackend());

      return successMessage;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        final message = e.response?.data?['message']?.toString();
        if (message == 'End break first') {
          return const QrActionResult(
            success: false,
            message: 'Zakończ przerwę przed zakończeniem zmiany.',
          );
        }
        if (message == 'No open session') {
          final sessionId = _openSessionId;
          final finalBreakSeconds = _accumulatedBreakSeconds;
          final finalWorkSeconds = workSeconds;
          final finalTotalSeconds = finalWorkSeconds + finalBreakSeconds;
          await _finalizeLocalSession(
            sessionId: sessionId,
            finalBreakSeconds: finalBreakSeconds,
          );
          unawaited(refreshHistoryFromBackend());
          return QrActionResult(
            success: true,
            message:
                'Sesja była już zamknięta na serwerze. '
                'Czas pracy: ${formatTime(finalWorkSeconds)}, '
                'Czas przerwy: ${formatTime(finalBreakSeconds)}, '
                'Całkowity czas: ${formatTime(finalTotalSeconds)}.',
          );
        }
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

  String formatTime(int totalSeconds) => formatDurationSeconds(totalSeconds);
}
