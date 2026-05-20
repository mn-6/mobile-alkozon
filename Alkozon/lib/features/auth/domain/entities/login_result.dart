sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  const LoginSuccess({required this.accessToken});

  final String accessToken;
}

class LoginRequiresTwoFactor extends LoginResult {
  const LoginRequiresTwoFactor({
    required this.challengeId,
    this.expiresInSeconds,
    this.message,
  });

  final String challengeId;
  final int? expiresInSeconds;
  final String? message;
}

class LoginFailure extends LoginResult {
  const LoginFailure(this.message);

  final String message;
}
