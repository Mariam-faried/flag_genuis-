import 'country_model.dart';

enum QuizMode { flag, capital, population, region, randomMix }

enum QuizDifficulty { easy, medium, hard }

extension QuizModeX on QuizMode {
  String get label {
    switch (this) {
      case QuizMode.flag:
        return 'Flag Quiz';
      case QuizMode.capital:
        return 'Capital Quiz';
      case QuizMode.population:
        return 'Population Quiz';
      case QuizMode.region:
        return 'Region Quiz';
      case QuizMode.randomMix:
        return 'Random Mix';
    }
  }
}

extension QuizDifficultyX on QuizDifficulty {
  String get label {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
    }
  }
}

class QuestionModel {
  QuestionModel({
    required this.mode,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.country,
    this.visualUrl,
    this.funFact,
  });

  final QuizMode mode;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final CountryModel country;
  final String? visualUrl;
  final String? funFact;

  bool isCorrect(String answer) => answer.trim() == correctAnswer;
}
