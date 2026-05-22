import 'package:flutter/material.dart';

import 'connectivity_error.dart';
import 'connectivity_problem_service.dart';

class ConnectivityFailureHandler {
  ConnectivityFailureHandler._();

  static bool report(
    Object? error, {
    Future<void> Function()? retry,
  }) {
    if (!ConnectivityError.isConnectivityFailure(error)) {
      return false;
    }

    ConnectivityProblemService.instance.showIfNeeded(retry: retry);
    return true;
  }

  static Widget? emptyBodyIfConnectivity(
    Object? error, {
    Future<void> Function()? retry,
  }) {
    if (!report(error, retry: retry)) {
      return null;
    }
    return const SizedBox.shrink();
  }
}
