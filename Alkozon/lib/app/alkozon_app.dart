import 'package:flutter/material.dart';

import '../core/di/injection_container.dart';
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
    const overlayCap = Duration(seconds: 20);

    try {
      await _waitForServerReady().timeout(
        overlayCap,
        onTimeout: () {
          debugPrint(
            'Warmup: limit czasu UI ($overlayCap) — przechodzę do logowania.',
          );
        },
      );
    } catch (error) {
      debugPrint('Warmup: $error');
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
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            if (_isWarmingUp)
              const ModalBarrier(dismissible: false, color: Color(0x88FFFFFF)),
            if (_isWarmingUp)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Łączenie z serwerem…',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
