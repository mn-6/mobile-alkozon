import 'package:flutter/material.dart';

import '../widgets/app_logo.dart';

/// Pełnoekranowy komunikat o problemie z łącznością (wygląd jak reszta aplikacji).
class ConnectivityProblemScreen extends StatefulWidget {
  const ConnectivityProblemScreen({
    super.key,
    required this.onRefresh,
    this.popOnSuccess = true,
  });

  final Future<bool> Function() onRefresh;
  final bool popOnSuccess;

  @override
  State<ConnectivityProblemScreen> createState() =>
      _ConnectivityProblemScreenState();
}

class _ConnectivityProblemScreenState extends State<ConnectivityProblemScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    final restored = await widget.onRefresh();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshing = false;
    });

    if (restored && widget.popOnSuccess) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 96),
              const Center(child: AppLogo()),
              const Spacer(),
              const Text(
                'Problem z łącznością.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isRefreshing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Odśwież',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
