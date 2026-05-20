import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/security/input_validators.dart';
import '../../../../core/security/login_attempt_limiter.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../../notifications/presentation/services/notification_service.dart';
import '../../../orders_realtime/data/services/order_realtime_service.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _di = InjectionContainer.I;
  final LoginAttemptLimiter _loginAttemptLimiter = LoginAttemptLimiter();
  final NotificationService _notificationService = NotificationService.instance;
  static const String _cachedLoginEmailKey = 'cached_login_email';
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _codeController;
  bool _isLoading = false;
  bool _isPasswordVisibleWhilePressed = false;
  String? _errorMessage;
  String? _infoMessage;
  bool _requiresTwoFactor = false;
  String? _challengeId;

  LoginUseCase get _loginUseCase => _di.loginUseCase;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _codeController = TextEditingController();
    _loadCachedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    await _cacheEmail(email);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final attemptStatus = await _loginAttemptLimiter.checkAllowed();
    if (!attemptStatus.allowed) {
      setState(() {
        _isLoading = false;
        _errorMessage = attemptStatus.lockoutMessage;
      });
      return;
    }

    if (!_requiresTwoFactor) {
      final emailErr = InputValidators.emailError(email);
      final passwordErr = InputValidators.passwordError(_passwordController.text);
      if (emailErr != null || passwordErr != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = emailErr ?? passwordErr;
        });
        return;
      }
    } else {
      final codeErr = InputValidators.verificationCodeError(_codeController.text);
      if (codeErr != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = codeErr;
        });
        return;
      }
    }

    final result = await _loginUseCase(
      email: email,
      password: _passwordController.text,
      verificationCode: _requiresTwoFactor ? _codeController.text : null,
      challengeId: _challengeId,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoginSuccess():
        await _loginAttemptLimiter.recordSuccess();
        await _notificationService.onAuthenticated();
        await OrderRealtimeService.instance.connectForCurrentUser(
          authRepository: _di.authRepository,
        );
        if (!mounted) {
          return;
        }
        await Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
        Future<void>.delayed(Duration.zero, () {
          _notificationService.processPendingNavigation();
        });
      case LoginRequiresTwoFactor():
        setState(() {
          _requiresTwoFactor = true;
          _challengeId = result.challengeId;
          _infoMessage = result.message ?? 'Wpisz kod 2FA wysłany na e-mail';
        });
      case LoginFailure():
        await _loginAttemptLimiter.recordFailure();
        setState(() {
          _errorMessage = result.message;
        });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCachedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedEmail = prefs.getString(_cachedLoginEmailKey)?.trim();
    if (cachedEmail == null || cachedEmail.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    _emailController.text = cachedEmail;
  }

  Future<void> _cacheEmail(String email) async {
    if (email.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedLoginEmailKey, email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 128),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'lib/imgs/logo.jpg',
                    height: 72,
                    width: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Witaj ponownie',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Zaloguj się do swojego panelu',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),
              if (_infoMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _infoMessage!,
                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              if (_infoMessage != null) const SizedBox(height: 16),
              _buildLabel('Email'),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                maxLines: 1,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  'Wpisz swój email',
                  Icons.mail_outline,
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Hasło'),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                maxLines: 1,
                obscureText: !_isPasswordVisibleWhilePressed,
                decoration: _inputDecoration(
                  '••••••••',
                  Icons.lock_outline,
                  suffixIcon: GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isPasswordVisibleWhilePressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isPasswordVisibleWhilePressed = false;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _isPasswordVisibleWhilePressed = false;
                      });
                    },
                    child: Icon(
                      _isPasswordVisibleWhilePressed
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              if (_requiresTwoFactor) ...[
                const SizedBox(height: 20),
                _buildLabel('Kod 2FA'),
                TextField(
                  controller: _codeController,
                  enabled: !_isLoading,
                  maxLines: 1,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Wpisz kod z e-maila',
                    Icons.verified_user_outlined,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPassword(),
                              ),
                            );
                          },
                    child: const Text(
                      'Zapomniałeś hasła?',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                      : Text(
                          _requiresTwoFactor ? 'Zweryfikuj kod' : 'Zaloguj się',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
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
