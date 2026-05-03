import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/question_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _homeTab = 0;

  void _onNavTapped(int index) {
    if (index == _homeTab) {
      return;
    }               

    final route = switch (index) {
      1 => AppRoutes.leaderboard,
      2 => AppRoutes.profile,
      _ => AppRoutes.settings,
    };
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final firestoreService = context.read<FirestoreService>();
    final hasCompletedDailyChallenge =
        !quizProvider.canCompleteDailyChallengeToday;
    final displayName = authProvider.displayName.trim();
    final firstName = _homeGreetingName(displayName);

    final modeCards = <_ModeCardData>[
      _ModeCardData(
        icon: Icons.flag_rounded,
        title: 'Flag Quiz',
        description: 'Match every flag with its country.',
        mode: QuizMode.flag,
        onTap: () => _openModeSelection(context, QuizMode.flag),
      ),
      _ModeCardData(
        icon: Icons.location_city_rounded,
        title: 'Capitals',
        description: 'Select the correct capital city.',
        mode: QuizMode.capital,
        onTap: () => _openModeSelection(context, QuizMode.capital),
      ),
      _ModeCardData(
        icon: Icons.groups_rounded,
        title: 'Population',
        description: 'Use clues to pick the right nation.',
        mode: QuizMode.population,
        onTap: () => _openModeSelection(context, QuizMode.population),
      ),
      _ModeCardData(
        icon: Icons.map_rounded,
        title: 'Regions',
        description: 'Find where each country belongs.',
        mode: QuizMode.region,
        onTap: () => _openModeSelection(context, QuizMode.region),
      ),
      _ModeCardData(
        icon: Icons.casino_rounded,
        title: 'Random Mix',
        description: 'Get a blended challenge every round.',
        mode: QuizMode.randomMix,
        onTap: () => _openModeSelection(context, QuizMode.randomMix),
      ),
    ];
    final explorerCard = _ModeCardData(
      icon: Icons.travel_explore_rounded,
      title: 'Explorer',
      description: 'Browse countries and learn fast facts.',
      customGradient: AppTheme.homeExplorerGradient,
      onTap: () => Navigator.pushNamed(context, AppRoutes.explorer),
    );
    final featuredMode = modeCards.first;
    final secondaryModes = modeCards.skip(1).toList(growable: false);
    final totalModesCount = modeCards.length;
    final explorerAnimationIndex = secondaryModes.length + 1;
    final nextUnlockLabel = _formatUnlockCountdown(_timeUntilNextDailyUnlock());

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeLayeredBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _PremiumHeader(
                      greeting: _timeBasedGreeting(),
                      firstName: firstName,
                      onProfileTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      onSettingsTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                      statChips: [
                        _HeaderStatData(
                          label: 'Pts',
                          value: quizProvider.lifetimeScore.toString(),
                          icon: Icons.emoji_events_rounded,
                        ),
                        _HeaderStatData(
                          label: 'Streak',
                          value: quizProvider.dailyChallengeStreak.toString(),
                          icon: Icons.local_fire_department_rounded,
                        ),
                        _HeaderStatData(
                          label: 'Games',
                          value: quizProvider.gamesPlayed.toString(),
                          icon: Icons.sports_esports_rounded,
                        ),
                        const _HeaderStatData(
                          label: 'Countries',
                          value: '250',
                          icon: Icons.public_rounded,
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0, duration: 400.ms),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 98),
                    child: Column(
                      children: [
                        Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: _DailyChallengeCard(
                                hasCompletedDailyChallenge:
                                    hasCompletedDailyChallenge,
                                challengeMode:
                                    quizProvider.todayDailyChallengeMode.label,
                                challengeDifficulty: quizProvider
                                    .todayDailyChallengeDifficulty
                                    .label,
                                streakDays: quizProvider.dailyChallengeStreak,
                                nextUnlockLabel: nextUnlockLabel,
                                onPracticePressed: () => _openModeSelection(
                                  context,
                                  quizProvider.todayDailyChallengeMode,
                                ),
                                onPlayPressed: hasCompletedDailyChallenge
                                    ? null
                                    : () async {
                                        final provider = context
                                            .read<QuizProvider>();
                                        final started = await provider
                                            .startDailyChallengeRound();
                                        if (!context.mounted) {
                                          return;
                                        }
                                        if (!started) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                quizProvider.loadError ??
                                                    'Could not start daily challenge.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (provider
                                            .isUsingLocalDailyChallengeFallback) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                provider.dailyChallengeNotice ??
                                                    'Running local daily challenge mode.',
                                              ),
                                            ),
                                          );
                                        }
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.quiz,
                                        );
                                      },
                              ),
                            )
                            .animate()
                            .slideY(begin: 0.3, duration: 500.ms)
                            .fadeIn(duration: 500.ms),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                              child: Row(
                                children: [
                                  Text(
                                    'Quiz Modes',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$totalModesCount modes',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accentYellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: Column(
                                children: [
                                  _FeaturedModeCard(data: featuredMode)
                                      .animate()
                                      .fadeIn(delay: 0.ms, duration: 400.ms)
                                      .slideY(begin: 0.2, end: 0),
                                  const SizedBox(height: 10),
                                  GridView.builder(
                                    itemCount: secondaryModes.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 1.03,
                                        ),
                                    itemBuilder: (context, index) {
                                      final cardIndex = index + 1;
                                      return _PremiumModeCard(
                                            data: secondaryModes[index],
                                          )
                                          .animate()
                                          .fadeIn(
                                            delay: (cardIndex * 80).ms,
                                            duration: 400.ms,
                                          )
                                          .slideY(begin: 0.2, end: 0);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _ExplorerWideCard(data: explorerCard)
                                      .animate()
                                      .fadeIn(
                                        delay: (explorerAnimationIndex * 80).ms,
                                        duration: 400.ms,
                                      )
                                      .slideY(begin: 0.2, end: 0),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                          child: _MiniLeaderboardCard(
                            stream: firestoreService.watchTopLeaderboard(
                              limit: 3,
                            ),
                            onSeeAll: () => Navigator.pushNamed(
                              context,
                              AppRoutes.leaderboard,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PremiumBottomNavigation(
        selectedIndex: _homeTab,
        onTap: _onNavTapped,
      ),
    );
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  void _openModeSelection(BuildContext context, QuizMode mode) {
    Navigator.pushNamed(context, AppRoutes.modeSelect, arguments: mode);
  }

  Duration _timeUntilNextDailyUnlock() {
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    return nextDay.difference(now);
  }

  String _formatUnlockCountdown(Duration duration) {
    final totalMinutes = duration.inMinutes.clamp(0, 24 * 60);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final hourText = hours.toString().padLeft(2, '0');
    final minuteText = minutes.toString().padLeft(2, '0');
    return '${hourText}h ${minuteText}m';
  }

  String _homeGreetingName(String displayName) {
    if (displayName.isEmpty) {
      return 'Explorer';
    }

    // Keep the unique guest suffix visible (for example "Guest a1b2c3")
    // so the name matches leaderboard/profile identity.
    if (displayName.startsWith('Guest ')) {
      return displayName;
    }

    return displayName.split(' ').first;
  }
}

class _HomeLayeredBackground extends StatelessWidget {
  const _HomeLayeredBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.homeBackgroundBaseGradient,
              ),
            ),
          ),
          Positioned(
            top: -170,
            right: -130,
            child: _BackgroundAura(
              size: 380,
              color: Color(0x55366DE0),
            ),
          ),
          Positioned(
            top: 220,
            left: -120,
            child: _BackgroundAura(
              size: 300,
              color: Color(0x3333A0B4),
            ),
          ),
          Positioned(
            bottom: -180,
            right: -80,
            child: _BackgroundAura(
              size: 340,
              color: Color(0x3D8351D5),
            ),
          ),
          Positioned.fill(child: _GeoTextureOverlay()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.homeBackgroundVeilGradient,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundAura extends StatelessWidget {
  const _BackgroundAura({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _GeoTextureOverlay extends StatelessWidget {
  const _GeoTextureOverlay();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const RadialGradient(
          center: Alignment(0, -0.22),
          radius: 1.04,
          colors: [Colors.white, Color(0xCFFFFFFF), Color(0x00FFFFFF)],
          stops: [0, 0.68, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: const SizedBox.expand(child: CustomPaint(painter: _GeoTexturePainter())),
    );
  }
}

class _GeoTexturePainter extends CustomPainter {
  const _GeoTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final latPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.homeTextureLine;
    final lonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.homeTextureAccent;

    const latitudeCount = 7;
    for (var index = 0; index < latitudeCount; index++) {
      final t = index / (latitudeCount - 1);
      final y = size.height * (0.17 + (0.64 * t));
      final curve = math.sin((t - 0.5) * math.pi) * 26;
      final path = Path()
        ..moveTo(-size.width * 0.06, y)
        ..quadraticBezierTo(size.width * 0.5, y + curve, size.width * 1.06, y);
      canvas.drawPath(path, latPaint);
    }

    const longitudeCount = 8;
    for (var index = 0; index < longitudeCount; index++) {
      final t = index / (longitudeCount - 1);
      final x = size.width * (0.08 + (0.84 * t));
      final sweep = (t - 0.5) * 42;
      final path = Path()
        ..moveTo(x, -size.height * 0.06)
        ..quadraticBezierTo(
          x + sweep,
          size.height * 0.5,
          x,
          size.height * 1.06,
        );
      canvas.drawPath(path, lonPaint);
    }

    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppTheme.homeTextureLine.withValues(alpha: 0.18);
    final routePath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.58,
        size.width * 0.56,
        size.height * 0.86,
        size.width * 0.84,
        size.height * 0.62,
      );
    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant _GeoTexturePainter oldDelegate) => false;
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.greeting,
    required this.firstName,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.statChips,
  });

  final String greeting;
  final String firstName;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final List<_HeaderStatData> statChips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppTheme.homeHeaderGradient,
        border: Border(
          bottom: BorderSide(color: AppTheme.homeHeaderBorder, width: 1),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -70,
            right: -45,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentBlue.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: GoogleFonts.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List<Widget>.generate(statChips.length, (
                          index,
                        ) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == statChips.length - 1 ? 0 : 8,
                            ),
                            child: _HeaderStatChip(data: statChips[index]),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  _HeaderCircleAction(
                    icon: Icons.person_outline_rounded,
                    onTap: onProfileTap,
                  ),
                  const SizedBox(height: 8),
                  _HeaderCircleAction(
                    icon: Icons.settings_outlined,
                    onTap: onSettingsTap,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCircleAction extends StatelessWidget {
  const _HeaderCircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.textPrimary.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 19, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

class _HeaderStatData {
  const _HeaderStatData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _HeaderStatChip extends StatelessWidget {
  const _HeaderStatChip({required this.data});

  final _HeaderStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: AppTheme.textPrimary),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1,
                ),
              ),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary.withValues(alpha: 0.6),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.hasCompletedDailyChallenge,
    required this.challengeMode,
    required this.challengeDifficulty,
    required this.streakDays,
    required this.nextUnlockLabel,
    required this.onPracticePressed,
    required this.onPlayPressed,
  });

  final bool hasCompletedDailyChallenge;
  final String challengeMode;
  final String challengeDifficulty;
  final int streakDays;
  final String nextUnlockLabel;
  final VoidCallback onPracticePressed;
  final VoidCallback? onPlayPressed;

  @override
  Widget build(BuildContext context) {
    final canPlay = onPlayPressed != null;
    final actionLabel = canPlay ? 'Play now ->' : 'Practice mode';
    final actionGradient = canPlay
        ? AppTheme.goldGradient
        : const LinearGradient(colors: [AppTheme.panelSoft, AppTheme.panel]);
    final actionTextColor = canPlay ? AppTheme.onGold : AppTheme.textPrimary;
    final statusText = hasCompletedDailyChallenge
        ? 'Next challenge unlocks in $nextUnlockLabel'
        : 'Available now';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.homeDailyGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.homeCardBorder.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: const [AppTheme.homeCardShadow],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -22,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            left: -18,
            child: IgnorePointer(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentBlue.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'DAILY CHALLENGE',
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.onGold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasCompletedDailyChallenge
                          ? Icons.calendar_today_rounded
                          : Icons.local_fire_department_rounded,
                      size: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasCompletedDailyChallenge
                    ? 'Daily challenge complete. Great consistency today.'
                    : 'Complete today\'s challenge and extend your streak.',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today: $challengeMode - $challengeDifficulty',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: canPlay ? onPlayPressed : onPracticePressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: actionGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: canPlay
                                ? AppTheme.accentYellow.withValues(alpha: 0.28)
                                : AppTheme.outline.withValues(alpha: 0.75),
                          ),
                          boxShadow: canPlay
                              ? const [AppTheme.glowYellow]
                              : const [AppTheme.cardShadow],
                        ),
                        child: Text(
                          actionLabel,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: actionTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Day ${streakDays <= 0 ? 1 : streakDays} streak',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeCardData {
  const _ModeCardData({
    required this.icon,
    required this.title,
    required this.description,
    this.mode,
    this.customGradient,
    required this.onTap,
  }) : assert(
         mode != null || customGradient != null,
         'Either mode or customGradient must be provided.',
       );

  final IconData icon;
  final String title;
  final String description;
  final QuizMode? mode;
  final LinearGradient? customGradient;
  final VoidCallback onTap;
}

class _FeaturedModeCard extends StatelessWidget {
  const _FeaturedModeCard({required this.data});

  final _ModeCardData data;

  @override
  Widget build(BuildContext context) {
    final modeGradient = data.mode != null
        ? AppTheme.homeModeColor(data.mode!)
        : data.customGradient!;

    return SizedBox(
      height: 168,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: modeGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: AppTheme.homeCardBorder.withValues(alpha: 0.7),
              ),
              boxShadow: const [AppTheme.homeCardShadow],
            ),
          ),
          Positioned(
            top: -44,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.textPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          _HapticScaleInkWell(
            onTap: data.onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            pressedScale: 0.986,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'FEATURED',
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppTheme.textPrimary.withValues(alpha: 0.86),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(data.icon, color: AppTheme.textPrimary, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    data.title,
                    style: GoogleFonts.baloo2(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary.withValues(alpha: 0.78),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumModeCard extends StatelessWidget {
  const _PremiumModeCard({required this.data});

  final _ModeCardData data;

  @override
  Widget build(BuildContext context) {
    final modeGradient = data.mode != null
        ? AppTheme.homeModeColor(data.mode!)
        : data.customGradient!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: modeGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.homeCardBorder.withValues(alpha: 0.68),
            ),
            boxShadow: const [AppTheme.homeCardShadow],
          ),
        ),
        Positioned(
          bottom: -20,
          right: -20,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.textPrimary.withValues(alpha: 0.07),
            ),
          ),
        ),
        _HapticScaleInkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          pressedScale: 0.97,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(data.icon, color: AppTheme.textPrimary, size: 28),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: AppTheme.textPrimary.withValues(alpha: 0.44),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExplorerWideCard extends StatelessWidget {
  const _ExplorerWideCard({required this.data});

  final _ModeCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.homeExplorerGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.homeCardBorder.withValues(alpha: 0.78),
              width: 1,
            ),
            boxShadow: const [AppTheme.homeCardShadow],
          ),
        child: _HapticScaleInkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          pressedScale: 0.985,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.textPrimary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.textPrimary.withValues(alpha: 0.15),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(data.icon, size: 20, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppTheme.textPrimary.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniLeaderboardCard extends StatelessWidget {
  const _MiniLeaderboardCard({required this.stream, required this.onSeeAll});

  final Stream<List<LeaderboardEntryModel>> stream;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.homeSectionGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.homeCardBorder.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: const [AppTheme.homeCardShadow],
      ),
      child: StreamBuilder<List<LeaderboardEntryModel>>(
        stream: stream,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <LeaderboardEntryModel>[];
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              entries.isEmpty;
          final hasError = snapshot.hasError && entries.isEmpty;
          final rows = List<LeaderboardEntryModel?>.generate(3, (index) {
            return index < entries.length ? entries[index] : null;
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 20,
                    color: AppTheme.accentYellow,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Top Players',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _HapticScaleInkWell(
                    onTap: onSeeAll,
                    borderRadius: BorderRadius.circular(10),
                    pressedScale: 0.97,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Text(
                        'See all ->',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentYellow,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const _LeaderboardSkeleton()
              else if (hasError)
                const _LeaderboardMessageState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Leaderboard unavailable',
                  subtitle: 'Check your connection. We will retry shortly.',
                )
              else if (entries.isEmpty)
                const _LeaderboardMessageState(
                  icon: Icons.rocket_launch_rounded,
                  title: 'Be the first on the board',
                  subtitle: 'Play a round and claim rank #1.',
                )
              else
                ...List<Widget>.generate(rows.length, (index) {
                  return _TopPlayerRow(
                    rankIndex: index,
                    entry: rows[index],
                    showDivider: index != rows.length - 1,
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(3, (index) {
        return _LeaderboardSkeletonRow(showDivider: index != 2);
      }),
    );
  }
}

class _LeaderboardSkeletonRow extends StatelessWidget {
  const _LeaderboardSkeletonRow({required this.showDivider});

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const _SkeletonBox(width: 18, height: 18, radius: 9),
              const SizedBox(width: 8),
              const _SkeletonBox(width: 36, height: 36, radius: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 96, height: 12, radius: 6),
                    SizedBox(height: 6),
                    _SkeletonBox(width: 68, height: 10, radius: 5),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _SkeletonBox(width: 34, height: 12, radius: 6),
            ],
          ),
        ),
        if (showDivider)
          const Divider(color: AppTheme.outline, height: 1, thickness: 0.5),
      ],
    );
  }
}

class _LeaderboardMessageState extends StatelessWidget {
  const _LeaderboardMessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.textPrimary.withValues(alpha: 0.08),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppTheme.accentYellow),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.panelSoft, AppTheme.card],
        ),
      ),
    );
  }
}

