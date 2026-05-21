import 'package:flutter/widgets.dart';

/// Tracks whether the app is in the foreground (resumed).
/// Used to route realtime alerts: STOMP when open, FCM when in background.
class AppForegroundState with WidgetsBindingObserver {
  AppForegroundState._();

  static final AppForegroundState instance = AppForegroundState._();

  bool _isForeground = true;
  bool _attached = false;

  bool get isForeground => _isForeground;

  void attach() {
    if (_attached) {
      return;
    }
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _isForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void detach() {
    if (!_attached) {
      return;
    }
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final next = state == AppLifecycleState.resumed;
    if (_isForeground == next) {
      return;
    }
    _isForeground = next;
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}
