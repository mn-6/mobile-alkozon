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
  String? _warmupError;

  @override
  void initState() {
    super.initState();
    _warmUpServer();
  }

  Future<void> _warmUpServer() async {
    try {
      await _waitForServerReady();
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
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
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
