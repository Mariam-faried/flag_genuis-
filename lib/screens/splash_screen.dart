import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/storage/local_prefs.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Future<void>? _bootstrapFuture;

  late final AnimationController _logoController;
  late final AnimationController _titleFadeController;
  late final AnimationController _taglineFadeController;
  late final AnimationController _particleController;
  late final AnimationController _pinController;

  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _pinDropProgress;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _taglineFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _titleOpacity = CurvedAnimation(
      parent: _titleFadeController,
      curve: Curves.easeOut,
    );
    _taglineOpacity = CurvedAnimation(
      parent: _taglineFadeController,
      curve: Curves.easeOut,
    );
    _pinDropProgress = CurvedAnimation(
      parent: _pinController,
      curve: Curves.bounceOut,
    );

    _logoController.forward().whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _pinController.forward();
        }
      });
    });
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _titleFadeController.forward();
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _taglineFadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleFadeController.dispose();
    _taglineFadeController.dispose();
    _particleController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final quizProvider = context.read<QuizProvider>();
    final authProvider = context.read<AuthProvider>();

    await Future.wait<void>([
      quizProvider.initializeCountries(),
      authProvider.waitUntilInitialized(),
    ]);

    if (quizProvider.loadError != null) {
      throw Exception(quizProvider.loadError);
    }

    final onboardingSeen = await LocalPrefs().isOnboardingSeen();
    final destination = onboardingSeen
        ? (authProvider.isSignedIn ? AppRoutes.home : AppRoutes.login)
        : AppRoutes.onboarding;

    if (destination == AppRoutes.home) {
      await quizProvider.hydrateProgressFromCloud();
    }

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, destination);
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spotlightColor = AppTheme.homeHeroGradient.colors.first;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.35,
            colors: [AppTheme.night, spotlightColor, AppTheme.night],
            stops: const [0, 0.58, 1],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<void>(
            future: _bootstrapFuture,
            builder: (context, snapshot) {
              return Stack(
                children: [
                  const _BottomRadialGlow(),
                  _SplashParticles(animation: _particleController),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 168),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _logoScale,
                            child: _SplashLogo(
                              pinDropProgress: _pinDropProgress,
                            ),
                          ),
                          const SizedBox(height: 30),
                          FadeTransition(
                            opacity: _titleOpacity,
                            child: Text(
                              'Flag Genius',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.baloo2(
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _taglineOpacity,
                            child: Text(
                              'Learn the world, one flag at a time',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 80,
                    child: snapshot.hasError
                        ? _SplashError(
                            errorText: snapshot.error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
                            onRetry: _retryBootstrap,
                          )
                        : const _SplashLoadingBar(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomRadialGlow extends StatelessWidget {
  const _BottomRadialGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: const Offset(0, 120),
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.5,
                colors: [
                  AppTheme.panelSoft.withValues(alpha: 0.6),
                  AppTheme.panelSoft.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashParticles extends StatelessWidget {
  const _SplashParticles({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = animation.value;
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;

              Widget particle({
                required double horizontalFactor,
                required double baseHeightFactor,
                required double riseDistance,
                required double size,
                required double phaseShift,
              }) {
                final progress = (t + phaseShift) % 1;
                final top =
                    (screenHeight * baseHeightFactor) -
                    (progress * riseDistance);

                return Positioned(
                  left: (screenWidth * horizontalFactor) - (size / 2),
                  top: top,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  particle(
                    horizontalFactor: 0.2,
                    baseHeightFactor: 0.86,
                    riseDistance: screenHeight * 0.24,
                    size: 4,
                    phaseShift: 0,
                  ),
                  particle(
                    horizontalFactor: 0.78,
                    baseHeightFactor: 0.84,
                    riseDistance: screenHeight * 0.2,
                    size: 5,
                    phaseShift: 0.33,
                  ),
                  particle(
                    horizontalFactor: 0.56,
                    baseHeightFactor: 0.9,
                    riseDistance: screenHeight * 0.26,
                    size: 6,
                    phaseShift: 0.66,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.pinDropProgress});

  final Animation<double> pinDropProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      height: 176,
      decoration: BoxDecoration(
        color: AppTheme.nightAccent.withValues(alpha: 0.28),
        shape: BoxShape.circle,
        boxShadow: const [AppTheme.glowBlue],
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: pinDropProgress,
        builder: (context, _) {
          return CustomPaint(
            size: const Size.square(134),
            painter: _GlobePainter(pinProgress: pinDropProgress.value),
          );
        },
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  const _GlobePainter({required this.pinProgress});

  final double pinProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final globeRadius = size.width * 0.34;
    final globeRect = Rect.fromCircle(center: center, radius: globeRadius);
    final globeMask = Path()..addOval(globeRect);

    final globePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentBlue.withValues(alpha: 0.9),
          AppTheme.nightAccent,
        ],
      ).createShader(globeRect);
    canvas.drawCircle(center, globeRadius, globePaint);

    canvas.save();
    canvas.clipPath(globeMask);

    final continentPaint = Paint()..color = const Color(0xFF1A4A89);
    final continentOne = Path()
      ..moveTo(center.dx - globeRadius * 0.7, center.dy - globeRadius * 0.25)
      ..cubicTo(
        center.dx - globeRadius * 0.9,
        center.dy - globeRadius * 0.55,
        center.dx - globeRadius * 0.45,
        center.dy - globeRadius * 0.78,
        center.dx - globeRadius * 0.2,
        center.dy - globeRadius * 0.55,
      )
      ..cubicTo(
        center.dx,
        center.dy - globeRadius * 0.42,
        center.dx - globeRadius * 0.05,
        center.dy - globeRadius * 0.15,
        center.dx - globeRadius * 0.38,
        center.dy - globeRadius * 0.05,
      )
      ..cubicTo(
        center.dx - globeRadius * 0.58,
        center.dy + globeRadius * 0.02,
        center.dx - globeRadius * 0.74,
        center.dy - globeRadius * 0.04,
        center.dx - globeRadius * 0.7,
        center.dy - globeRadius * 0.25,
      )
      ..close();

    final continentTwo = Path()
      ..moveTo(center.dx + globeRadius * 0.1, center.dy - globeRadius * 0.08)
      ..cubicTo(
        center.dx + globeRadius * 0.4,
        center.dy - globeRadius * 0.28,
        center.dx + globeRadius * 0.82,
        center.dy - globeRadius * 0.08,
        center.dx + globeRadius * 0.62,
        center.dy + globeRadius * 0.2,
      )
      ..cubicTo(
        center.dx + globeRadius * 0.48,
        center.dy + globeRadius * 0.4,
        center.dx + globeRadius * 0.2,
        center.dy + globeRadius * 0.33,
        center.dx + globeRadius * 0.05,
        center.dy + globeRadius * 0.15,
      )
      ..cubicTo(
        center.dx - globeRadius * 0.03,
        center.dy + globeRadius * 0.05,
        center.dx,
        center.dy - globeRadius * 0.02,
        center.dx + globeRadius * 0.1,
        center.dy - globeRadius * 0.08,
      )
      ..close();

    final continentThree = Path()
      ..moveTo(center.dx - globeRadius * 0.24, center.dy + globeRadius * 0.22)
      ..cubicTo(
        center.dx - globeRadius * 0.42,
        center.dy + globeRadius * 0.16,
        center.dx - globeRadius * 0.56,
        center.dy + globeRadius * 0.33,
        center.dx - globeRadius * 0.38,
        center.dy + globeRadius * 0.5,
      )
      ..cubicTo(
        center.dx - globeRadius * 0.2,
        center.dy + globeRadius * 0.64,
        center.dx + globeRadius * 0.02,
        center.dy + globeRadius * 0.52,
        center.dx - globeRadius * 0.02,
        center.dy + globeRadius * 0.34,
      )
      ..cubicTo(
        center.dx - globeRadius * 0.06,
        center.dy + globeRadius * 0.26,
        center.dx - globeRadius * 0.14,
        center.dy + globeRadius * 0.23,
        center.dx - globeRadius * 0.24,
        center.dy + globeRadius * 0.22,
      )
      ..close();

    canvas.drawPath(continentOne, continentPaint);
    canvas.drawPath(continentTwo, continentPaint);
    canvas.drawPath(continentThree, continentPaint);

    canvas.restore();

    final latitudePaint = Paint()
      ..color = AppTheme.textPrimary.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (final latitude in [
      (offset: -0.35, amplitude: 0.12),
      (offset: 0.0, amplitude: 0.09),
      (offset: 0.35, amplitude: 0.13),
    ]) {
      final y = center.dy + (globeRadius * latitude.offset);
      final leftX = center.dx - globeRadius * 0.88;
      final rightX = center.dx + globeRadius * 0.88;
      final wave = globeRadius * latitude.amplitude;

      final path = Path()
        ..moveTo(leftX, y)
        ..cubicTo(
          center.dx - globeRadius * 0.55,
          y - wave,
          center.dx - globeRadius * 0.2,
          y + wave * 0.7,
          center.dx,
          y,
        )
        ..cubicTo(
          center.dx + globeRadius * 0.2,
          y - wave * 0.7,
          center.dx + globeRadius * 0.55,
          y + wave,
          rightX,
          y,
        );

      canvas.drawPath(path, latitudePaint);
    }

    for (final xFactor in [-0.34, 0.34]) {
      final path = Path()
        ..moveTo(center.dx + (globeRadius * xFactor), center.dy - globeRadius)
        ..quadraticBezierTo(
          center.dx + (globeRadius * (xFactor * 1.55)),
          center.dy,
          center.dx + (globeRadius * xFactor),
          center.dy + globeRadius,
        );
      canvas.drawPath(path, latitudePaint);
    }

    canvas.save();
    canvas.clipPath(globeMask);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(center.dx - globeRadius * 0.42, center.dy - globeRadius * 0.46),
      20,
      highlightPaint,
    );
    canvas.restore();

    final ringPaint = Paint()
      ..color = AppTheme.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, globeRadius + 1.5, ringPaint);

    final targetPinCenter = Offset(
      center.dx + (globeRadius * 0.85),
      center.dy - (globeRadius * 0.8),
    );
    final pinCenter = Offset(
      targetPinCenter.dx,
      targetPinCenter.dy - ((1 - pinProgress) * globeRadius * 0.95),
    );
    final pinRadius = globeRadius * 0.28;
    final pinBounds = Rect.fromCenter(
      center: pinCenter,
      width: pinRadius * 2.1,
      height: pinRadius * 2.9,
    );
    final pinGradient = AppTheme.goldGradient.createShader(pinBounds);
    final pinPaint = Paint()..shader = pinGradient;

    canvas.drawCircle(pinCenter, pinRadius, pinPaint);

    final pinTail = Path()
      ..moveTo(
        pinCenter.dx - (pinRadius * 0.62),
        pinCenter.dy + pinRadius * 0.6,
      )
      ..lineTo(
        pinCenter.dx + (pinRadius * 0.62),
        pinCenter.dy + pinRadius * 0.6,
      )
      ..lineTo(pinCenter.dx, pinCenter.dy + pinRadius * 1.7)
      ..close();
    canvas.drawPath(pinTail, pinPaint);

    final flagRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pinCenter.dx, pinCenter.dy + pinRadius * 0.03),
        width: pinRadius * 1.18,
        height: pinRadius * 0.46,
      ),
      Radius.circular(pinRadius * 0.1),
    );

    final flagPaint = Paint()
      ..shader = AppTheme.goldGradient.createShader(flagRect.outerRect);
    canvas.drawRRect(flagRect, flagPaint);

    final flagBorderPaint = Paint()
      ..color = AppTheme.nightAccent.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(flagRect, flagBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) {
    return oldDelegate.pinProgress != pinProgress;
  }
}

class _SplashLoadingBar extends StatelessWidget {
  const _SplashLoadingBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 4,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: AppTheme.panelSoft),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return AppTheme.goldGradient.createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: AppTheme.panelSoft.withValues(alpha: 0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Loading countries...',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.errorText, required this.onRetry});

  final String errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.panel.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    errorText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: onRetry,
                    child: Text(
                      'Retry loading',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
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
