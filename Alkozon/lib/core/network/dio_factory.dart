import 'package:dio/dio.dart';

import '../config/api_config.dart';

class DioFactory {
  DioFactory._();

  static Dio create({Duration? connectTimeout, Duration? receiveTimeout}) {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 10),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 10),
      ),
    );
  }

  static Options bearerOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
