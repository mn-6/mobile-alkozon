import 'package:dio/dio.dart';

import '../connectivity/connectivity_error.dart';
import '../connectivity/connectivity_problem_service.dart';

/// Przechwytuje błędy łączności z głównego klienta HTTP i pokazuje ekran problemu.
class ConnectivityErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (ConnectivityError.isConnectivityFailure(err)) {
      ConnectivityProblemService.instance.showIfNeeded();
    }
    handler.next(err);
  }
}
