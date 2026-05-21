import 'package:flutter/material.dart';

import 'app_logo.dart';

/// Wycentrowany komunikat na całą szerokość (błędy list, mapy itd.).
class AppStatusPanel extends StatelessWidget {
  const AppStatusPanel({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.showLogo = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final bool showLogo;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLogo) ...[
            const AppLogo(size: 56),
            const SizedBox(height: 20),
          ] else if (icon != null) ...[
            Icon(icon, size: 52, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 16),
          ],
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
