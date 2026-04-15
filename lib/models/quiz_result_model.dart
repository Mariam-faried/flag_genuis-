import 'badge_model.dart';
import 'question_model.dart';

class QuizResultModel {
  QuizResultModel({
    required this.mode,
    required this.difficulty,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.longestStreak,
    required this.newBadges,
  });

  final QuizMode mode;
  final QuizDifficulty difficulty;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int longestStreak;
  final Set<BadgeType> newBadges;

  int get totalAnswered => correctAnswers + wrongAnswers;

  double get accuracyPercent {
    if (totalAnswered == 0) {
      return 0;
    }
    return (correctAnswers / totalAnswered) * 100;
  }

  int get stars {
    if (accuracyPercent >= 90) {
      return 3;
    }
    if (accuracyPercent >= 70) {
      return 2;
    }
    return 1;
  }
}
