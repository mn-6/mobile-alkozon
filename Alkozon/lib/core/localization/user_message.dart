import 'package:dio/dio.dart';

/// Ujednolica komunikaty użytkownika po polsku (także z backendu / wyjątków).
class UserMessage {
  UserMessage._();

  static String polish(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Wystąpił nieoczekiwany błąd.';
    }

    final text = raw.trim();

    const replacements = <String, String>{
      'Invalid credentials': 'Nieprawidłowy e-mail lub hasło.',
      'Bad credentials': 'Nieprawidłowy e-mail lub hasło.',
      'Unauthorized': 'Sesja wygasła. Zaloguj się ponownie.',
      'Forbidden': 'Brak uprawnień do tej operacji.',
      'Not Found': 'Nie znaleziono zasobu.',
      'Internal Server Error': 'Błąd serwera. Spróbuj ponownie później.',
      'Network Error': 'Brak połączenia z internetem.',
      'Connection refused': 'Serwer jest niedostępny.',
      'Connection timed out': 'Przekroczono czas oczekiwania na odpowiedź serwera.',
      'Missing tokens in auth response': 'Brak tokenów w odpowiedzi serwera.',
      'Exception:': '',
    };

    for (final entry in replacements.entries) {
      if (text.contains(entry.key)) {
        return entry.value.isEmpty
            ? text.replaceFirst('Exception:', '').trim()
            : entry.value;
      }
    }

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }

    return text;
  }

  static String fromError(Object? error) {
    if (error == null) {
      return 'Wystąpił nieoczekiwany błąd.';
    }

    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return polish(data['message'].toString());
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Przekroczono czas oczekiwania na odpowiedź serwera.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Brak połączenia z serwerem. Sprawdź internet.';
      }
      return polish(error.message);
    }

    return polish(error.toString());
  }
}
