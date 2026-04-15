import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/question_model.dart';
import '../providers/quiz_provider.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  QuizMode _selectedMode = QuizMode.flag;
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;
  bool _didLoadArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArguments) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is QuizMode) {
      _selectedMode = args;
    }
    _didLoadArguments = true;
  }

  void _selectDifficulty(QuizDifficulty difficulty) {
    if (_selectedDifficulty == difficulty) {
      return;
    }
    setState(() {
      _selectedDifficulty = difficulty;
    });
  }

  void _selectMode(QuizMode mode) {
    if (_selectedMode == mode) {
      return;
    }
    setState(() {
      _selectedMode = mode;
    });
  }

  void _startRound() {
    HapticFeedback.mediumImpact();
    final provider = context.read<QuizProvider>();
    provider.startRound(mode: _selectedMode, difficulty: _selectedDifficulty);

    if (provider.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.loadError ?? 'Could not start round')),
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.quiz);
  }

  @override
  Widget build(BuildContext context) {
    final questionCount = _questionCountFor(_selectedDifficulty);
    final maxDuration = _durationLabel(
      questionCount * AppConstants.questionTimeLimitSeconds,
    );
    final adaptiveBottomPanelSpace = _adaptiveBottomPanelSpace(context);
    final listBottomPadding =
        adaptiveBottomPanelSpace + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _ModeBackground()),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          listBottomPadding,
                        ),
                        children: [
                          _buildDifficultySection(context),
                          const SizedBox(height: 18),
                          _buildModeSection(context),
                          const SizedBox(height: 8),
                          _buildRoundPreview(
                            context,
                            questionCount,
                            maxDuration,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomPanel(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HapticTapScale(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(999),
                pressedScale: 0.93,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.textPrimary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.outline.withValues(alpha: 0.48),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.panel.withValues(alpha: 0.64),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.outline.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  '${QuizMode.values.length} modes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentYellow,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Choose Mode',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            'Craft your round with mode and difficulty.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.panel.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.58)),
          ),
          child: Row(
            children: QuizDifficulty.values
                .map((difficulty) {
                  final selected = _selectedDifficulty == difficulty;
                  final color = _difficultyColor(difficulty);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _HapticTapScale(
                        onTap: () => _selectDifficulty(difficulty),
                        borderRadius: BorderRadius.circular(999),
                        pressedScale: 0.965,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: selected
                                ? LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.32),
                                      color.withValues(alpha: 0.16),
                                    ],
                                  )
                                : null,
                            color: selected
                                ? null
                                : AppTheme.panelSoft.withValues(alpha: 0.95),
                            border: Border.all(
                              color: selected
                                  ? color.withValues(alpha: 0.95)
                                  : AppTheme.outline.withValues(alpha: 0.72),
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.22),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _difficultyIcon(difficulty),
                                size: 16,
                                color: selected
                                    ? color
                                    : AppTheme.textPrimary.withValues(
                                        alpha: 0.78,
                                      ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                difficulty.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: selected
                                          ? color
                                          : AppTheme.textPrimary.withValues(
                                              alpha: 0.78,
                                            ),
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _difficultyHint(_selectedDifficulty),
            key: ValueKey(_selectedDifficulty),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 10),
        _buildScoringQuickAccess(context),
      ],
    );
  }

  Widget _buildScoringQuickAccess(BuildContext context) {
    return _HapticTapScale(
      onTap: _showScoringRules,
      borderRadius: BorderRadius.circular(14),
      pressedScale: 0.985,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.panel.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outline.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 16,
              color: AppTheme.accentYellow.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scoring Rules & Bonuses',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Rules',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.accentYellow,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.accentYellow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Mode',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...QuizMode.values.map((mode) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ModeTile(
              mode: mode,
              icon: _iconFor(mode),
              title: mode.label,
              subtitle: _subtitleFor(mode),
              selected: _selectedMode == mode,
              onTap: () => _selectMode(mode),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRoundPreview(
    BuildContext context,
    int questionCount,
    String maxDuration,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.homeSectionGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.homeCardBorder.withValues(alpha: 0.7),
        ),
        boxShadow: const [AppTheme.homeCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppTheme.accentYellow,
              ),
              const SizedBox(width: 8),
              Text(
                'Round Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_selectedMode.label} - ${_selectedDifficulty.label}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoundMetaChip(
                icon: Icons.quiz_outlined,
                label: '$questionCount questions',
                color: AppTheme.accentBlue,
              ),
              _RoundMetaChip(
                icon: Icons.timer_outlined,
                label: 'Up to $maxDuration',
                color: AppTheme.accentOrange,
              ),
              _RoundMetaChip(
                icon: Icons.favorite_rounded,
                label: '${AppConstants.maxLives} lives',
                color: AppTheme.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Includes speed rewards and streak bonuses.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.66)),
            boxShadow: const [AppTheme.cardShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: 19,
                    color: AppTheme.accentYellow,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready: ${_selectedMode.label} - ${_selectedDifficulty.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentYellow, AppTheme.accentOrange],
                  ),
                  boxShadow: const [AppTheme.glowOrange],
                ),
                child: ElevatedButton.icon(
                  onPressed: _startRound,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Round'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScoringRules() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              decoration: BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.72),
                ),
                boxShadow: const [AppTheme.cardShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Scoring Rules',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 20,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const _ScoreRuleItem(
                    icon: Icons.flash_on_rounded,
                    text: '0-3s = 20 points',
                  ),
                  const _ScoreRuleItem(
                    icon: Icons.bolt_rounded,
                    text: '3-6s = 15 points',
                  ),
                  const _ScoreRuleItem(
                    icon: Icons.timer_outlined,
                    text: '6-10s = 10 points',
                  ),
                  const _ScoreRuleItem(
                    icon: Icons.local_fire_department_rounded,
                    text: 'Streak 5+ = x1.5 multiplier',
                  ),
                  const _ScoreRuleItem(
                    icon: Icons.favorite_border_rounded,
                    text: 'Wrong answer = lose 1 life',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _questionCountFor(QuizDifficulty difficulty) {
    return switch (difficulty) {
      QuizDifficulty.easy => 8,
      QuizDifficulty.medium => 10,
      QuizDifficulty.hard => 12,
    };
  }

  String _durationLabel(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  double _adaptiveBottomPanelSpace(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.2).clamp(148.0, 208.0);
  }

  Color _difficultyColor(QuizDifficulty difficulty) {
    return switch (difficulty) {
      QuizDifficulty.easy => AppTheme.success,
      QuizDifficulty.medium => AppTheme.accentYellow,
      QuizDifficulty.hard => AppTheme.danger,
    };
  }

  IconData _difficultyIcon(QuizDifficulty difficulty) {
    return switch (difficulty) {
      QuizDifficulty.easy => Icons.eco_rounded,
      QuizDifficulty.medium => Icons.flash_on_rounded,
      QuizDifficulty.hard => Icons.local_fire_department_rounded,
    };
  }

  String _difficultyHint(QuizDifficulty difficulty) {
    return switch (difficulty) {
      QuizDifficulty.easy =>
        'Relaxed pace with safer choices to build streaks.',
      QuizDifficulty.medium =>
        'Balanced challenge tuned for steady progression.',
      QuizDifficulty.hard =>
        'Fast and intense rounds with high risk and reward.',
    };
  }

  IconData _iconFor(QuizMode mode) {
    return switch (mode) {
      QuizMode.flag => Icons.flag_rounded,
      QuizMode.capital => Icons.location_city_rounded,
      QuizMode.population => Icons.groups_rounded,
      QuizMode.region => Icons.map_rounded,
      QuizMode.randomMix => Icons.casino_rounded,
    };
  }

  String _subtitleFor(QuizMode mode) {
    return switch (mode) {
      QuizMode.flag => 'Identify country from flag',
      QuizMode.capital => 'Match country to capital',
      QuizMode.population => 'Order by population size',
      QuizMode.region => 'Which continent?',
      QuizMode.randomMix => 'Mix every mode in one run',
    };
  }
}

class _ModeBackground extends StatelessWidget {
  const _ModeBackground();

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
            top: -160,
            right: -110,
            child: _Aura(size: 340, color: Color(0x4D3778FF)),
          ),
          Positioned(
            top: 170,
            left: -100,
            child: _Aura(size: 260, color: Color(0x3642C8A5)),
          ),
          Positioned(
            bottom: -190,
            right: -80,
            child: _Aura(size: 320, color: Color(0x3D8450D8)),
          ),
          Positioned.fill(child: CustomPaint(painter: _ModeTexturePainter())),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0x26010816)),
            ),
          ),
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

