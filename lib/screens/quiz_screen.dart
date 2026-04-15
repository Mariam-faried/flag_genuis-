import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/question_model.dart';
import '../providers/quiz_provider.dart';
import '../widgets/answer_button.dart';
import '../widgets/lives_indicator.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _resultRouteOpen = false;

  void _openResultIfNeeded(QuizProvider provider) {
    if (_resultRouteOpen || !provider.hasAnsweredCurrent) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) {
      return;
    }

    _resultRouteOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.pushNamed(context, AppRoutes.result).whenComplete(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _resultRouteOpen = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final question = provider.currentQuestion;
    _openResultIfNeeded(provider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: question == null
              ? const _NoRoundView()
              : provider.isRoundOver
              ? _RoundOverView(provider: provider)
              : _ActiveQuizView(provider: provider, question: question),
        ),
      ),
    );
  }
}

class _ActiveQuizView extends StatelessWidget {
  const _ActiveQuizView({required this.provider, required this.question});

  final QuizProvider provider;
  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (_) => false,
                );
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Question ${provider.currentQuestionNumber} of ${provider.totalQuestions}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 10),
        _QuizTopBar(provider: provider),
        const SizedBox(height: 12),
        _TimerTrack(
          progress: provider.timerProgress,
          remainingSeconds: provider.remainingSeconds,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            children: [
              if (question.visualUrl != null && question.visualUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      question.visualUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              if (question.visualUrl != null && question.visualUrl!.isNotEmpty)
                const SizedBox(height: 14),
              Text(
                question.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...question.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnswerButton(
              label: option,
              isCorrect:
                  provider.hasAnsweredCurrent &&
                  option == question.correctAnswer,
              isWrong:
                  provider.hasAnsweredCurrent &&
                  provider.selectedAnswer == option &&
                  option != question.correctAnswer,
              isDisabled:
                  provider.hasAnsweredCurrent || provider.isSubmittingAnswer,
              onTap: () => context.read<QuizProvider>().submitAnswer(option),
            ),
          ),
        ),
        if (provider.isSubmittingAnswer)
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
      ],
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
  const _RoundOverView({required this.provider});

  final QuizProvider provider;

  @override
  Widget build(BuildContext context) {
    final result = provider.lastRoundResult;
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
                'Score: ${result?.score ?? provider.score}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Accuracy: ${result?.accuracyPercent.toStringAsFixed(1) ?? '0'}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Longest streak: ${result?.longestStreak ?? provider.longestStreak}',
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
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (_) => false,
                  ),
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
  const _QuizTopBar({required this.provider});

  final QuizProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopPill(
          icon: Icons.star_rounded,
          label: 'Score',
          value: provider.score.toString(),
          color: AppTheme.accentYellow,
        ),
        const SizedBox(width: 8),
        _TopPill(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: provider.streak.toString(),
          color: AppTheme.accentOrange,
        ),
        const Spacer(),
        LivesIndicator(lives: provider.lives),
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
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            '$label: $value',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TimerTrack extends StatelessWidget {
  const _TimerTrack({required this.progress, required this.remainingSeconds});

  final double progress;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final color = clamped > 0.6
        ? AppTheme.success
        : clamped > 0.3
        ? AppTheme.accentOrange
        : AppTheme.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time: ${remainingSeconds}s',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 10,
            backgroundColor: AppTheme.outline,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
