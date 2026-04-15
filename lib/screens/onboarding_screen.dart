import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_routes.dart';
import '../core/storage/local_prefs.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isFinishing = false;

  static const List<_OnboardingItem> _slides = [
    _OnboardingItem(
      title: 'Master Flags & Capitals',
      description:
          'Challenge yourself with fast-paced questions generated from live country data.',
      illustrationAsset: 'assets/onboarding/flag_globe.svg',
      colors: [Color(0xFF103548), Color(0xFF1D596C), Color(0xFF2A7385)],
    ),
    _OnboardingItem(
      title: 'Compete Globally',
      description:
          'Push your score to the top and aim for leaderboard glory with your streak multiplier.',
      illustrationAsset: 'assets/onboarding/leader_trophy.svg',
      colors: [Color(0xFF22184A), Color(0xFF37286B), Color(0xFF47358F)],
    ),
    _OnboardingItem(
      title: 'Unlock Badges',
      description:
          'Earn achievement badges for perfect runs, long streaks, and consistent daily play.',
      illustrationAsset: 'assets/onboarding/badge_emblem.svg',
      colors: [Color(0xFF153A39), Color(0xFF1D6454), Color(0xFF258163)],
    ),
  ];

  Future<void> _finishOnboarding() async {
    if (_isFinishing) {
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final quizProvider = context.read<QuizProvider>();
      final navigator = Navigator.of(context);

      await LocalPrefs().setOnboardingSeen(true);
      if (!mounted) {
        return;
      }

      var destination = AppRoutes.login;

      if (authProvider.isSignedIn) {
        await quizProvider.hydrateProgressFromCloud();
        if (!mounted) {
          return;
        }
        destination = AppRoutes.home;
      }

      navigator.pushReplacementNamed(destination);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFinishing = false;
      });
    }
  }

  void _onBackPressed() {
    if (_currentIndex == 0 || _isFinishing) {
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _onNextPressed() {
    if (_isFinishing) {
      return;
    }

    if (_currentIndex == _slides.length - 1) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  int _boundIndex(int index) {
    if (index < 0) {
      return 0;
    }
    if (index >= _slides.length) {
      return _slides.length - 1;
    }
    return index;
  }

  List<Color> _resolvedPanelColors() {
    final fallback = _slides[_currentIndex].colors;
    if (!_pageController.hasClients) {
      return fallback;
    }

    final page = _pageController.page;
    if (page == null) {
      return fallback;
    }

    final lowerIndex = _boundIndex(page.floor());
    final upperIndex = _boundIndex(page.ceil());
    final t = (page - lowerIndex).clamp(0.0, 1.0);

    final from = _slides[lowerIndex].colors;
    final to = _slides[upperIndex].colors;
    return List<Color>.generate(
      from.length,
      (i) => Color.lerp(from[i], to[i], t)!,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _currentIndex == _slides.length - 1;
    const backButtonSlotWidth = 108.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.deepSpaceGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isFinishing ? null : _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentYellow,
                      backgroundColor: AppTheme.textPrimary.withValues(
                        alpha: 0.08,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) {
                      final panelColors = _resolvedPanelColors();

                      return DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.34),
                              blurRadius: 26,
                              offset: const Offset(0, 18),
                            ),
                            BoxShadow(
                              color: panelColors.last.withValues(alpha: 0.26),
                              blurRadius: 30,
                              spreadRadius: 1,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.outline.withValues(alpha: 0.7),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: panelColors,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomCenter,
                                            stops: const [0, 0.45, 1],
                                            colors: [
                                              AppTheme.textPrimary.withValues(
                                                alpha: 0.18,
                                              ),
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.11,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -34,
                                    right: -26,
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              AppTheme.textPrimary.withValues(
                                                alpha: 0.13,
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: const SizedBox(
                                          width: 126,
                                          height: 126,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      24,
                                      22,
                                      20,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 62,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: AppTheme.textPrimary
                                                .withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: PageView.builder(
                                            controller: _pageController,
                                            itemCount: _slides.length,
                                            onPageChanged: (index) {
                                              setState(() {
                                                _currentIndex = index;
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              return _AnimatedSlideContent(
                                                slide: _slides[index],
                                                isActive: _currentIndex == index,
                                              );
                                            },
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            SmoothPageIndicator(
                                              controller: _pageController,
                                              count: _slides.length,
                                              effect: ExpandingDotsEffect(
                                                activeDotColor:
                                                    AppTheme.accentYellow,
                                                dotColor: AppTheme.textPrimary
                                                    .withValues(alpha: 0.46),
                                                dotHeight: 10,
                                                dotWidth: 10,
                                                spacing: 8,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${_currentIndex + 1}/${_slides.length}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppTheme.textPrimary
                                                        .withValues(
                                                          alpha: 0.9,
                                                        ),
                                                    letterSpacing: 0.2,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: AppTheme.textPrimary
                                                .withValues(alpha: 0.09),
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.textPrimary
                                                  .withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: backButtonSlotWidth,
                                                  child: AnimatedOpacity(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    opacity:
                                                        _currentIndex == 0
                                                            ? 0
                                                            : 1,
                                                    child: IgnorePointer(
                                                      ignoring:
                                                          _currentIndex == 0 ||
                                                          _isFinishing,
                                                      child: OutlinedButton(
                                                        onPressed: _onBackPressed,
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              AppTheme
                                                                  .textPrimary,
                                                          backgroundColor: AppTheme
                                                              .textPrimary
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          side: BorderSide(
                                                            color: AppTheme
                                                                .textPrimary
                                                                .withValues(
                                                                  alpha: 0.38,
                                                                ),
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 14,
                                                                vertical: 14,
                                                              ),
                                                          minimumSize:
                                                              const Size(
                                                                0,
                                                                52,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'Back',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              AppTheme
                                                                  .accentYellow,
                                                              AppTheme
                                                                  .accentOrange,
                                                            ],
                                                          ),
                                                      boxShadow: const [
                                                        AppTheme.glowYellow,
                                                      ],
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed:
                                                          _isFinishing
                                                              ? null
                                                              : _onNextPressed,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        shadowColor:
                                                            Colors.transparent,
                                                        disabledBackgroundColor:
                                                            Colors.transparent,
                                                        disabledForegroundColor:
                                                            AppTheme.onGold
                                                                .withValues(
                                                                  alpha: 0.85,
                                                                ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 16,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                        ),
                                                      ),
                                                      child: AnimatedSwitcher(
                                                        duration: const Duration(
                                                          milliseconds: 220,
                                                        ),
                                                        transitionBuilder: (
                                                          child,
                                                          animation,
                                                        ) {
                                                          return FadeTransition(
                                                            opacity: animation,
                                                            child: SlideTransition(
                                                              position: Tween<
                                                                Offset
                                                              >(
                                                                begin:
                                                                    const Offset(
                                                                      0.08,
                                                                      0,
                                                                    ),
                                                                end:
                                                                    Offset.zero,
                                                              ).animate(
                                                                animation,
                                                              ),
                                                              child: child,
                                                            ),
                                                          );
                                                        },
                                                        child:
                                                            _isFinishing
                                                                ? SizedBox(
                                                                  key:
                                                                      const ValueKey(
                                                                        'loading',
                                                                      ),
                                                                  width: 20,
                                                                  height: 20,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2.2,
                                                                    valueColor: AlwaysStoppedAnimation<
                                                                      Color
                                                                    >(
                                                                      AppTheme
                                                                          .onGold,
                                                                    ),
                                                                  ),
                                                                )
                                                                : Row(
                                                                  key: ValueKey<
                                                                    String
                                                                  >(
                                                                    isLastSlide
                                                                        ? 'start'
                                                                        : 'next',
                                                                  ),
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      isLastSlide
                                                                          ? 'Start Challenge'
                                                                          : 'Next',
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Icon(
                                                                      isLastSlide
                                                                          ? Icons
                                                                              .rocket_launch_rounded
                                                                          : Icons
                                                                              .arrow_forward_rounded,
                                                                      size: 18,
                                                                    ),
                                                                  ],
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.illustrationAsset,
    required this.colors,
  });

  final String title;
  final String description;
  final String illustrationAsset;
  final List<Color> colors;
}

class _AnimatedSlideContent extends StatelessWidget {
  const _AnimatedSlideContent({required this.slide, required this.isActive});

  final _OnboardingItem slide;
  final bool isActive;

  double _segment(double t, double start, double end) {
    final normalized = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return normalized.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: AppTheme.textPrimary,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppTheme.textPrimary.withValues(alpha: 0.91),
      height: 1.38,
      fontWeight: FontWeight.w700,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isActive ? 1 : 0),
      duration: const Duration(milliseconds: 640),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final iconT = Curves.easeOutBack.transform(_segment(value, 0.0, 0.58));
        final iconOpacity = iconT.clamp(0.0, 1.0).toDouble();
        final titleT = Curves.easeOutCubic.transform(_segment(value, 0.2, 0.82));
        final titleOpacity = titleT.clamp(0.0, 1.0).toDouble();
        final bodyT = Curves.easeOutCubic.transform(_segment(value, 0.34, 1.0));
        final bodyOpacity = bodyT.clamp(0.0, 1.0).toDouble();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: iconOpacity,
              child: Transform.translate(
                offset: Offset(0, (1 - iconT) * 24),
                child: Transform.scale(
                  scale: 0.86 + (0.14 * iconT),
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: AppTheme.textPrimary.withValues(alpha: 0.18),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.textPrimary.withValues(alpha: 0.2),
                          AppTheme.textPrimary.withValues(alpha: 0.08),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: SvgPicture.asset(
                        slide.illustrationAsset,
                        fit: BoxFit.contain,
                        semanticsLabel: '${slide.title} illustration',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Opacity(
              opacity: titleOpacity,
              child: Transform.translate(
                offset: Offset(0, (1 - titleT) * 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: bodyOpacity,
              child: Transform.translate(
                offset: Offset(0, (1 - bodyT) * 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    slide.description,
                    textAlign: TextAlign.center,
                    style: bodyStyle,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
