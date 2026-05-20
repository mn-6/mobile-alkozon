class SigningConfig {
  static const String _extraAllowed = String.fromEnvironment(
    'ALLOWED_SIGNING_SHA256_EXTRA',
    defaultValue: '',
  );

  static const List<String> _builtInAllowed = [
    'e1b17830399a952b8ff905023d5dc98f0a202cbb18941beb06000717341ac7f6',
  ];

  static List<String> get allowedSigningCertSha256 {
    final extras = _extraAllowed
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    return [..._builtInAllowed, ...extras];
  }
}
