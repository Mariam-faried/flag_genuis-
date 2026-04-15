import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/quiz_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final question = provider.currentQuestion;

    if (question == null) {
      return _FallbackResultScaffold(
        title: 'No active round',
        subtitle: 'Start a round first to see question results.',
        actionLabel: 'Back to Home',
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        ),
      );
    }

    if (!provider.hasAnsweredCurrent) {
      return _FallbackResultScaffold(
        title: 'No answer yet',
        subtitle: 'Answer the current question to view result details.',
        actionLabel: 'Back to Quiz',
        onPressed: () => Navigator.pop(context),
      );
    }

    final timedOut = provider.selectedAnswer == null;
    final isCorrect = provider.answerWasCorrect;
    final isRoundOver = provider.isRoundOver;

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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(icon, size: 58, color: accent),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _ResultRow(
                      label: timedOut
                          ? 'Your answer'
                          : (isCorrect ? 'Your answer' : 'Selected'),
                      value: provider.selectedAnswer ?? 'No answer',
                    ),
                    _ResultRow(
                      label: 'Correct answer',
                      value: question.correctAnswer,
                    ),
                    _ResultRow(
                      label: 'Points',
                      value: isCorrect ? '+${provider.lastAnswerPoints}' : '+0',
                    ),
                    if ((question.funFact ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.panelSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Text(
                          question.funFact!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.accentYellow,
                            AppTheme.accentOrange,
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (isRoundOver) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.summary,
                            );
                            return;
                          }

                          context.read<QuizProvider>().nextQuestion();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          isRoundOver ? 'View Summary' : 'Next Question',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (_) => false,
                      ),
                      child: const Text('Quit Round'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

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

class _FallbackResultScaffold extends StatelessWidget {
  const _FallbackResultScaffold({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

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
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onPressed,
                    child: Text(actionLabel),
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
