import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _hidePassword = true;
  bool _isRegisterMode = false;
  bool _submitted = false;
  bool _navigatedAfterAuth = false;
  late final AnimationController _entryController;
  late final AnimationController _orbitController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _cardFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.08, 1, curve: Curves.easeOutCubic),
      ),
    );
    _entryController.forward();
  }

  void _clearAuthErrorIfAny() {
    final authProvider = context.read<AuthProvider>();
    if ((authProvider.errorMessage ?? '').isNotEmpty) {
      authProvider.clearError();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _orbitController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final normalized = (value ?? '').trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (normalized.isEmpty) {
      return 'Enter your email address.';
    }
    if (!emailRegex.hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Enter your password.';
    }
    if (_isRegisterMode && password.length < 6) {
      return 'Use at least 6 characters.';
    }
    return null;
  }

  String _friendlyAuthMessage(String message) {
    final lowered = message.toLowerCase();
    if (lowered.contains('plugin bridge is out of sync') ||
        lowered.contains('pigeon')) {
      return 'Sign-in is temporarily unavailable. Please close and reopen the app, then try again.';
    }
    if (lowered.contains('cloud sync is blocked')) {
      return 'You are signed in, but cloud sync is unavailable right now. You can keep playing and sync later.';
    }
    if (lowered.contains('apiexception: 10')) {
      return 'Google sign-in is unavailable on this device right now. Try email sign-in or guest mode.';
    }
    if (lowered.contains('network')) {
      return 'Connection looks unstable. Please check your internet and try again.';
    }
    return message;
  }

  bool _canContinueOfflineGuest(String message) {
    final lowered = message.toLowerCase();
    return lowered.contains('plugin bridge is out of sync') ||
        lowered.contains('plugin mismatch') ||
        lowered.contains('pigeonuserdetails') ||
        lowered.contains('pigeonuserinfo') ||
        lowered.contains('list<object?>');
  }

  Future<void> _handleEmailAction() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isBusy) {
      return;
    }

    _clearAuthErrorIfAny();

    if (!_submitted) {
      setState(() {
        _submitted = true;
      });
    }
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = _isRegisterMode
        ? await authProvider.registerWithEmail(email: email, password: password)
        : await authProvider.signInWithEmail(email: email, password: password);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        _friendlyAuthMessage(
          authProvider.errorMessage ?? 'Authentication failed.',
        ),
      );
      return;
    }

    await _completeAuthFlow();
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isBusy) {
      return;
    }

    _clearAuthErrorIfAny();

    final success = await authProvider.signInWithGoogle();

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        _friendlyAuthMessage(
          authProvider.errorMessage ?? 'Google sign-in failed.',
        ),
      );
      return;
    }

    await _completeAuthFlow();
  }

  Future<void> _handleGuestSignIn() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isBusy) {
      return;
    }

    _clearAuthErrorIfAny();

    final success = await authProvider.continueAsGuest();

    if (!mounted) {
      return;
    }

    if (!success) {
      final rawError = authProvider.errorMessage ?? '';
      if (_canContinueOfflineGuest(rawError)) {
        _showMessage(
          'Cloud guest sign-in is temporarily unavailable. Continuing in offline guest mode.',
        );
        await _completeAuthFlow();
        return;
      }
      _showMessage(
        _friendlyAuthMessage(rawError.isEmpty ? 'Guest sign-in failed.' : rawError),
      );
      return;
    }

    await _completeAuthFlow();
  }

  Future<void> _handleForgotPassword() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isBusy) {
      return;
    }

    final email = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ForgotPasswordSheet(initialEmail: _emailController.text.trim());
      },
    );

    if (!mounted || email == null) {
      return;
    }

    _clearAuthErrorIfAny();
    final success = await authProvider.sendPasswordResetEmail(email: email);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        _friendlyAuthMessage(
          authProvider.errorMessage ?? 'Could not send reset link.',
        ),
      );
      return;
    }

    _showMessage('Password reset link sent to $email');
  }

  Future<void> _completeAuthFlow() async {
    if (_navigatedAfterAuth) {
      return;
    }

    _navigatedAfterAuth = true;
    try {
      await context.read<QuizProvider>().hydrateProgressFromCloud();
    } catch (_) {
      _navigatedAfterAuth = false;
      if (mounted) {
        _showMessage(
          'Signed in, but syncing progress failed. Please try again.',
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isBusy = authProvider.isBusy;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: SafeArea(
          child: Stack(
            children: [
              const _LoginTopRadialGlow(),
              const _LoginBottomRadialGlow(),
              const _BackgroundParticles(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.panel.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: AppTheme.outline,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.night.withValues(alpha: 0.48),
                                blurRadius: 36,
                                offset: const Offset(0, 24),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                autovalidateMode: _submitted
                                    ? AutovalidateMode.onUserInteraction
                                    : AutovalidateMode.disabled,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 62,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppTheme.outline.withValues(
                                            alpha: 0.8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _LoginBrandHeader(orbitTurns: _orbitController),
                                    const SizedBox(height: 20),
                                    Text(
                                      _isRegisterMode
                                          ? 'Create Your Account'
                                          : 'Welcome Back',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.baloo2(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isRegisterMode
                                          ? 'Start your world journey and climb the leaderboard.'
                                          : 'Sign in to continue your global challenge.',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.email],
                                      autocorrect: false,
                                      enabled: !isBusy,
                                      validator: _validateEmail,
                                      onChanged: (_) => _clearAuthErrorIfAny(),
                                      onFieldSubmitted: (_) {
                                        _passwordFocusNode.requestFocus();
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Email address',
                                        prefixIcon: Icon(Icons.mail_outline),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      obscureText: _hidePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: _isRegisterMode
                                          ? const [AutofillHints.newPassword]
                                          : const [AutofillHints.password],
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      enabled: !isBusy,
                                      validator: _validatePassword,
                                      onChanged: (_) => _clearAuthErrorIfAny(),
                                      onFieldSubmitted: (_) {
                                        if (!isBusy) {
                                          unawaited(_handleEmailAction());
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: isBusy
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _hidePassword =
                                                        !_hidePassword;
                                                  });
                                                },
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (!_isRegisterMode) ...[
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: isBusy
                                              ? null
                                              : _handleForgotPassword,
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Forgot password?',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ] else
                                      const SizedBox(height: 10),
                                    _GradientActionButton(
                                      enabled: !isBusy,
                                      onTap: _handleEmailAction,
                                      child: isBusy
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: AppTheme.onGold,
                                              ),
                                            )
                                          : Text(
                                              _isRegisterMode
                                                  ? 'Create Account'
                                                  : 'Sign In',
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: AppTheme.outline,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            'or',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: AppTheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _GoogleSignInButton(
                                      enabled: !isBusy,
                                      onTap: _handleGoogleSignIn,
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: isBusy
                                          ? null
                                          : _handleGuestSignIn,
                                      child: const Text('Continue as Guest'),
                                    ),
                                    TextButton(
                                      onPressed: isBusy
                                          ? null
                                          : () {
                                              _clearAuthErrorIfAny();
                                              setState(() {
                                                _isRegisterMode =
                                                    !_isRegisterMode;
                                                _submitted = false;
                                              });
                                            },
                                      child: Text(
                                        _isRegisterMode
                                            ? 'Already have an account? Sign in'
                                            : 'Don\'t have an account? Register',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '195 countries to explore',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const _MiniFlagStripRow(),
                                    if ((authProvider.errorMessage ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.danger.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.danger.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          _friendlyAuthMessage(
                                            authProvider.errorMessage!,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.textPrimary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginTopRadialGlow extends StatelessWidget {
  const _LoginTopRadialGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.82,
              colors: [
                const Color(0xFF17366C).withValues(alpha: 0.35),
                const Color(0x0017366C),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBottomRadialGlow extends StatelessWidget {
  const _LoginBottomRadialGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: const Offset(0, 165),
          child: Container(
            width: 470,
            height: 470,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.58,
                colors: [Color(0xFF1A2347), Color(0x001A2347)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader({required this.orbitTurns});

  final Animation<double> orbitTurns;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LoginBrandLogo(orbitTurns: orbitTurns),
        const SizedBox(height: 10),
        Text(
          'Flag Genius',
          textAlign: TextAlign.center,
          style: GoogleFonts.baloo2(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Learn the world, one flag at a time',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: AppTheme.goldGradient,
          ),
        ),
      ],
    );
  }
}

class _LoginBrandLogo extends StatelessWidget {
  const _LoginBrandLogo({required this.orbitTurns});

  final Animation<double> orbitTurns;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppTheme.nightAccent.withValues(alpha: 0.34),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentBlue.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const CustomPaint(
              size: Size.square(52),
              painter: _LoginGlobePainter(),
            ),
          ),
          RotationTransition(
            turns: orbitTurns,
            child: SizedBox(
              width: 92,
              height: 92,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentYellow.withValues(alpha: 0.42),
                        blurRadius: 8,
                        spreadRadius: 0.6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginGlobePainter extends CustomPainter {
  const _LoginGlobePainter();

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
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(center.dx - globeRadius * 0.42, center.dy - globeRadius * 0.46),
      globeRadius * 0.42,
      highlightPaint,
    );
    canvas.restore();

    final ringPaint = Paint()
      ..color = AppTheme.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, globeRadius + 1.5, ringPaint);

    final pinCenter = Offset(
      center.dx + (globeRadius * 0.85),
      center.dy - (globeRadius * 0.8),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _MiniFlagStripRow extends StatelessWidget {
  const _MiniFlagStripRow();

  @override
  Widget build(BuildContext context) {
    final flags = <Widget>[
      _stripeFlag(
        colors: const [Color(0xFF002395), Color(0xFFFFFFFF), Color(0xFFED2939)],
        axis: Axis.vertical,
      ),
      _stripeFlag(
        colors: const [Color(0xFF000000), Color(0xFFDD0000), Color(0xFFFFCE00)],
        axis: Axis.horizontal,
      ),
      _stripeFlag(
        colors: const [Color(0xFF009A44), Color(0xFFFFFFFF), Color(0xFFCE1126)],
        axis: Axis.vertical,
      ),
      _japanFlag(),
      _brazilFlag(),
      _stripeFlag(
        colors: const [Color(0xFFCE1126), Color(0xFFFFFFFF), Color(0xFF000000)],
        axis: Axis.horizontal,
      ),
      _swedenFlag(),
      _turkeyFlag(),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < flags.length; i++) ...[
          Opacity(opacity: 0.5, child: flags[i]),
          if (i != flags.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _stripeFlag({required List<Color> colors, required Axis axis}) {
    return _flagFrame(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: axis == Axis.vertical
              ? Alignment.centerLeft
              : Alignment.topCenter,
          end: axis == Axis.vertical
              ? Alignment.centerRight
              : Alignment.bottomCenter,
          colors: [
            colors[0],
            colors[0],
            colors[1],
            colors[1],
            colors[2],
            colors[2],
          ],
          stops: const [0, 1 / 3, 1 / 3, 2 / 3, 2 / 3, 1],
        ),
      ),
    );
  }

  Widget _japanFlag() {
    return _flagFrame(
      child: Container(
        color: const Color(0xFFFFFFFF),
        child: const Center(
          child: SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFBC002D),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brazilFlag() {
    return _flagFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(color: const Color(0xFF009B3A)),
          Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 11,
              height: 11,
              color: const Color(0xFFFFDF00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swedenFlag() {
    return _flagFrame(
      child: Stack(
        children: [
          Container(color: const Color(0xFF006AA7)),
          Align(
            alignment: const Alignment(-0.25, 0),
            child: Container(width: 4, color: const Color(0xFFFECC00)),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(height: 4, color: const Color(0xFFFECC00)),
          ),
        ],
      ),
    );
  }

  Widget _turkeyFlag() {
    return _flagFrame(
      child: Container(
        color: const Color(0xFFE30A17),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFE30A17),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flagFrame({Decoration? decoration, Widget? child}) {
    return SizedBox(
      width: 32,
      height: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: decoration != null
            ? DecoratedBox(decoration: decoration)
            : child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outline, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.nightAccent.withValues(alpha: 0.58),
                AppTheme.panel.withValues(alpha: 0.42),
              ],
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleMarkIcon(size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
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

class _GoogleMarkIcon extends StatelessWidget {
  const _GoogleMarkIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.2;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, _deg(-40), _deg(82), false, arcPaint);

    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, _deg(45), _deg(96), false, arcPaint);

    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, _deg(143), _deg(96), false, arcPaint);

    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, _deg(238), _deg(103), false, arcPaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final centerY = size.height * 0.5;
    canvas.drawLine(
      Offset(size.width * 0.52, centerY),
      Offset(size.width * 0.86, centerY),
      barPaint,
    );
  }

  double _deg(double degrees) => degrees * (math.pi / 180);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final normalized = (value ?? '').trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (normalized.isEmpty) {
      return 'Enter your email address.';
    }
    if (!emailRegex.hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    Navigator.pop(context, _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
            boxShadow: [
              BoxShadow(
                color: AppTheme.night.withValues(alpha: 0.62),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We will send a reset link to your email.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Send Reset Link'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppTheme.accentYellow, AppTheme.accentOrange],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentYellow.withValues(alpha: 0.31),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BackgroundParticles extends StatelessWidget {
  const _BackgroundParticles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(top: 90, left: 70, child: _Dot(size: 3)),
          Positioned(top: 170, right: 72, child: _Dot(size: 4)),
          Positioned(top: 330, left: 36, child: _Dot(size: 2)),
          Positioned(top: 460, right: 40, child: _Dot(size: 3)),
          Positioned(bottom: 170, left: 92, child: _Dot(size: 4)),
          Positioned(bottom: 110, right: 110, child: _Dot(size: 2)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: 0.68),
        shape: BoxShape.circle,
      ),
    );
  }
}
