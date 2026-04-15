import 'dart:math';

import '../models/country_model.dart';
import '../models/question_model.dart';

class QuestionGenerator {
  QuestionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<QuestionModel> generateQuestions({
    required List<CountryModel> countries,
    required QuizMode mode,
    required int count,
  }) {
    if (countries.length < 4) {
      return [];
    }

    final questions = <QuestionModel>[];
    final maxAttempts = count * 12;
    var attempts = 0;

    while (questions.length < count && attempts < maxAttempts) {
      attempts++;
      final activeMode = mode == QuizMode.randomMix
          ? _pickRandomCoreMode()
          : mode;

      final question = switch (activeMode) {
        QuizMode.flag => _buildFlagQuestion(countries),
        QuizMode.capital => _buildCapitalQuestion(countries),
        QuizMode.population => _buildPopulationQuestion(countries),
        QuizMode.region => _buildRegionQuestion(countries),
        QuizMode.randomMix => null,
      };

      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  QuizMode _pickRandomCoreMode() {
    const modes = [
      QuizMode.flag,
      QuizMode.capital,
      QuizMode.population,
      QuizMode.region,
    ];
    return modes[_random.nextInt(modes.length)];
  }

  QuestionModel? _buildFlagQuestion(List<CountryModel> countries) {
    final validCountries = countries
        .where((country) => country.hasFlag && country.nameCommon.isNotEmpty)
        .toList();
    if (validCountries.length < 4) {
      return null;
    }

    final correctCountry =
        validCountries[_random.nextInt(validCountries.length)];
    final wrongOptions = _collectUniqueOptions(
      source: validCountries,
      excludedCountry: correctCountry,
      mapper: (country) => country.nameCommon,
      neededCount: 3,
    );

    if (wrongOptions.length < 3) {
      return null;
    }

    final options = <String>[correctCountry.nameCommon, ...wrongOptions]
      ..shuffle(_random);

    return QuestionModel(
      mode: QuizMode.flag,
      prompt: 'Which country does this flag belong to?',
      options: options,
      correctAnswer: correctCountry.nameCommon,
      country: correctCountry,
      visualUrl: correctCountry.flagPng,
      funFact: _buildFunFact(correctCountry),
    );
  }

  QuestionModel? _buildCapitalQuestion(List<CountryModel> countries) {
    final validCountries = countries
        .where((country) => country.hasCapital)
        .toList();
    if (validCountries.length < 4) {
      return null;
    }

    final correctCountry =
        validCountries[_random.nextInt(validCountries.length)];
    final correctCapital = correctCountry.primaryCapital;

    final wrongOptions = _collectUniqueOptions(
      source: validCountries,
      excludedCountry: correctCountry,
      mapper: (country) => country.primaryCapital,
      neededCount: 3,
    );

    if (wrongOptions.length < 3) {
      return null;
    }

    final options = <String>[correctCapital, ...wrongOptions]..shuffle(_random);

    return QuestionModel(
      mode: QuizMode.capital,
      prompt: 'What is the capital of ${correctCountry.nameCommon}?',
      options: options,
      correctAnswer: correctCapital,
      country: correctCountry,
      funFact: _buildFunFact(correctCountry),
    );
  }

  QuestionModel? _buildPopulationQuestion(List<CountryModel> countries) {
    final validCountries = countries
        .where((country) => country.population > 0)
        .toList();
    if (validCountries.length < 4) {
      return null;
    }

    final sample = List<CountryModel>.from(validCountries)..shuffle(_random);
    final optionsCountries = sample.take(4).toList();

    final correctCountry = optionsCountries.reduce(
      (current, next) => current.population >= next.population ? current : next,
    );

    final options =
        optionsCountries.map((country) => country.nameCommon).toList()
          ..shuffle(_random);

    return QuestionModel(
      mode: QuizMode.population,
      prompt: 'Which country has the highest population?',
      options: options,
      correctAnswer: correctCountry.nameCommon,
      country: correctCountry,
      funFact:
          '${correctCountry.nameCommon} has around ${_formatPopulation(correctCountry.population)} people.',
    );
  }

  QuestionModel? _buildRegionQuestion(List<CountryModel> countries) {
    final validCountries = countries
        .where((country) => country.region.isNotEmpty)
        .toList();
    final regionPool = validCountries
        .map((country) => country.region)
        .where((region) => region.trim().isNotEmpty)
        .toSet()
        .toList();

    if (validCountries.isEmpty || regionPool.length < 4) {
      return null;
    }

    final correctCountry =
        validCountries[_random.nextInt(validCountries.length)];
    final correctRegion = correctCountry.region;
    final wrongRegions = List<String>.from(
      regionPool.where((region) => region != correctRegion),
    )..shuffle(_random);

    if (wrongRegions.length < 3) {
      return null;
    }

    final options = <String>[correctRegion, ...wrongRegions.take(3)]
      ..shuffle(_random);

    return QuestionModel(
      mode: QuizMode.region,
      prompt: 'Which region does ${correctCountry.nameCommon} belong to?',
      options: options,
      correctAnswer: correctRegion,
      country: correctCountry,
      funFact: _buildFunFact(correctCountry),
    );
  }

  List<String> _collectUniqueOptions({
    required List<CountryModel> source,
    required CountryModel excludedCountry,
    required String Function(CountryModel country) mapper,
    required int neededCount,
  }) {
    final copy = List<CountryModel>.from(source)..shuffle(_random);
    final values = <String>{};

    for (final country in copy) {
      if (country.nameCommon == excludedCountry.nameCommon) {
        continue;
      }

      final mapped = mapper(country).trim();
      if (mapped.isEmpty) {
        continue;
      }

      values.add(mapped);
      if (values.length == neededCount) {
        break;
      }
    }

    return values.toList();
  }

  String _buildFunFact(CountryModel country) {
    final parts = <String>[
      '${country.nameCommon} is part of ${country.regionLabel}.',
      'Population: ${_formatPopulation(country.population)}.',
    ];

    if (country.capital.isNotEmpty) {
      parts.add('Capital: ${country.primaryCapital}.');
    }

    return parts.join(' ');
  }

  String _formatPopulation(int value) {
    final digits = value.toString();
    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
