import 'package:flutter/material.dart';

import '../core/connectivity/connectivity_problem_screen.dart';
import '../core/connectivity/connectivity_problem_service.dart';
import '../core/di/injection_container.dart';
import '../core/widgets/app_logo.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/notifications/presentation/services/notification_service.dart';
import '../features/startup/domain/usecases/wait_for_server_ready_use_case.dart';

enum _LaunchPhase { warmup, ready, offline }

class AlkozonApp extends StatefulWidget {
  const AlkozonApp({super.key});

  @override
  State<AlkozonApp> createState() => _AlkozonAppState();
}

class _AlkozonAppState extends State<AlkozonApp> {
  final WaitForServerReadyUseCase _waitForServerReady =
      InjectionContainer.I.waitForServerReadyUseCase;
  _LaunchPhase _phase = _LaunchPhase.warmup;

  @override
  void initState() {
    super.initState();
    _runStartupCheck();
  }

  Future<void> _runStartupCheck() async {
    setState(() {
      _phase = _LaunchPhase.warmup;
    });

    try {
      await _waitForServerReady(
        timeout: const Duration(seconds: 25),
      );
    } catch (error) {
      debugPrint('Startup: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _phase = _LaunchPhase.offline;
      });
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _phase = _LaunchPhase.ready;
    });
  }

  Future<bool> _refreshStartup() async {
    setState(() {
      _phase = _LaunchPhase.warmup;
    });

    try {
      await ConnectivityProblemService.instance.probeServer();
    } catch (error) {
      debugPrint('Startup refresh: $error');
      if (!mounted) {
        return false;
      }
      setState(() {
        _phase = _LaunchPhase.offline;
      });
      return false;
    }

    if (!mounted) {
      return false;
    }
    setState(() {
      _phase = _LaunchPhase.ready;
    });
    return true;
  }

  Widget _buildHome() {
    switch (_phase) {
      case _LaunchPhase.warmup:
        return const _WarmupScreen();
      case _LaunchPhase.offline:
        return ConnectivityProblemScreen(
          popOnSuccess: false,
          onRefresh: _refreshStartup,
        );
      case _LaunchPhase.ready:
        return const LoginPage();
    }
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
      home: _buildHome(),
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
