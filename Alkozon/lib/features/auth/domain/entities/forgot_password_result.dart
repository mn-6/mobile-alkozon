sealed class ForgotPasswordResult {
  const ForgotPasswordResult();
}

class ForgotPasswordSuccess extends ForgotPasswordResult {
  const ForgotPasswordSuccess();
}

class ForgotPasswordFailure extends ForgotPasswordResult {
  const ForgotPasswordFailure(this.message, {this.cause});

  final String message;
  final Object? cause;
}
