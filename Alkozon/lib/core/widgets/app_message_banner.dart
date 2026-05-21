import 'package:flutter/material.dart';

enum AppMessageKind { error, info, success }

class AppMessageBanner extends StatelessWidget {
  const AppMessageBanner({
    super.key,
    required this.message,
    this.kind = AppMessageKind.error,
  });

  final String message;
  final AppMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final Color foreground;
    final Color background;
    final Color border;

    switch (kind) {
      case AppMessageKind.error:
        foreground = Colors.red.shade700;
        background = Colors.red.withValues(alpha: 0.08);
        border = Colors.red.withValues(alpha: 0.35);
      case AppMessageKind.info:
        foreground = Colors.blue.shade700;
        background = Colors.blue.withValues(alpha: 0.08);
        border = Colors.blue.withValues(alpha: 0.35);
      case AppMessageKind.success:
        foreground = Colors.green.shade700;
        background = Colors.green.withValues(alpha: 0.08);
        border = Colors.green.withValues(alpha: 0.35);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: foreground, fontSize: 14, height: 1.35),
      ),
    );
  }
}
