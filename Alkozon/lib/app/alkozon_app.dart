import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/di/injection_container.dart';
import '../core/widgets/app_logo.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/notifications/presentation/services/notification_service.dart';
import '../features/startup/domain/usecases/wait_for_server_ready_use_case.dart';

class AlkozonApp extends StatefulWidget {
  const AlkozonApp({super.key});

  @override
  State<AlkozonApp> createState() => _AlkozonAppState();
}

class _AlkozonAppState extends State<AlkozonApp> {
  final WaitForServerReadyUseCase _waitForServerReady =
      InjectionContainer.I.waitForServerReadyUseCase;
  bool _isWarmingUp = true;

  @override
  void initState() {
    super.initState();
    _warmUpServer();
  }

  Future<void> _warmUpServer() async {
    final warmupTimeout = ApiConfig.isProduction
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);

    try {
      await _waitForServerReady(timeout: warmupTimeout);
    } catch (error) {
      debugPrint(
        'Warmup: backend niedostępny ($warmupTimeout) — przechodzę do logowania: $error',
      );
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
      home: _isWarmingUp ? const _WarmupScreen() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}

class _WarmupScreen extends StatelessWidget {
  const _WarmupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(),
              SizedBox(height: 32),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
