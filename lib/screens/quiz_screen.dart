import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/question_model.dart';
import '../providers/quiz_provider.dart';
import '../widgets/answer_button.dart';
import '../widgets/lives_indicator.dart';

void _showAnswerValidationMessage(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Please wait, answer validation is still in progress.'),
        duration: Duration(seconds: 2),
      ),
    );
}

void _exitQuizToHome(BuildContext context) {
  final provider = context.read<QuizProvider>();
  if (provider.isSubmittingAnswer) {
    _showAnswerValidationMessage(context);
    return;
  }

  provider.abandonRound();
  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final question = context.select<QuizProvider, QuestionModel?>(
      (provider) => provider.currentQuestion,
    );
    final isRoundOver = context.select<QuizProvider, bool>(
      (provider) => provider.isRoundOver,
    );
    final hasAnsweredCurrent = context.select<QuizProvider, bool>(
      (provider) => provider.hasAnsweredCurrent,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: WillPopScope(
          onWillPop: () async {
            _exitQuizToHome(context);
            return false;
          },
          child: SafeArea(
            child: question == null
                ? const _NoRoundView()
                : isRoundOver && !hasAnsweredCurrent
                ? const _RoundOverView()
                : _ActiveQuizView(question: question, isRoundOver: isRoundOver),
          ),
        ),
      ),
    );
  }
}

class _ActiveQuizView extends StatefulWidget {
  const _ActiveQuizView({required this.question, required this.isRoundOver});

  final QuestionModel question;
  final bool isRoundOver;

  @override
  State<_ActiveQuizView> createState() => _ActiveQuizViewState();
}

class _ActiveQuizViewState extends State<_ActiveQuizView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inlineResultKey = GlobalKey();
  bool _didScrollForCurrentAnswer = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInlineResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final resultContext = _inlineResultKey.currentContext;
      if (resultContext != null) {
        Scrollable.ensureVisible(
          resultContext,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: 0.06,
        );
        return;
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final isRoundOver = widget.isRoundOver;
    final answerState = context
        .select<
          QuizProvider,
          ({
            bool hasAnsweredCurrent,
            bool isSubmittingAnswer,
            String? selected,
            bool answerWasCorrect,
            int lastAnswerPoints,
          })
        >(
          (provider) => (
            hasAnsweredCurrent: provider.hasAnsweredCurrent,
            isSubmittingAnswer: provider.isSubmittingAnswer,
            selected: provider.selectedAnswer,
            answerWasCorrect: provider.answerWasCorrect,
            lastAnswerPoints: provider.lastAnswerPoints,
          ),
        );

    if (answerState.hasAnsweredCurrent && !_didScrollForCurrentAnswer) {
      _didScrollForCurrentAnswer = true;
      _scrollToInlineResult();
    } else if (!answerState.hasAnsweredCurrent && _didScrollForCurrentAnswer) {
      _didScrollForCurrentAnswer = false;
    }

    final timedOut =
        answerState.hasAnsweredCurrent && answerState.selected == null;
    final points = answerState.answerWasCorrect
        ? answerState.lastAnswerPoints
        : 0;

    final contentChildren = <Widget>[
      _QuestionPromptCard(question: question),
      const SizedBox(height: 14),
      ...question.options.asMap().entries.map((entry) {
        final optionIndex = entry.key;
        final option = entry.value;

        return _AnswerEntrance(
          index: optionIndex,
          questionSeed: question.hashCode,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnswerButton(
              optionIndex: optionIndex,
              label: option,
              isCorrect:
                  answerState.hasAnsweredCurrent &&
                  option == question.correctAnswer,
              isWrong:
                  answerState.hasAnsweredCurrent &&
                  answerState.selected == option &&
                  option != question.correctAnswer,
              isDisabled:
                  answerState.hasAnsweredCurrent ||
                  answerState.isSubmittingAnswer,
              onTap: () => context.read<QuizProvider>().submitAnswer(option),
            ),
          ),
        );
      }),
      if (answerState.isSubmittingAnswer)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.panelSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Validating answer...',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: answerState.hasAnsweredCurrent
            ? Padding(
                key: const ValueKey('inline-result-visible'),
                padding: const EdgeInsets.only(top: 12),
                child: KeyedSubtree(
                  key: _inlineResultKey,
                  child: _InlineResultPanel(
                    timedOut: timedOut,
                    isCorrect: answerState.answerWasCorrect,
                    isRoundOver: isRoundOver,
                    selectedAnswer: answerState.selected,
                    correctAnswer: question.correctAnswer,
                    points: points,
                    funFact: question.funFact,
                    onPrimaryPressed: () {
                      if (isRoundOver) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.summary,
                        );
                        return;
                      }
                      context.read<QuizProvider>().nextQuestion();
                    },
                    onQuitPressed: () {
                      _exitQuizToHome(context);
                    },
                  ),
                ),
              )
            : const SizedBox(key: ValueKey('inline-result-hidden'), height: 0),
      ),
      const SizedBox(height: 18),
    ];

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _QuizHeaderDelegate(
            extent: _PinnedQuizHeader.preferredExtent(context),
            child: const _PinnedQuizHeader(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate(contentChildren),
          ),
        ),
      ],
    );
  }
}

