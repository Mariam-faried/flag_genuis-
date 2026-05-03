import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AnswerButton extends StatefulWidget {
  const AnswerButton({
    super.key,
    required this.optionIndex,
    required this.label,
    required this.onTap,
    this.isCorrect = false,
    this.isWrong = false,
    this.isDisabled = false,
  });

  final int optionIndex;
  final String label;
  final VoidCallback? onTap;
  final bool isCorrect;
  final bool isWrong;
  final bool isDisabled;

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton> {
  bool _pressed = false;

  String _optionToken(int index) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (index >= 0 && index < letters.length) {
      return letters[index];
    }
    return '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.isCorrect;
    final isWrong = widget.isWrong;
    final isDisabled = widget.isDisabled;

    Color border = AppTheme.outline;
    Color text = AppTheme.textPrimary;
    Color badgeFill = AppTheme.accentBlue.withValues(alpha: 0.28);
    Color badgeBorder = AppTheme.accentBlue.withValues(alpha: 0.48);
    Color badgeText = AppTheme.textPrimary;
    LinearGradient gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1D2A57), Color(0xFF152047)],
    );
    BoxShadow shadow = const BoxShadow(
      color: Color(0x24000000),
      blurRadius: 14,
      offset: Offset(0, 6),
    );

    if (isCorrect) {
      border = AppTheme.success;
      text = AppTheme.textPrimary;
      badgeFill = AppTheme.success.withValues(alpha: 0.28);
      badgeBorder = AppTheme.success.withValues(alpha: 0.64);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.success.withValues(alpha: 0.30),
          AppTheme.success.withValues(alpha: 0.18),
        ],
      );
      shadow = BoxShadow(
        color: AppTheme.success.withValues(alpha: 0.25),
        blurRadius: 20,
        offset: const Offset(0, 8),
      );
    } else if (isWrong) {
      border = AppTheme.danger;
      text = AppTheme.textPrimary;
      badgeFill = AppTheme.danger.withValues(alpha: 0.24);
      badgeBorder = AppTheme.danger.withValues(alpha: 0.58);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.danger.withValues(alpha: 0.24),
          AppTheme.danger.withValues(alpha: 0.12),
        ],
      );
      shadow = BoxShadow(
        color: AppTheme.danger.withValues(alpha: 0.22),
        blurRadius: 18,
        offset: const Offset(0, 8),
      );
    } else if (isDisabled) {
      border = AppTheme.outline;
      text = AppTheme.textSecondary;
      badgeFill = AppTheme.outline.withValues(alpha: 0.25);
      badgeBorder = AppTheme.outline.withValues(alpha: 0.55);
      badgeText = AppTheme.textSecondary;
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.panelSoft.withValues(alpha: 0.95),
          AppTheme.panel.withValues(alpha: 0.95),
        ],
      );
      shadow = const BoxShadow(
        color: Color(0x18000000),
        blurRadius: 10,
        offset: Offset(0, 4),
      );
    }

    final trailingIcon = isCorrect
        ? const Icon(
            Icons.check_circle_rounded,
            key: ValueKey('correct'),
            color: AppTheme.success,
          )
        : isWrong
        ? const Icon(
            Icons.cancel_rounded,
            key: ValueKey('wrong'),
            color: AppTheme.danger,
          )
        : isDisabled
        ? Icon(
            Icons.circle_outlined,
            key: const ValueKey('disabled'),
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            size: 20,
          )
        : Icon(
            Icons.arrow_forward_ios_rounded,
            key: const ValueKey('idle'),
            color: AppTheme.textSecondary.withValues(alpha: 0.85),
            size: 16,
          );

    return Semantics(
      button: true,
      enabled: !isDisabled,
      selected: isCorrect || isWrong,
      label: 'Option ${_optionToken(widget.optionIndex)} ${widget.label}',
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        scale: _pressed && !isDisabled ? 0.985 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled ? null : widget.onTap,
            borderRadius: BorderRadius.circular(18),
            onHighlightChanged: (highlighted) {
              if (_pressed == highlighted) {
                return;
              }
              setState(() {
                _pressed = highlighted;
              });
            },
            splashColor: AppTheme.accentBlue.withValues(alpha: 0.16),
            highlightColor: AppTheme.accentBlue.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: 1.2),
                boxShadow: [shadow],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Text(
                      _optionToken(widget.optionIndex),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: badgeText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: trailingIcon,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
