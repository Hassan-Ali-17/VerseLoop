import 'package:flutter/material.dart';
import '../../app/theme/ember_theme.dart';
import 'ember_button.dart';

class ErrorPanel extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorPanel({
    super.key,
    this.title = 'Action Failed',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmberColors.error.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44, color: EmberColors.error),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: EmberColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: EmberColors.textMuted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            EmberButton(
              label: 'Retry Request',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ]
        ],
      ),
    );
  }
}
