import 'package:dio/dio.dart';

/// Rezerwowany pod ewentualne logowanie błędów sieciowych.
///
/// Ekran „Problem z łącznością” otwieramy jawnie przez [ConnectivityFailureHandler],
/// nie tutaj — automatyczne wyświetlanie przy każdym [DioException] blokowało logowanie
/// (np. rejestracja tokenu FCM w tle tuż po starcie aplikacji).
class ConnectivityErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
