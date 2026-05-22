import 'package:flutter/material.dart';

import '../../../../core/connectivity/connectivity_failure_handler.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/input_validators.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_message_banner.dart';
import '../../domain/entities/forgot_password_result.dart';
import '../../domain/usecases/request_password_reset_use_case.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({
    super.key,
    this.requestPasswordResetUseCase,
  });

  final RequestPasswordResetUseCase? requestPasswordResetUseCase;

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  static const String _successMessage =
      'Jeżeli adres e-mail jest prawidłowy, hasło zostało zresetowane. Sprawdź skrzynkę.';

  final _emailController = TextEditingController();
  late final RequestPasswordResetUseCase _requestPasswordResetUseCase;

  String? _errorMessage;
  String? _infoMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPasswordResetUseCase =
        widget.requestPasswordResetUseCase ??
        InjectionContainer.I.requestPasswordResetUseCase;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final emailErr = InputValidators.emailError(email);

    setState(() {
      _errorMessage = emailErr;
      _infoMessage = null;
    });

    if (emailErr != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final result = await _requestPasswordResetUseCase(email: email);

    if (!mounted) {
      return;
    }

    switch (result) {
      case ForgotPasswordSuccess():
        setState(() {
          _isLoading = false;
          _infoMessage = _successMessage;
        });
      case ForgotPasswordFailure(:final message, :final cause):
        if (ConnectivityFailureHandler.report(cause ?? message)) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 32, right: 32, top: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(size: 60)),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Resetowanie hasła',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Podaj swój e-mail, a wyślemy Ci instrukcje',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                AppMessageBanner(message: _errorMessage!),
                const SizedBox(height: 16),
              ],
              if (_infoMessage != null) ...[
                AppMessageBanner(
                  message: _infoMessage!,
                  kind: AppMessageKind.info,
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'E-mail',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                maxLines: 1,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  'Wpisz swój e-mail',
                  Icons.mail_outline,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Wyślij instrukcje',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }
}
