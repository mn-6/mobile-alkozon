import 'package:dio/dio.dart';

class ConnectivityError {
  ConnectivityError._();

  static bool isConnectivityFailure(Object? error) {
    if (error is DioException) {
      return _isDioConnectivity(error);
    }

    if (error is StateError) {
      final message = error.message.toLowerCase();
      if (message.contains('backend nie odpowiada')) {
        return true;
      }
    }

    if (error is String) {
      return isConnectivityMessage(error);
    }

    return isConnectivityMessage(error.toString());
  }

  static bool _isDioConnectivity(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        return code == 502 || code == 503 || code == 504;
      default:
        return false;
    }
  }

  static bool isConnectivityMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return false;
    }

    final text = message.toLowerCase();

    const markers = [
      'brak połączenia',
      'błąd połączenia z serwerem',
      'przekroczono czas oczekiwania',
      'serwer jest niedostępny',
      'backend nie odpowiada',
      'network error',
      'connection refused',
      'connection timed out',
      'connection error',
      'nie udało się pobrać logów z serwera',
      'qr start zablokowany',
      'qr stop zablokowany',
    ];

    for (final marker in markers) {
      if (text.contains(marker)) {
        return true;
      }
    }

    return false;
  }
}