class _TopPlayerRow extends StatelessWidget {
  const _TopPlayerRow({
    required this.rankIndex,
    required this.entry,
    required this.showDivider,
  });

  final int rankIndex;
  final LeaderboardEntryModel? entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = entry == null;
    final medalColor = isPlaceholder
        ? AppTheme.textSecondary.withValues(alpha: 0.55)
        : switch (rankIndex) {
            0 => AppTheme.medalGold,
            1 => AppTheme.medalSilver,
            _ => AppTheme.medalBronze,
          };
    final initials = isPlaceholder
        ? '?'
        : _initialsFromName(entry!.displayName);
    final displayName = isPlaceholder ? 'Open spot' : entry!.displayName;
    final rankLabel = isPlaceholder
        ? 'Play now to claim rank #${rankIndex + 1}'
        : 'Rank #${rankIndex + 1}';
    final scoreText = isPlaceholder ? null : entry!.bestScore.toString();
    final scoreColor = isPlaceholder
        ? AppTheme.textSecondary
        : AppTheme.accentYellow;

    final avatarGradient = isPlaceholder
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.panelSoft, AppTheme.panel],
          )
        : switch (rankIndex) {
            0 => AppTheme.goldGradient,
            1 => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.textSecondary, AppTheme.medalSilver],
            ),
            _ => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accentOrange, AppTheme.medalBronze],
            ),
          };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 20,
                color: medalColor,
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: avatarGradient,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isPlaceholder
                        ? AppTheme.textSecondary
                        : AppTheme.onGold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isPlaceholder
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      rankLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (scoreText != null)
                Text(
                  scoreText,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.outline.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    'Join',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(color: AppTheme.outline, height: 1, thickness: 0.5),
      ],
    );
  }

  String _initialsFromName(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      return '?';
    }
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _HapticScaleInkWell extends StatefulWidget {
  const _HapticScaleInkWell({
    required this.onTap,
    required this.borderRadius,
    required this.child,
    this.pressedScale = 0.97,
  });

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;
  final double pressedScale;

  @override
  State<_HapticScaleInkWell> createState() => _HapticScaleInkWellState();
}

