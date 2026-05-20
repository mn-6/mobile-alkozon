class InputValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _verificationCodePattern = RegExp(r'^\d{4,8}$');

  static String? emailError(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Podaj adres e-mail';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Nieprawidłowy format adresu e-mail';
    }
    return null;
  }

  static String? passwordError(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'Podaj hasło';
    }
    if (trimmed.length < 8) {
      return 'Hasło musi mieć co najmniej 8 znaków';
    }
    return null;
  }

  static String? verificationCodeError(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Podaj kod weryfikacyjny';
    }
    if (!_verificationCodePattern.hasMatch(trimmed)) {
      return 'Kod musi składać się z 4–8 cyfr';
    }
    return null;
  }
}
