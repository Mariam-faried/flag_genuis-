import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/badge_model.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';
import '../providers/quiz_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final result = provider.lastRoundResult;

    if (result == null) {
      return const _NoSummaryView();
    }

    final isPersonalBest = result.score >= provider.bestScore;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: Stack(
          children: [
            const _SummaryAtmosphere(),
            SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const _SummaryHeader(),
                  const SizedBox(height: 12),
                  _SummaryHeroCard(
                    result: result,
                    isPersonalBest: isPersonalBest,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _MetricCard(
                        label: 'Correct',
                        value: result.correctAnswers.toString(),
                        color: AppTheme.success,
                        icon: Icons.check_circle_rounded,
                      ),
                      _MetricCard(
                        label: 'Wrong',
                        value: result.wrongAnswers.toString(),
                        color: AppTheme.danger,
                        icon: Icons.cancel_rounded,
                      ),
                      _MetricCard(
                        label: 'Best Streak',
                        value: result.longestStreak.toString(),
                        color: AppTheme.accentOrange,
                        icon: Icons.local_fire_department_rounded,
                      ),
                      _MetricCard(
                        label: 'Accuracy',
                        value: '${result.accuracyPercent.toStringAsFixed(1)}%',
                        color: AppTheme.accentBlue,
                        icon: Icons.track_changes_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BadgeSection(newBadges: result.newBadges),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentYellow, AppTheme.accentOrange],
                      ),
                      boxShadow: const [AppTheme.glowYellow],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.modeSelect,
                        (_) => false,
                      ),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (_) => false,
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSummaryView extends StatelessWidget {
  const _NoSummaryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: AppTheme.accentBlue,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No summary available yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete a round and your results will appear here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (_) => false,
                    ),
                    child: const Text('Go Home'),
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: Column(
            children: [
              Text(
                'Round Summary',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Mission Debrief',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary.withValues(alpha: 0.78),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({
    required this.result,
    required this.isPersonalBest,
  });

  final QuizResultModel result;
  final bool isPersonalBest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: AppTheme.summaryHeroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.summaryHeroBorder),
        boxShadow: const [AppTheme.glowBlue],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.accentYellow,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Round Complete!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ResultPill(
                icon: _iconForMode(result.mode),
                label: result.mode.label,
              ),
              _ResultPill(
                icon: _iconForDifficulty(result.difficulty),
                label: result.difficulty.label,
              ),
              _ResultPill(
                icon: Icons.format_list_numbered_rounded,
                label: '${result.totalAnswered} Questions',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StarMeter(filledStars: result.stars),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: result.score),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '$value',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.accentYellow,
                  fontSize: 58,
                ),
              );
            },
          ),
          Text(
            isPersonalBest
                ? 'Personal Best Performance'
                : 'Great progress, keep climbing',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (result.accuracyPercent / 100).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: AppTheme.panelSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.accentYellow,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Accuracy',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${result.accuracyPercent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarMeter extends StatelessWidget {
  const _StarMeter({required this.filledStars});

  final int filledStars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filledStars out of 3 stars',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: Duration(milliseconds: 280 + (index * 120)),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Icon(
              index < filledStars
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 36,
              color: AppTheme.accentYellow,
            ),
          );
        }),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.summaryChipBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.summaryChipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.textPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.22),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSection extends StatelessWidget {
  const _BadgeSection({required this.newBadges});

  final Set<BadgeType> newBadges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Badges Unlocked',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (newBadges.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${newBadges.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentYellow,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (newBadges.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.panelSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                'No new badges this round. Push your streak to unlock rarer rewards.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: newBadges.map((badge) {
                final meta = badgeCatalog[badge];
                return _BadgeTile(
                  title: meta?.title ?? badge.name,
                  description: meta?.description ?? 'Achievement unlocked',
                  icon: _iconForBadge(badge),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentYellow.withValues(alpha: 0.2),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppTheme.accentYellow),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryAtmosphere extends StatelessWidget {
  const _SummaryAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -110,
            top: -80,
            child: Container(
              width: 230,
              height: 230,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.summaryAtmosphereBlue,
              ),
            ),
          ),
          Positioned(
            right: -70,
            top: 210,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.summaryAtmosphereGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForBadge(BadgeType badgeType) {
  return switch (badgeType) {
    BadgeType.firstGame => Icons.public_rounded,
    BadgeType.perfectFlagQuiz => Icons.flag_rounded,
    BadgeType.perfectCapitalQuiz => Icons.location_city_rounded,
    BadgeType.streakTen => Icons.local_fire_department_rounded,
    BadgeType.topTenLeaderboard => Icons.emoji_events_rounded,
    BadgeType.fiftyRounds => Icons.explore_rounded,
    BadgeType.dailySevenStreak => Icons.calendar_month_rounded,
    BadgeType.allModesPlayed => Icons.hub_rounded,
  };
}

IconData _iconForMode(QuizMode mode) {
  return switch (mode) {
    QuizMode.flag => Icons.flag_rounded,
    QuizMode.capital => Icons.location_city_rounded,
    QuizMode.population => Icons.groups_rounded,
    QuizMode.region => Icons.public_rounded,
    QuizMode.randomMix => Icons.shuffle_rounded,
  };
}

IconData _iconForDifficulty(QuizDifficulty difficulty) {
  return switch (difficulty) {
    QuizDifficulty.easy => Icons.sentiment_satisfied_alt_rounded,
    QuizDifficulty.medium => Icons.bolt_rounded,
    QuizDifficulty.hard => Icons.local_fire_department_rounded,
  };
}
