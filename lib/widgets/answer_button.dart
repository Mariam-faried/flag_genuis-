import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isCorrect = false,
    this.isWrong = false,
    this.isDisabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isCorrect;
  final bool isWrong;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    Color background = AppTheme.panelSoft;
    Color border = AppTheme.outline;
    Color text = AppTheme.textPrimary;

    if (isCorrect) {
      background = AppTheme.success.withValues(alpha: 0.2);
      border = AppTheme.success;
      text = AppTheme.textPrimary;
    } else if (isWrong) {
      background = AppTheme.danger.withValues(alpha: 0.16);
      border = AppTheme.danger;
      text = AppTheme.textPrimary;
    } else if (isDisabled) {
      background = AppTheme.panelSoft.withValues(alpha: 0.7);
      border = AppTheme.outline;
      text = AppTheme.textSecondary;
    }

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle, color: AppTheme.success)
            else if (isWrong)
              const Icon(Icons.cancel, color: AppTheme.danger),
          ],
        ),
      ),
    );
  }
}