class _PinnedQuizHeader extends StatelessWidget {
  const _PinnedQuizHeader();

  static double preferredExtent(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final extraHeight = ((textScale - 1.0).clamp(0.0, 0.6)) * 18.0;
    return 188.0 + extraHeight;
  }

  @override
  Widget build(BuildContext context) {
    final isSubmittingAnswer = context.select<QuizProvider, bool>(
      (provider) => provider.isSubmittingAnswer,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.panel, AppTheme.nightAccent],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66010614),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: isSubmittingAnswer
                    ? null
                    : () => _exitQuizToHome(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(child: const _QuestionIndexLabel()),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 6),
          const _QuizTopBar(),
          const SizedBox(height: 10),
          const _TimerTrack(),
        ],
      ),
    );
  }
}

class _QuizHeaderDelegate extends SliverPersistentHeaderDelegate {
  _QuizHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _QuizHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

class _QuestionPromptCard extends StatelessWidget {
  const _QuestionPromptCard({required this.question});

  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    final hasVisual =
        question.visualUrl != null && question.visualUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          if (hasVisual)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: question.visualUrl!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 220),
                  placeholder: (_, __) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.shimmerBase,
                          AppTheme.shimmerHighlight,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.panelSoft,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          if (hasVisual) const SizedBox(height: 14),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _AnswerEntrance extends StatelessWidget {
  const _AnswerEntrance({
    required this.index,
    required this.questionSeed,
    required this.child,
  });

  final int index;
  final int questionSeed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('answer-$questionSeed-$index'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final offsetY = (1 - value) * 16;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, offsetY), child: child),
        );
      },
      child: child,
    );
  }
}

class _InlineResultPanel extends StatelessWidget {
  const _InlineResultPanel({
    required this.timedOut,
    required this.isCorrect,
    required this.isRoundOver,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.points,
    required this.onPrimaryPressed,
    required this.onQuitPressed,
    this.funFact,
  });

  final bool timedOut;
  final bool isCorrect;
  final bool isRoundOver;
  final String? selectedAnswer;
  final String correctAnswer;
  final int points;
  final String? funFact;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onQuitPressed;

