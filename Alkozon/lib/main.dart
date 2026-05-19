import 'package:flutter/material.dart';
import 'package:alkozon/screens/dashboard.dart';
import 'package:alkozon/screens/forgot_password_screen.dart';
import 'package:alkozon/services/auth_service.dart';
import 'package:alkozon/services/notification_service.dart';
import 'package:alkozon/services/product_image_resolver.dart';
import 'package:alkozon/services/startup_warmup_service.dart';
import 'services/security_service.dart'; // IMPORT Twojego nowego serwisu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ProductImageResolver.ensureInitialized();
  await SecurityService.checkSecurity();
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final StartupWarmupService _startupWarmupService = StartupWarmupService();
  bool _isWarmingUp = true;
  String? _warmupError;

  @override
  void initState() {
    super.initState();
    _warmUpServer();
  }

  Future<void> _warmUpServer() async {
    try {
      await _startupWarmupService.waitForServerReady();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _warmupError = error.toString();
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isWarmingUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.instance.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'sans-serif',
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (_isWarmingUp) ...[
              const ModalBarrier(dismissible: false, color: Color(0x88FFFFFF)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_warmupError == null)
                        const CircularProgressIndicator()
                      else ...[
                        const Icon(Icons.wifi_off, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _warmupError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _warmupError = null;
                            });
                            _warmUpServer();
                          },
                          child: const Text('Spróbuj ponownie'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService.instance;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _codeController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;
  bool _requiresTwoFactor = false;
  String? _challengeId;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
      verificationCode: _requiresTwoFactor ? _codeController.text : null,
      challengeId: _challengeId,
    );

    if (mounted) {
      if (result['success']) {
        await _notificationService.onAuthenticated();
        // Logowanie udane - przejdź do Dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
          Future<void>.delayed(Duration.zero, () {
            _notificationService.processPendingNavigation();
          });
        }
      } else if (result['requires2fa'] == true) {
        setState(() {
          _requiresTwoFactor = true;
          _challengeId = result['challengeId']?.toString();
          _infoMessage =
              result['message']?.toString() ??
              'Wpisz kod 2FA wysłany na e-mail';
        });
      } else {
        // Pokaż błąd
        setState(() {
          _errorMessage = result['error'] ?? 'Błąd logowania';
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
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
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  "Witaj ponownie",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  "Zaloguj się do swojego panelu",
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 24),
              // Komunikat błędu
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Text(
                    _infoMessage!,
                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              if (_infoMessage != null) const SizedBox(height: 16),
              _buildLabel("Email"),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  "Wpisz swój email",
                  Icons.mail_outline,
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel("Hasło"),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: true,
                decoration: _inputDecoration("••••••••", Icons.lock_outline),
              ),
              if (_requiresTwoFactor) ...[
                const SizedBox(height: 20),
                _buildLabel("Kod 2FA"),
                TextField(
                  controller: _codeController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    "Wpisz kod z e-maila",
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
                      "Zapomniałeś hasła?",
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
                          _requiresTwoFactor ? "Zweryfikuj kod" : "Zaloguj się",
                          style: TextStyle(
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