class _Aura extends StatelessWidget {
  const _Aura({required this.size, required this.color});

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

class _ModeTexturePainter extends CustomPainter {
  const _ModeTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = AppTheme.homeTextureLine.withValues(alpha: 0.09);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = AppTheme.homeTextureAccent.withValues(alpha: 0.06);

    const arcCount = 6;
    for (var i = 0; i < arcCount; i++) {
      final t = i / (arcCount - 1);
      final y = size.height * (0.14 + (0.7 * t));
      final bend = math.sin((t - 0.5) * math.pi) * 24;
      final path = Path()
        ..moveTo(-size.width * 0.08, y)
        ..quadraticBezierTo(size.width * 0.5, y + bend, size.width * 1.08, y);
      canvas.drawPath(path, arcPaint);
    }

    const lineCount = 5;
    for (var i = 0; i < lineCount; i++) {
      final t = i / (lineCount - 1);
      final x = size.width * (0.1 + (0.8 * t));
      final bend = (t - 0.5) * 40;
      final path = Path()
        ..moveTo(x, -size.height * 0.08)
        ..quadraticBezierTo(x + bend, size.height * 0.5, x, size.height * 1.08);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ModeTexturePainter oldDelegate) => false;
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final QuizMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (mode) {
      QuizMode.flag => const Color(0xFF4E7BFF),
      QuizMode.capital => const Color(0xFF2CD674),
      QuizMode.population => const Color(0xFFFFA14F),
      QuizMode.region => const Color(0xFF3AA9FF),
      QuizMode.randomMix => const Color(0xFF7E6AFF),
    };
    final radius = BorderRadius.circular(AppTheme.radiusMd);

    return Semantics(
      button: true,
      selected: selected,
      child: _HapticTapScale(
        onTap: onTap,
        borderRadius: radius,
        pressedScale: selected ? 0.992 : 0.982,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: selected
                ? AppTheme.modeColor(mode)
                : LinearGradient(
                    colors: [
                      AppTheme.panelSoft.withValues(alpha: 0.88),
                      AppTheme.panel.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.95)
                  : AppTheme.outline.withValues(alpha: 0.58),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.13)
                        : AppTheme.panel.withValues(alpha: 0.7),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppTheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? Colors.white : AppTheme.accentYellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              height: 1,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary.withValues(
                            alpha: selected ? 0.9 : 0.82,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundMetaChip extends StatelessWidget {
  const _RoundMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.52)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRuleItem extends StatelessWidget {
  const _ScoreRuleItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accentYellow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HapticTapScale extends StatefulWidget {
  const _HapticTapScale({
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
  State<_HapticTapScale> createState() => _HapticTapScaleState();
}

class _HapticTapScaleState extends State<_HapticTapScale> {
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