  @override
  Widget build(BuildContext context) {
    final title = timedOut
        ? 'Time Is Up'
        : isCorrect
        ? 'Correct Answer'
        : 'Not Quite';
    final subtitle = timedOut
        ? 'You ran out of time for this question.'
        : isCorrect
        ? 'Great speed and accuracy.'
        : 'Keep pushing, the next one is yours.';
    final icon = timedOut
        ? Icons.schedule_rounded
        : isCorrect
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final accent = timedOut
        ? AppTheme.accentOrange
        : isCorrect
        ? AppTheme.success
        : AppTheme.danger;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.panel, AppTheme.nightAccent],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6B020611),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Icon(icon, size: 50, color: accent)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _InlineResultRow(
              label: timedOut
                  ? 'Your answer'
                  : (isCorrect ? 'Your answer' : 'Selected'),
              value: selectedAnswer ?? 'No answer',
            ),
            _InlineResultRow(label: 'Correct answer', value: correctAnswer),
            _InlineResultRow(label: 'Points', value: '+$points'),
            if ((funFact ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.panelSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  funFact!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
                ),
              ),
            ],
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppTheme.accentYellow, AppTheme.accentOrange],
                ),
                boxShadow: const [AppTheme.glowYellow],
              ),
              child: ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(isRoundOver ? 'View Summary' : 'Next Question'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onQuitPressed,
              child: const Text('Quit Round'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineResultRow extends StatelessWidget {
  const _InlineResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.panelSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionIndexLabel extends StatelessWidget {
  const _QuestionIndexLabel();

  @override
  Widget build(BuildContext context) {
    final questionProgress = context
        .select<QuizProvider, ({int currentQuestion, int totalQuestions})>(
          (provider) => (
            currentQuestion: provider.currentQuestionNumber,
            totalQuestions: provider.totalQuestions,
          ),
        );

    return Text(
      'Question ${questionProgress.currentQuestion} of ${questionProgress.totalQuestions}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _NoRoundView extends StatelessWidget {
  const _NoRoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.quiz_outlined,
              size: 52,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(height: 12),
            Text(
              'No active round',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new game mode to begin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.modeSelect),
              child: const Text('Start a Round'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundOverView extends StatelessWidget {
  const _RoundOverView();

  @override
  Widget build(BuildContext context) {
    final stats = context
        .select<
          QuizProvider,
          ({int score, double accuracyPercent, int longestStreak})
        >((provider) {
          final result = provider.lastRoundResult;
          return (
            score: result?.score ?? provider.score,
            accuracyPercent: result?.accuracyPercent ?? 0,
            longestStreak: result?.longestStreak ?? provider.longestStreak,
          );
        });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 58,
                color: AppTheme.accentYellow,
              ),
              const SizedBox(height: 10),
              Text(
                'Round Complete',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Score: ${stats.score}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Accuracy: ${stats.accuracyPercent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Longest streak: ${stats.longestStreak}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.summary,
                  ),
                  child: const Text('View Summary'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _exitQuizToHome(context),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizTopBar extends StatelessWidget {
  const _QuizTopBar();

  @override
  Widget build(BuildContext context) {
    final topBarStats = context
        .select<QuizProvider, ({int score, int streak, int lives})>(
          (provider) => (
            score: provider.score,
            streak: provider.streak,
            lives: provider.lives,
          ),
        );

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                _TopPill(
                  icon: Icons.star_rounded,
                  label: 'Score',
                  value: topBarStats.score,
                  color: AppTheme.accentYellow,
                ),
                const SizedBox(width: 8),
                _TopPill(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Streak',
                  value: topBarStats.streak,
                  color: AppTheme.accentOrange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        LivesIndicator(lives: topBarStats.lives),
      ],
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$label-$value'),
      tween: Tween<double>(begin: 1.12, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.panelSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                '$value',
                key: ValueKey('$label-value-$value'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerTrack extends StatelessWidget {
  const _TimerTrack();

  @override
  Widget build(BuildContext context) {
    final timerState = context
        .select<
          QuizProvider,
          ({double progress, int remainingSeconds, bool hasAnsweredCurrent})
        >(
          (provider) => (
            progress: provider.timerProgress,
            remainingSeconds: provider.remainingSeconds,
            hasAnsweredCurrent: provider.hasAnsweredCurrent,
          ),
        );
    final clamped = timerState.progress.clamp(0.0, 1.0).toDouble();
    final isUrgent =
        !timerState.hasAnsweredCurrent &&
        timerState.remainingSeconds > 0 &&
        timerState.remainingSeconds <= 3;
    final pulseScale = isUrgent && timerState.remainingSeconds.isOdd
        ? 1.03
        : 1.0;

    final fillGradient = clamped > 0.6
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF22C55E), Color(0xFF15803D)],
          )
        : clamped > 0.3
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppTheme.accentYellow, AppTheme.accentOrange],
          )
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFB7185), Color(0xFFEF4444)],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              scale: pulseScale,
              alignment: Alignment.centerLeft,
              child: Text(
                'Timer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUrgent ? AppTheme.danger : AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Container(
                key: ValueKey('timer-${timerState.remainingSeconds}'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppTheme.danger.withValues(alpha: 0.16)
                      : AppTheme.panelSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isUrgent ? AppTheme.danger : AppTheme.outline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUrgent
                          ? Icons.warning_amber_rounded
                          : Icons.timer_rounded,
                      size: 14,
                      color: isUrgent
                          ? AppTheme.danger
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${timerState.remainingSeconds}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUrgent
                            ? AppTheme.danger
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            boxShadow: isUrgent
                ? [
                    BoxShadow(
                      color: AppTheme.danger.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 0.2,
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: isUrgent ? 12 : 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppTheme.outline.withValues(alpha: 0.35)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List<Widget>.generate(5, (index) {
                      return Container(
                        width: 1,
                        color: AppTheme.night.withValues(alpha: 0.25),
                      );
                    }),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clamped,
                      child: Container(
                        decoration: BoxDecoration(gradient: fillGradient),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
