import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({
    super.key,
    required this.progress,
    required this.remainingSeconds,
  });

  final double progress;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final color = clampedProgress > 0.6
        ? AppTheme.success
        : clampedProgress > 0.3
        ? AppTheme.accentOrange
        : AppTheme.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time: ${remainingSeconds}s',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: clampedProgress,
            backgroundColor: AppTheme.outline,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
