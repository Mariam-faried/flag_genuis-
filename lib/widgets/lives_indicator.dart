import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class LivesIndicator extends StatelessWidget {
  const LivesIndicator({super.key, required this.lives, this.maxLives = 3});

  final int lives;
  final int maxLives;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(maxLives, (index) {
        final active = index < lives;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            active ? Icons.favorite : Icons.favorite_border,
            color: active ? AppTheme.danger : AppTheme.textSecondary,
            size: 20,
          ),
        );
      }),
    );
  }
}
