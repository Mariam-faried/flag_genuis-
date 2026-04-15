class QuizRules {
  static const int fastThresholdSeconds = 3;
  static const int mediumThresholdSeconds = 6;
  static const int slowThresholdSeconds = 10;

  static const int fastPoints = 20;
  static const int mediumPoints = 15;
  static const int slowPoints = 10;

  static const int streakMultiplierStart = 5;
  static const double streakMultiplier = 1.5;

  static int pointsForElapsedSeconds(int elapsedSeconds) {
    if (elapsedSeconds <= fastThresholdSeconds) {
      return fastPoints;
    }
    if (elapsedSeconds <= mediumThresholdSeconds) {
      return mediumPoints;
    }
    if (elapsedSeconds <= slowThresholdSeconds) {
      return slowPoints;
    }
    return 0;
  }

  static bool isMultiplierActive(int streak) => streak >= streakMultiplierStart;

  static int applyStreakMultiplier(int basePoints, int streak) {
    if (!isMultiplierActive(streak)) {
      return basePoints;
    }
    return (basePoints * streakMultiplier).round();
  }

  static int maxPossibleRoundScore({required int questionCount}) {
    if (questionCount <= 0) {
      return 0;
    }

    final nonBoostedQuestions = (streakMultiplierStart - 1)
        .clamp(0, questionCount)
        .toInt();
    final boostedQuestions = (questionCount - nonBoostedQuestions).clamp(
      0,
      questionCount,
    );
    final boostedFastPoints = (fastPoints * streakMultiplier).round();

    return (nonBoostedQuestions * fastPoints) +
        (boostedQuestions * boostedFastPoints);
  }
}
