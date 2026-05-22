import 'package:flutter/material.dart';

import '../../features/notifications/presentation/services/notification_service.dart';
import '../config/api_config.dart';
import '../di/injection_container.dart';
import 'connectivity_problem_screen.dart';

class ConnectivityProblemService {
  ConnectivityProblemService._();

  static final ConnectivityProblemService instance =
      ConnectivityProblemService._();

  bool _routeVisible = false;
  Future<void> Function()? _pendingRetry;

  Future<bool> probeServer({
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ??
        (ApiConfig.isProduction
            ? const Duration(seconds: 60)
            : const Duration(seconds: 25));
    await InjectionContainer.I.waitForServerReadyUseCase(
      timeout: effectiveTimeout,
    );
    return true;
  }

  Future<bool> refreshAndRetry({
    Duration? timeout,
  }) async {
    try {
      await probeServer(timeout: timeout);
      final retry = _pendingRetry;
      if (retry != null) {
        await retry();
      }
      return true;
    } catch (error) {
      debugPrint('Connectivity refresh failed: $error');
      return false;
    }
  }

  Future<void> showIfNeeded({Future<void> Function()? retry}) async {
    if (retry != null) {
      _pendingRetry = retry;
    }

    if (_routeVisible) {
      return;
    }

    final navigator = NotificationService.instance.navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      return;
    }

    _routeVisible = true;
    await navigator.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => ConnectivityProblemScreen(
          onRefresh: () => refreshAndRetry(),
        ),
      ),
    );
    _routeVisible = false;
    _pendingRetry = null;
  }
}