class _HapticScaleInkWellState extends State<_HapticScaleInkWell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onHighlightChanged: (value) {
            if (_pressed == value) {
              return;
            }
            setState(() {
              _pressed = value;
            });
          },
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _PremiumBottomNavigation extends StatelessWidget {
  const _PremiumBottomNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = <_NavItemData>[
      _NavItemData(index: 0, icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(index: 1, icon: Icons.emoji_events_rounded, label: 'Ranks'),
      _NavItemData(index: 2, icon: Icons.person_rounded, label: 'Profile'),
      _NavItemData(index: 3, icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border(
          top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.75)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: items
                .map((item) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 4,
                      ),
                      child: _PremiumNavItem(
                        item: item,
                        selected: selectedIndex == item.index,
                        onTap: () => onTap(item.index),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _PremiumNavItem extends StatelessWidget {
  const _PremiumNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.textPrimary;
    final inactiveColor = AppTheme.textSecondary;
    final color = selected ? activeColor : inactiveColor;

    return _HapticScaleInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentYellow.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.accentYellow.withValues(alpha: 0.17)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: selected ? 12 : 4,
              height: 3,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accentYellow
                    : AppTheme.textSecondary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.index,
    required this.icon,
    required this.label,
  });

  final int index;
  final IconData icon;
  final String label;
}
