import 'dart:async';
import 'package:flutter/material.dart';

class WorkTimerService extends ChangeNotifier {
  static final WorkTimerService _instance = WorkTimerService._internal();
  factory WorkTimerService() => _instance;
  WorkTimerService._internal();

  Timer? _timer;
  int _seconds = 0;
  int _accumulatedSeconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  DateTime? _lastResumeTime;
  final List<Map<String, String>> _history = [];

  int get seconds => _seconds;
  bool get isRunning => _isRunning;
  DateTime? get startTime => _startTime;
  List<Map<String, String>> get history => _history;

  void toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      if (_lastResumeTime != null) {
        _accumulatedSeconds += DateTime.now().difference(_lastResumeTime!).inSeconds;
      }
    } else {
      if (_startTime == null) _startTime = DateTime.now();
      _lastResumeTime = DateTime.now();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_lastResumeTime != null) {
          int currentSessionSeconds = DateTime.now().difference(_lastResumeTime!).inSeconds;
          _seconds = _accumulatedSeconds + currentSessionSeconds;
          notifyListeners();
        }
      });
    }
    _isRunning = !_isRunning;
    notifyListeners();
  }

  void stopAndSaveWork() {
    if (_seconds == 0 && _accumulatedSeconds == 0) return;

    DateTime endTime = DateTime.now();
    _timer?.cancel();

    if (_isRunning && _lastResumeTime != null) {
      _seconds = _accumulatedSeconds + DateTime.now().difference(_lastResumeTime!).inSeconds;
    }

    _history.insert(0, {
      'start': formatDateTime(_startTime!),
      'end': formatDateTime(endTime),
      'duration': formatTime(_seconds),
    });

    _isRunning = false;
    _seconds = 0;
    _accumulatedSeconds = 0;
    _startTime = null;
    _lastResumeTime = null;
    notifyListeners();
  }

  String formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}