import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/badge_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.user?.isAnonymous ?? true;
    final displayName = authProvider.displayName;
    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'G';
    final accountLabel = isGuest
        ? 'Guest Account'
        : (authProvider.user?.email ?? 'Account Linked');

    const pointsPerLevel = 500;
    final level = (provider.lifetimeScore / pointsPerLevel).floor() + 1;
    final currentLevelXp = provider.lifetimeScore % pointsPerLevel;
    final levelProgress = (currentLevelXp / pointsPerLevel).clamp(0.0, 1.0);
    final pointsToNextLevel = currentLevelXp == 0
        ? pointsPerLevel
        : pointsPerLevel - currentLevelXp;
    final earnedBadges = provider.earnedBadges;
    final featuredBadgeType = _selectFeaturedBadge(earnedBadges);
    final featuredBadge = featuredBadgeType == null
        ? null
        : badgeCatalog[featuredBadgeType];
    final featuredRarity = featuredBadgeType == null
        ? _BadgeRarity.common
        : _badgeRarity(featuredBadgeType);
    final rankLabel = isGuest
        ? 'Guest'
        : provider.simulatedLeaderboardRank >= 999
        ? 'Unranked'
        : '#${provider.simulatedLeaderboardRank}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: Stack(
          children: [
            const _ProfileAtmosphere(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Traveler Passport',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary.withValues(alpha: 0.76),
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PassportHeroCard(
                    displayName: displayName,
                    avatarLetter: avatarLetter,
                    accountLabel: accountLabel,
                    level: level,
                    levelTitle: _levelTitle(level),
                    levelProgress: levelProgress,
                    currentLevelXp: currentLevelXp,
                    pointsToNextLevel: pointsToNextLevel,
                    gamesPlayed: provider.gamesPlayed,
                    dailyStreak: provider.dailyChallengeStreak,
                    rankLabel: rankLabel,
                    isGuest: isGuest,
                    nextGoal: _nextGoal(provider),
                    onContinueMission: () {
                      Navigator.pushNamed(context, AppRoutes.modeSelect);
                    },
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _PremiumStatCard(
                        label: 'Total XP',
                        value: provider.lifetimeScore.toString(),
                        color: AppTheme.accentYellow,
                        icon: Icons.stars_rounded,
                      ),
                      _PremiumStatCard(
                        label: 'Best Score',
                        value: provider.bestScore.toString(),
                        color: AppTheme.success,
                        icon: Icons.auto_awesome_rounded,
                      ),
                      _PremiumStatCard(
                        label: 'Games',
                        value: provider.gamesPlayed.toString(),
                        color: AppTheme.accentBlue,
                        icon: Icons.videogame_asset_rounded,
                      ),
                      _PremiumStatCard(
                        label: 'Badges',
                        value: earnedBadges.length.toString(),
                        color: AppTheme.rarityEpic,
                        icon: Icons.military_tech_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FeaturedBadgeCard(
                    badgeType: featuredBadgeType,
                    badge: featuredBadge,
                    rarity: featuredRarity,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Badges Collection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${earnedBadges.length}/${badgeCatalog.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 420 ? 4 : 3;

                      return GridView.builder(
                        itemCount: badgeCatalog.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.96,
                        ),
                        itemBuilder: (context, index) {
                          final entry = badgeCatalog.entries.elementAt(index);
                          final earned = earnedBadges.contains(entry.key);
                          return _BadgeTile(
                            badgeType: entry.key,
                            title: entry.value.title,
                            earned: earned,
                          );
                        },
                      );
                    },
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

class _ProfileAtmosphere extends StatelessWidget {
  const _ProfileAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -100,
            top: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentBlue.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: 180,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentYellow.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportHeroCard extends StatelessWidget {
  const _PassportHeroCard({
    required this.displayName,
    required this.avatarLetter,
    required this.accountLabel,
    required this.level,
    required this.levelTitle,
    required this.levelProgress,
    required this.currentLevelXp,
    required this.pointsToNextLevel,
    required this.gamesPlayed,
    required this.dailyStreak,
    required this.rankLabel,
    required this.isGuest,
    required this.nextGoal,
    required this.onContinueMission,
  });

  final String displayName;
  final String avatarLetter;
  final String accountLabel;
  final int level;
  final String levelTitle;
  final double levelProgress;
  final int currentLevelXp;
  final int pointsToNextLevel;
  final int gamesPlayed;
  final int dailyStreak;
  final String rankLabel;
  final bool isGuest;
  final String nextGoal;
  final VoidCallback onContinueMission;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: AppTheme.profilePassportGradient,
          border: Border.all(
            color: AppTheme.profileHeroBorder.withValues(alpha: 0.82),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.profileGlow.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _XpRingAvatar(letter: avatarLetter, progress: levelProgress),
            const SizedBox(height: 10),
            Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              levelTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.accentYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _HeroMetaChip(
                  icon: Icons.rocket_launch_rounded,
                  value: 'Level $level',
                ),
                _HeroMetaChip(
                  icon: isGuest
                      ? Icons.person_outline_rounded
                      : Icons.emoji_events_rounded,
                  value: rankLabel,
                ),
                _HeroMetaChip(
                  icon: Icons.local_fire_department_rounded,
                  value: '$dailyStreak Day Streak',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.profileGlassSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.profileHeroBorder.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'XP Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$currentLevelXp / 500',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AnimatedXpBar(progress: levelProgress),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '$pointsToNextLevel XP to next level',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary.withValues(alpha: 0.82),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$gamesPlayed journeys',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              accountLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onContinueMission,
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text(nextGoal),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpRingAvatar extends StatelessWidget {
  const _XpRingAvatar({required this.letter, required this.progress});

  final String letter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final visualProgress = progress <= 0 ? 0.0 : math.max(progress, 0.08);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: visualProgress),
      builder: (context, animatedProgress, _) {
        return SizedBox(
          width: 94,
          height: 94,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 94,
                height: 94,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 7,
                  color: AppTheme.profileTrack,
                ),
              ),
              Transform.rotate(
                angle: -math.pi / 2,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        AppTheme.accentYellow,
                        AppTheme.profileXpFill,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: SizedBox(
                    width: 94,
                    height: 94,
                    child: CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 7,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.panel,
                  border: Border.all(
                    color: AppTheme.accentYellow.withValues(alpha: 0.4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedXpBar extends StatelessWidget {
  const _AnimatedXpBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final visualProgress = progress <= 0 ? 0.0 : math.max(progress, 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: visualProgress),
        builder: (context, value, _) {
          return LinearProgressIndicator(
            minHeight: 10,
            value: value,
            backgroundColor: AppTheme.profileTrack,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.profileXpFill,
            ),
          );
        },
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.profileGlass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.profileHeroBorder.withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.textPrimary),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.94),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  const _PremiumStatCard({
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
        color: AppTheme.profileGlassSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.profileHeroBorder.withValues(alpha: 0.56),
        ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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

class _FeaturedBadgeCard extends StatelessWidget {
  const _FeaturedBadgeCard({
    required this.badgeType,
    required this.badge,
    required this.rarity,
  });

  final BadgeType? badgeType;
  final BadgeDefinition? badge;
  final _BadgeRarity rarity;

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(rarity);
    final hasBadge = badgeType != null && badge != null;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppTheme.profileFeaturedBadgeGradient,
          border: Border.all(
            color: hasBadge
                ? rarityColor
                : AppTheme.profileHeroBorder.withValues(alpha: 0.62),
          ),
          boxShadow: hasBadge
              ? [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.3),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasBadge
                    ? rarityColor.withValues(alpha: 0.18)
                    : AppTheme.profileGlass,
                border: Border.all(
                  color: hasBadge ? rarityColor : AppTheme.profileHeroBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                hasBadge ? _iconForBadge(badgeType!) : Icons.lock_outline_rounded,
                color: hasBadge ? rarityColor : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasBadge ? 'Featured Badge' : 'Next Badge Milestone',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBadge ? badge!.title : 'Unlock your first badge',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBadge
                        ? badge!.description
                        : 'Play one round to begin your badge journey.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ),
            ),
            if (hasBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  rarity.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: rarityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badgeType,
    required this.title,
    required this.earned,
  });

  final BadgeType badgeType;
  final String title;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final rarity = _badgeRarity(badgeType);
    final rarityColor = _rarityColor(rarity);
    final lockedColor = AppTheme.panel.withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: earned ? null : lockedColor,
        gradient: earned
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  rarityColor.withValues(alpha: 0.22),
                  AppTheme.profileGlassSoft,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: earned
              ? rarityColor.withValues(alpha: 0.9)
              : AppTheme.profileHeroBorder.withValues(alpha: 0.5),
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            earned ? _iconForBadge(badgeType) : Icons.lock_outline_rounded,
            color: earned
                ? rarityColor
                : AppTheme.textSecondary.withValues(alpha: 0.72),
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: earned
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BadgeRarity { common, rare, epic, legendary }

extension on _BadgeRarity {
  String get label => switch (this) {
    _BadgeRarity.common => 'Common',
    _BadgeRarity.rare => 'Rare',
    _BadgeRarity.epic => 'Epic',
    _BadgeRarity.legendary => 'Legendary',
  };
}

BadgeType? _selectFeaturedBadge(Set<BadgeType> earnedBadges) {
  if (earnedBadges.isEmpty) {
    return null;
  }

  const rankedOrder = <BadgeType>[
    BadgeType.topTenLeaderboard,
    BadgeType.allModesPlayed,
    BadgeType.dailySevenStreak,
    BadgeType.fiftyRounds,
    BadgeType.streakTen,
    BadgeType.perfectCapitalQuiz,
    BadgeType.perfectFlagQuiz,
    BadgeType.firstGame,
  ];

  for (final badge in rankedOrder) {
    if (earnedBadges.contains(badge)) {
      return badge;
    }
  }
  return earnedBadges.first;
}

_BadgeRarity _badgeRarity(BadgeType badgeType) {
  return switch (badgeType) {
    BadgeType.topTenLeaderboard => _BadgeRarity.legendary,
    BadgeType.allModesPlayed || BadgeType.dailySevenStreak => _BadgeRarity.epic,
    BadgeType.fiftyRounds ||
    BadgeType.streakTen ||
    BadgeType.perfectCapitalQuiz ||
    BadgeType.perfectFlagQuiz => _BadgeRarity.rare,
    BadgeType.firstGame => _BadgeRarity.common,
  };
}

Color _rarityColor(_BadgeRarity rarity) {
  return switch (rarity) {
    _BadgeRarity.common => AppTheme.rarityCommon,
    _BadgeRarity.rare => AppTheme.rarityRare,
    _BadgeRarity.epic => AppTheme.rarityEpic,
    _BadgeRarity.legendary => AppTheme.rarityLegendary,
  };
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

String _levelTitle(int level) {
  if (level >= 25) {
    return 'Atlas Legend';
  }
  if (level >= 16) {
    return 'Geo Strategist';
  }
  if (level >= 10) {
    return 'World Pathfinder';
  }
  if (level >= 5) {
    return 'Region Scout';
  }
  return 'Rookie Explorer';
}

String _nextGoal(QuizProvider provider) {
  if (provider.gamesPlayed == 0) {
    return 'Play First Mission';
  }
  if (provider.dailyChallengeStreak < 7) {
    return 'Push Daily Streak';
  }
  if (!provider.earnedBadges.contains(BadgeType.allModesPlayed)) {
    return 'Unlock Mode Master';
  }
  return 'Start New Challenge';
}

