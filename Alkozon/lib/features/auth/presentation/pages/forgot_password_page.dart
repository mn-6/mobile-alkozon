import 'package:flutter/material.dart';

import '../../../../core/security/input_validators.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_message_banner.dart';
import '../../../../core/widgets/app_snackbar.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final emailErr = InputValidators.emailError(_emailController.text.trim());
    setState(() {
      _errorMessage = emailErr;
      _infoMessage = null;
    });
    if (emailErr != null) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _infoMessage =
          'Jeśli konto istnieje, instrukcje resetu hasła zostały wysłane na podany adres e-mail.';
    });
    AppSnackbar.show(
      context,
      message: 'Instrukcje resetu hasła zostały wysłane.',
      success: true,
    );
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
          onPressed: () => Navigator.pop(context),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Wyślij instrukcje',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
