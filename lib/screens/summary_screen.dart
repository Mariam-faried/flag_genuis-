import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/badge_model.dart';
import '../providers/quiz_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final result = provider.lastRoundResult;

    if (result == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBackgroundGradient,
          ),
          child: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (_) => false,
              ),
              child: const Text('Go Home'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (_) => false,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Round Summary',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    Text(
                      'Round Complete!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(3, (index) {
                        return Icon(
                          index < result.stars ? Icons.star : Icons.star_border,
                          size: 38,
                          color: AppTheme.accentYellow,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.score.toString(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.accentYellow,
                        fontSize: 58,
                      ),
                    ),
                    Text(
                      provider.bestScore == result.score
                          ? 'Personal Best!'
                          : 'Keep pushing your high score',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.55,
                      children: [
                        _MetricCard(
                          label: 'Correct',
                          value: result.correctAnswers.toString(),
                          color: AppTheme.success,
                        ),
                        _MetricCard(
                          label: 'Wrong',
                          value: result.wrongAnswers.toString(),
                          color: AppTheme.danger,
                        ),
                        _MetricCard(
                          label: 'Best Streak',
                          value: result.longestStreak.toString(),
                          color: AppTheme.accentYellow,
                        ),
                        _MetricCard(
                          label: 'Accuracy',
                          value: '${result.accuracyPercent.toStringAsFixed(1)}%',
                          color: AppTheme.accentBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Badges Unlocked',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (result.newBadges.isEmpty)
                      Text(
                        'No new badges this round.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.newBadges.map((badge) {
                          final meta = badgeCatalog[badge];
                          return Chip(
                            avatar: const Icon(
                              Icons.military_tech,
                              size: 18,
                              color: AppTheme.accentYellow,
                            ),
                            label: Text(meta?.title ?? badge.name),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentYellow, AppTheme.accentOrange],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.modeSelect,
                    (_) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (_) => false,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
