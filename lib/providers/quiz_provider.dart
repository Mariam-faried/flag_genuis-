import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/quiz_rules.dart';
import '../models/badge_model.dart';
import '../models/country_model.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/daily_challenge_service.dart';
import '../services/feedback_service.dart';
import '../services/firestore_service.dart';
import '../services/question_generator.dart';

class QuizProvider extends ChangeNotifier {
  QuizProvider({
    required ApiService apiService,
    required AuthService authService,
    required FirestoreService firestoreService,
    required FeedbackService feedbackService,
    required DailyChallengeService dailyChallengeService,
    QuestionGenerator? questionGenerator,
  }) : _apiService = apiService,
       _authService = authService,
       _firestoreService = firestoreService,
       _feedbackService = feedbackService,
       _dailyChallengeService = dailyChallengeService,
       _questionGenerator = questionGenerator ?? QuestionGenerator();

  final ApiService _apiService;
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final FeedbackService _feedbackService;
  final DailyChallengeService _dailyChallengeService;
  final QuestionGenerator _questionGenerator;

  final Set<BadgeType> _earnedBadges = <BadgeType>{};
  final Set<QuizMode> _playedModes = <QuizMode>{};

  List<CountryModel> _countries = <CountryModel>[];
  List<QuestionModel> _questions = <QuestionModel>[];
  Set<BadgeType> _newBadgesThisRound = <BadgeType>{};

  bool _isLoadingCountries = false;
  String? _loadError;

  QuizMode _selectedMode = QuizMode.flag;
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;
  QuizResultModel? _lastRoundResult;
  Timer? _timer;

  int _currentQuestionIndex = 0;
  int _remainingSeconds = AppConstants.questionTimeLimitSeconds;
  int _score = 0;
  int _lives = AppConstants.maxLives;
  int _streak = 0;
  int _longestStreak = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _lastAnswerPoints = 0;

  int _gamesPlayed = 0;
  int _lifetimeScore = 0;
  int _bestScore = 0;
  int _dailyChallengeStreak = 0;
  DateTime? _lastDailyChallengeDate;
  int _simulatedLeaderboardRank = 999;

  bool _isSyncingProgress = false;
  String? _syncError;

  bool _hasAnsweredCurrent = false;
  bool _answerWasCorrect = false;
  bool _roundCompleted = false;
  String? _selectedAnswer;
  bool _isSubmittingAnswer = false;
  bool _isDailyChallengeActive = false;
  bool _isUsingLocalDailyChallengeFallback = false;
  String? _dailyChallengeNotice;
  QuestionModel? _pendingDailyNextQuestion;
  String? _dailyChallengeDateKey;
  int _activeRoundQuestionCount = 0;

  bool get isLoadingCountries => _isLoadingCountries;
  String? get loadError => _loadError;

  List<CountryModel> get countries =>
      List<CountryModel>.unmodifiable(_countries);
  int get countriesCount => _countries.length;

  List<QuestionModel> get questions =>
      List<QuestionModel>.unmodifiable(_questions);
  QuestionModel? get currentQuestion {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }

  QuizMode get selectedMode => _selectedMode;
  QuizDifficulty get selectedDifficulty => _selectedDifficulty;

  int get currentQuestionNumber =>
      _questions.isEmpty ? 0 : _currentQuestionIndex + 1;
  int get totalQuestions {
    if (_activeRoundQuestionCount > 0) {
      return _activeRoundQuestionCount;
    }
    return _questions.length;
  }

  int get remainingSeconds => _remainingSeconds;
  double get timerProgress {
    return _remainingSeconds / AppConstants.questionTimeLimitSeconds;
  }

  int get score => _score;
  int get lives => _lives;
  int get streak => _streak;
  int get longestStreak => _longestStreak;
  int get lastAnswerPoints => _lastAnswerPoints;

  bool get hasAnsweredCurrent => _hasAnsweredCurrent;
  bool get answerWasCorrect => _answerWasCorrect;
  String? get selectedAnswer => _selectedAnswer;
  bool get isRoundOver => _roundCompleted;
  bool get isSubmittingAnswer => _isSubmittingAnswer;
  bool get isDailyChallengeActive => _isDailyChallengeActive;
  bool get isUsingLocalDailyChallengeFallback =>
      _isUsingLocalDailyChallengeFallback;
  String? get dailyChallengeNotice => _dailyChallengeNotice;

  QuizResultModel? get lastRoundResult => _lastRoundResult;

  int get gamesPlayed => _gamesPlayed;
  int get lifetimeScore => _lifetimeScore;
  int get bestScore => _bestScore;
  int get dailyChallengeStreak => _dailyChallengeStreak;
  DateTime? get lastDailyChallengeDate => _lastDailyChallengeDate;
  int get simulatedLeaderboardRank => _simulatedLeaderboardRank;

  bool get isSyncingProgress => _isSyncingProgress;
  String? get syncError => _syncError;
  bool get canCompleteDailyChallengeToday {
    final lastPlayedDay = _lastDailyChallengeDate;
    if (lastPlayedDay == null) {
      return true;
    }
    return !_isSameDay(lastPlayedDay, DateTime.now().toLocal());
  }

  QuizMode get todayDailyChallengeMode => _dailyChallengeConfigForToday().mode;
  QuizDifficulty get todayDailyChallengeDifficulty =>
      _dailyChallengeConfigForToday().difficulty;
  String get todayDailyChallengeLabel {
    final config = _dailyChallengeConfigForToday();
    return '${config.mode.label} - ${config.difficulty.label}';
  }

  Set<BadgeType> get earnedBadges => Set<BadgeType>.unmodifiable(_earnedBadges);
  Set<BadgeType> get newBadgesThisRound =>
      Set<BadgeType>.unmodifiable(_newBadgesThisRound);

  Future<void> initializeCountries() async {
    if (_isLoadingCountries || _countries.isNotEmpty) {
      return;
    }

    _isLoadingCountries = true;
    _loadError = null;
    notifyListeners();

    try {
      final fetched = await _apiService.fetchCountries();

      if (fetched.length < AppConstants.minCountriesToStart) {
        throw Exception('Not enough countries to generate quiz questions.');
      }

      _countries = fetched;
    } catch (error) {
      _loadError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingCountries = false;
      notifyListeners();
    }
  }

  Future<void> hydrateProgressFromCloud() async {
    final user = _authService.currentUser;
    if (user == null) {
      _resetPersistentProgress(notify: true);
      return;
    }

    _isSyncingProgress = true;
    _syncError = null;
    notifyListeners();

    try {
      await _firestoreService.ensureUserDocument(user);
      final progress = await _firestoreService.fetchUserProgress(user);

      _resetPersistentProgress(notify: false);
      if (progress != null) {
        _gamesPlayed = progress.gamesPlayed;
        _lifetimeScore = progress.lifetimeScore;
        _bestScore = progress.bestScore;
        _dailyChallengeStreak = progress.dailyChallengeStreak;
        _lastDailyChallengeDate = progress.lastDailyChallengeDate?.toLocal();
        _earnedBadges
          ..clear()
          ..addAll(progress.earnedBadges);
      }

      await _refreshCurrentUserRank(notify: false);
    } catch (error) {
      _syncError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSyncingProgress = false;
      notifyListeners();
    }
  }

  void clearCloudBackedProgress() {
    _resetPersistentProgress(notify: true);
  }

  void startRound({
    required QuizMode mode,
    required QuizDifficulty difficulty,
  }) {
    _isDailyChallengeActive = false;
    _isUsingLocalDailyChallengeFallback = false;
    _dailyChallengeNotice = null;
    _startRoundInternal(
      mode: mode,
      difficulty: difficulty,
      questionGenerator: _questionGenerator,
    );
  }

  Future<bool> startDailyChallengeRound() async {
    if (_countries.isEmpty) {
      _loadError = 'Country data is not loaded yet.';
      notifyListeners();
      return false;
    }

    if (!canCompleteDailyChallengeToday) {
      _loadError = 'Daily challenge is already completed today.';
      notifyListeners();
      return false;
    }

    _loadError = null;
    _dailyChallengeNotice = null;
    _isUsingLocalDailyChallengeFallback = false;
    _roundCompleted = false;
    _newBadgesThisRound = <BadgeType>{};
    _lastRoundResult = null;
    _pendingDailyNextQuestion = null;
    _isSubmittingAnswer = false;
    _resetRoundState();
    notifyListeners();

    try {
      final payload = await _dailyChallengeService.startDailyChallenge();
      final status = (payload['status'] as String? ?? 'in_progress').trim();
      final dateKey = (payload['dateKey'] as String? ?? '').trim();

      if (status == 'completed') {
        _isDailyChallengeActive = false;
        if (dateKey.isNotEmpty) {
          _lastDailyChallengeDate = _dateFromDateKey(dateKey);
        }
        _loadError = 'Daily challenge already completed today.';
        notifyListeners();
        return false;
      }

      final mode = _parseQuizMode(payload['mode']) ?? QuizMode.flag;
      final difficulty =
          _parseQuizDifficulty(payload['difficulty']) ?? QuizDifficulty.medium;
      final questionMap = _asMap(payload['question']);
      final question = _questionFromServerMap(
        questionMap,
        includeAnswer: false,
      );

      if (question == null) {
        _isDailyChallengeActive = false;
        _loadError = 'Daily challenge question payload is invalid.';
        notifyListeners();
        return false;
      }

      _selectedMode = mode;
      _selectedDifficulty = difficulty;
      _dailyChallengeDateKey = dateKey.isEmpty ? null : dateKey;
      _isDailyChallengeActive = true;
      _activeRoundQuestionCount =
          (payload['questionCount'] as num?)?.toInt() ??
          _questionCountForDifficulty(difficulty);

      _questions = <QuestionModel>[question];
      _currentQuestionIndex =
          (payload['currentQuestionIndex'] as num?)?.toInt() ?? 0;
      _score = (payload['score'] as num?)?.toInt() ?? 0;
      _lives = (payload['lives'] as num?)?.toInt() ?? AppConstants.maxLives;
      _streak = (payload['streak'] as num?)?.toInt() ?? 0;
      _longestStreak = (payload['longestStreak'] as num?)?.toInt() ?? 0;
      _correctAnswers = (payload['correctAnswers'] as num?)?.toInt() ?? 0;
      _wrongAnswers = (payload['wrongAnswers'] as num?)?.toInt() ?? 0;
      _hasAnsweredCurrent = false;
      _answerWasCorrect = false;
      _selectedAnswer = null;
      _lastAnswerPoints = 0;
      _roundCompleted = false;
      _pendingDailyNextQuestion = null;

      _startTimer();
      notifyListeners();
      return true;
    } catch (error) {
      final fallbackStarted = _startLocalDailyChallengeFallbackRound();
      if (fallbackStarted) {
        _isUsingLocalDailyChallengeFallback = true;
        _dailyChallengeNotice =
            'Cloud daily challenge unavailable. Running local demo challenge.';
        notifyListeners();
        return true;
      }

      _isDailyChallengeActive = false;
      _loadError = _readableError(error);
      notifyListeners();
      return false;
    }
  }

  bool _startRoundInternal({
    required QuizMode mode,
    required QuizDifficulty difficulty,
    required QuestionGenerator questionGenerator,
  }) {
    _loadError = null;

    if (_countries.isEmpty) {
      _loadError = 'Country data is not loaded yet.';
      notifyListeners();
      return false;
    }

    _selectedMode = mode;
    _selectedDifficulty = difficulty;
    _roundCompleted = false;
    _newBadgesThisRound = <BadgeType>{};
    _lastRoundResult = null;
    _dailyChallengeDateKey = null;
    _pendingDailyNextQuestion = null;

    _resetRoundState();

    final questionCount = _questionCountForDifficulty(difficulty);
    _questions = questionGenerator.generateQuestions(
      countries: _countries,
      mode: mode,
      count: questionCount,
    );

    if (_questions.isEmpty) {
      _loadError = 'Could not generate enough questions for this mode.';
      notifyListeners();
      return false;
    }

    _activeRoundQuestionCount = questionCount;

    if (mode != QuizMode.randomMix) {
      _playedModes.add(mode);
    }

    _startTimer();
    notifyListeners();
    return true;
  }

  Future<bool> submitAnswer(String? answer) async {
    if (_hasAnsweredCurrent ||
        _roundCompleted ||
        _isSubmittingAnswer ||
        currentQuestion == null) {
      return false;
    }

    _timer?.cancel();

    if (_isDailyChallengeActive && _dailyChallengeDateKey != null) {
      return _submitDailyChallengeAnswer(answer);
    }

    _hasAnsweredCurrent = true;
    _selectedAnswer = answer;

    final question = currentQuestion!;
    final isCorrect = answer != null && question.isCorrect(answer);
    _answerWasCorrect = isCorrect;

    if (isCorrect) {
      _correctAnswers++;
      _streak++;
      _longestStreak = max(_longestStreak, _streak);

      final elapsed = AppConstants.questionTimeLimitSeconds - _remainingSeconds;
      final basePoints = QuizRules.pointsForElapsedSeconds(
        elapsed.clamp(0, AppConstants.questionTimeLimitSeconds).toInt(),
      );
      _lastAnswerPoints = QuizRules.applyStreakMultiplier(basePoints, _streak);
      _score += _lastAnswerPoints;
      unawaited(_feedbackService.playCorrect());
    } else {
      _wrongAnswers++;
      _streak = 0;
      _lastAnswerPoints = 0;
      _lives = max(0, _lives - 1);
      unawaited(_feedbackService.playWrong());
    }

    if (_lives == 0 || _currentQuestionIndex >= _questions.length - 1) {
      _completeRound();
    }

    notifyListeners();
    return isCorrect;
  }

  Future<bool> _submitDailyChallengeAnswer(String? answer) async {
    if (_dailyChallengeDateKey == null || currentQuestion == null) {
      _loadError = 'Daily challenge session is not ready.';
      notifyListeners();
      return false;
    }

    _isSubmittingAnswer = true;
    notifyListeners();

    try {
      final payload = await _dailyChallengeService.submitDailyChallengeAnswer(
        dateKey: _dailyChallengeDateKey!,
        selectedAnswer: answer,
      );

      final answerResult = _asMap(payload['answerResult']);
      final question = currentQuestion!;
      final solvedQuestion = QuestionModel(
        mode: question.mode,
        prompt: question.prompt,
        options: List<String>.from(question.options),
        correctAnswer: (answerResult['correctAnswer'] as String?)?.trim() ?? '',
        country: question.country,
        visualUrl: question.visualUrl,
        funFact: (answerResult['funFact'] as String?)?.trim(),
      );
      _questions[_currentQuestionIndex] = solvedQuestion;

      _hasAnsweredCurrent = true;
      _selectedAnswer = (answerResult['selectedAnswer'] as String?)?.trim();
      if (_selectedAnswer != null && _selectedAnswer!.isEmpty) {
        _selectedAnswer = null;
      }
      _answerWasCorrect = answerResult['isCorrect'] == true;
      _lastAnswerPoints = (answerResult['points'] as num?)?.toInt() ?? 0;

      _score = (payload['score'] as num?)?.toInt() ?? _score;
      _lives = (payload['lives'] as num?)?.toInt() ?? _lives;
      _streak = (payload['streak'] as num?)?.toInt() ?? _streak;
      _longestStreak =
          (payload['longestStreak'] as num?)?.toInt() ?? _longestStreak;
      _correctAnswers =
          (payload['correctAnswers'] as num?)?.toInt() ?? _correctAnswers;
      _wrongAnswers =
          (payload['wrongAnswers'] as num?)?.toInt() ?? _wrongAnswers;

      if (_answerWasCorrect) {
        unawaited(_feedbackService.playCorrect());
      } else {
        unawaited(_feedbackService.playWrong());
      }

      final roundOver = payload['roundOver'] == true;
      _roundCompleted = roundOver;

      if (!roundOver) {
        final nextQuestion = _questionFromServerMap(
          _asMap(payload['nextQuestion']),
          includeAnswer: false,
        );
        if (nextQuestion == null) {
          throw Exception('Server response is missing the next question.');
        }
        _pendingDailyNextQuestion = nextQuestion;
        _isSubmittingAnswer = false;
        notifyListeners();
        return _answerWasCorrect;
      }

      _pendingDailyNextQuestion = null;
      _isDailyChallengeActive = false;
      _isSubmittingAnswer = false;

      final dateKey = (payload['dateKey'] as String?)?.trim();
      if (dateKey != null && dateKey.isNotEmpty) {
        _lastDailyChallengeDate = _dateFromDateKey(dateKey);
      }

      final summary = _asMap(payload['summary']);
      final serverStreak = (summary['dailyChallengeStreak'] as num?)?.toInt();
      if (serverStreak != null) {
        _dailyChallengeStreak = serverStreak;
      } else {
        _applyDailyChallengeCompletion();
      }

      _gamesPlayed = (_gamesPlayed + 1).clamp(0, 1000000).toInt();
      _lifetimeScore = (_lifetimeScore + _score).clamp(0, 100000000).toInt();
      _bestScore = max(_bestScore, _score);

      for (final playedQuestion in _questions) {
        if (playedQuestion.mode != QuizMode.randomMix) {
          _playedModes.add(playedQuestion.mode);
        }
      }

      _newBadgesThisRound = _evaluateNewBadges();
      _lastRoundResult = QuizResultModel(
        mode: _selectedMode,
        difficulty: _selectedDifficulty,
        score: _score,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        longestStreak: _longestStreak,
        newBadges: _newBadgesThisRound,
      );

      _dailyChallengeDateKey = null;
      unawaited(_feedbackService.playRoundComplete());
      notifyListeners();
      return _answerWasCorrect;
    } catch (error) {
      _loadError = _readableError(error);
      _isSubmittingAnswer = false;
      if (!_hasAnsweredCurrent) {
        _startTimer();
      }
      notifyListeners();
      return false;
    }
  }

  void nextQuestion() {
    if (!_hasAnsweredCurrent || _roundCompleted) {
      return;
    }

    if (_isDailyChallengeActive && _pendingDailyNextQuestion != null) {
      _currentQuestionIndex++;
      if (_questions.length <= _currentQuestionIndex) {
        _questions.add(_pendingDailyNextQuestion!);
      } else {
        _questions[_currentQuestionIndex] = _pendingDailyNextQuestion!;
      }

      _pendingDailyNextQuestion = null;
      _hasAnsweredCurrent = false;
      _answerWasCorrect = false;
      _selectedAnswer = null;
      _lastAnswerPoints = 0;
      _isSubmittingAnswer = false;
      unawaited(_feedbackService.playTap());
      _startTimer();
      notifyListeners();
      return;
    }

    if (_currentQuestionIndex >= _questions.length - 1) {
      _completeRound();
      notifyListeners();
      return;
    }

    _currentQuestionIndex++;
    _hasAnsweredCurrent = false;
    _answerWasCorrect = false;
    _selectedAnswer = null;
    _lastAnswerPoints = 0;
    _isSubmittingAnswer = false;
    unawaited(_feedbackService.playTap());
    _startTimer();
    notifyListeners();
  }

  bool markDailyChallengeCompleted() {
    if (!_applyDailyChallengeCompletion()) {
      return false;
    }
    notifyListeners();
    unawaited(_syncProgressToCloud(refreshRank: false));
    return true;
  }

  void setSimulatedLeaderboardRank(int rank) {
    if (_simulatedLeaderboardRank == rank) {
      return;
    }
    _simulatedLeaderboardRank = rank;
    notifyListeners();
  }

  Future<void> refreshCurrentUserRank() async {
    await _refreshCurrentUserRank(notify: true);
  }

  int _questionCountForDifficulty(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 8;
      case QuizDifficulty.medium:
        return 10;
      case QuizDifficulty.hard:
        return 12;
    }
  }

  void _resetRoundState() {
    _questions = <QuestionModel>[];
    _activeRoundQuestionCount = 0;
    _currentQuestionIndex = 0;
    _remainingSeconds = AppConstants.questionTimeLimitSeconds;
    _score = 0;
    _lives = AppConstants.maxLives;
    _streak = 0;
    _longestStreak = 0;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    _lastAnswerPoints = 0;
    _hasAnsweredCurrent = false;
    _answerWasCorrect = false;
    _selectedAnswer = null;
    _isSubmittingAnswer = false;
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = AppConstants.questionTimeLimitSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_roundCompleted || _hasAnsweredCurrent) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        _remainingSeconds = 0;
        timer.cancel();
        unawaited(submitAnswer(null));
        return;
      }

      _remainingSeconds--;
      notifyListeners();
    });
  }

  void _completeRound() {
    if (_roundCompleted) {
      return;
    }

    _timer?.cancel();
    _roundCompleted = true;
    final maxAllowedRoundScore = QuizRules.maxPossibleRoundScore(
      questionCount: _questionCountForDifficulty(_selectedDifficulty),
    );
    final normalizedRoundScore = _score.clamp(0, maxAllowedRoundScore).toInt();
    if (normalizedRoundScore != _score) {
      _syncError =
          'Detected an out-of-range score and normalized it before sync.';
      _score = normalizedRoundScore;
    }

    if (_isDailyChallengeActive) {
      _applyDailyChallengeCompletion();
      _isDailyChallengeActive = false;
    }

    _gamesPlayed++;
    _lifetimeScore += _score;
    _bestScore = max(_bestScore, _score);

    for (final question in _questions) {
      if (question.mode != QuizMode.randomMix) {
        _playedModes.add(question.mode);
      }
    }

    _newBadgesThisRound = _evaluateNewBadges();

    _lastRoundResult = QuizResultModel(
      mode: _selectedMode,
      difficulty: _selectedDifficulty,
      score: _score,
      correctAnswers: _correctAnswers,
      wrongAnswers: _wrongAnswers,
      longestStreak: _longestStreak,
      newBadges: _newBadgesThisRound,
    );

    unawaited(_feedbackService.playRoundComplete());
    unawaited(_syncProgressToCloud());
  }

  Set<BadgeType> _evaluateNewBadges() {
    final unlocked = <BadgeType>{};
    final totalAnswered = _correctAnswers + _wrongAnswers;
    final perfectRun = totalAnswered > 0 && _wrongAnswers == 0;

    if (_gamesPlayed >= 1) {
      unlocked.add(BadgeType.firstGame);
    }
    if (perfectRun && _selectedMode == QuizMode.flag) {
      unlocked.add(BadgeType.perfectFlagQuiz);
    }
    if (perfectRun && _selectedMode == QuizMode.capital) {
      unlocked.add(BadgeType.perfectCapitalQuiz);
    }
    if (_longestStreak >= 10) {
      unlocked.add(BadgeType.streakTen);
    }
    if (_simulatedLeaderboardRank <= 10) {
      unlocked.add(BadgeType.topTenLeaderboard);
    }
    if (_gamesPlayed >= 50) {
      unlocked.add(BadgeType.fiftyRounds);
    }
    if (_dailyChallengeStreak >= 7) {
      unlocked.add(BadgeType.dailySevenStreak);
    }

    const requiredModes = {
      QuizMode.flag,
      QuizMode.capital,
      QuizMode.population,
      QuizMode.region,
    };
    if (_playedModes.containsAll(requiredModes)) {
      unlocked.add(BadgeType.allModesPlayed);
    }

    final newBadges = unlocked.difference(_earnedBadges);
    _earnedBadges.addAll(unlocked);
    return newBadges;
  }

  Future<void> _syncProgressToCloud({bool refreshRank = true}) async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    _sanitizePersistentProgressForSync();

    try {
      await _firestoreService.upsertUserProgress(
        user: user,
        gamesPlayed: _gamesPlayed,
        lifetimeScore: _lifetimeScore,
        bestScore: _bestScore,
        dailyChallengeStreak: _dailyChallengeStreak,
        earnedBadgeNames: _earnedBadges.map((badge) => badge.name).toSet(),
        lastDailyChallengeDate: _lastDailyChallengeDate,
      );

      if (refreshRank) {
        await _refreshCurrentUserRank(notify: true);
      }
    } catch (error) {
      _syncError = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _sanitizePersistentProgressForSync() {
    _gamesPlayed = _gamesPlayed.clamp(0, 1000000).toInt();
    _bestScore = _bestScore.clamp(0, 1000).toInt();
    _lifetimeScore = _lifetimeScore.clamp(0, 100000000).toInt();
    if (_lifetimeScore < _bestScore) {
      _lifetimeScore = _bestScore;
    }
    _dailyChallengeStreak = _dailyChallengeStreak.clamp(0, 10000).toInt();
  }

  bool _applyDailyChallengeCompletion() {
    final today = _normalizedDate(DateTime.now().toLocal());
    final lastCompletedDay = _lastDailyChallengeDate;

    if (lastCompletedDay != null && _isSameDay(lastCompletedDay, today)) {
      return false;
    }

    if (lastCompletedDay != null &&
        today.difference(_normalizedDate(lastCompletedDay)).inDays == 1) {
      _dailyChallengeStreak++;
    } else {
      _dailyChallengeStreak = 1;
    }

    _lastDailyChallengeDate = today;
    return true;
  }

  _DailyChallengeConfig _dailyChallengeConfigForToday() {
    final now = DateTime.now().toUtc();
    final dayOfYear = _dayOfYear(now);
    final seed = (now.year * 1000) + dayOfYear;
    const coreModes = [
      QuizMode.flag,
      QuizMode.capital,
      QuizMode.population,
      QuizMode.region,
    ];
    final mode = coreModes[seed % coreModes.length];
    final difficulty = seed % 5 == 0
        ? QuizDifficulty.hard
        : QuizDifficulty.medium;
    return _DailyChallengeConfig(
      mode: mode,
      difficulty: difficulty,
      seed: seed,
    );
  }

  int _dayOfYear(DateTime date) {
    final firstDay = DateTime.utc(date.year, 1, 1);
    return date.difference(firstDay).inDays + 1;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  QuizMode? _parseQuizMode(dynamic raw) {
    final normalized = raw?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final mode in QuizMode.values) {
      if (mode.name == normalized) {
        return mode;
      }
    }
    return null;
  }

  QuizDifficulty? _parseQuizDifficulty(dynamic raw) {
    final normalized = raw?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final difficulty in QuizDifficulty.values) {
      if (difficulty.name == normalized) {
        return difficulty;
      }
    }
    return null;
  }

  QuestionModel? _questionFromServerMap(
    Map<String, dynamic> raw, {
    required bool includeAnswer,
  }) {
    if (raw.isEmpty) {
      return null;
    }

    final mode = _parseQuizMode(raw['mode']) ?? QuizMode.flag;
    final prompt = (raw['prompt'] as String?)?.trim() ?? '';
    final options = (raw['options'] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);

    if (prompt.isEmpty || options.length < 2) {
      return null;
    }

    final visualUrl = (raw['visualUrl'] as String?)?.trim();
    final answer = includeAnswer
        ? (raw['correctAnswer'] as String?)?.trim() ?? ''
        : '';
    final funFact = (raw['funFact'] as String?)?.trim();

    return QuestionModel(
      mode: mode,
      prompt: prompt,
      options: options,
      correctAnswer: answer,
      country: _placeholderCountry(),
      visualUrl: visualUrl == null || visualUrl.isEmpty ? null : visualUrl,
      funFact: funFact == null || funFact.isEmpty ? null : funFact,
    );
  }

  CountryModel _placeholderCountry() {
    return CountryModel(
      nameCommon: 'Unknown',
      flagPng: '',
      capital: const <String>[],
      population: 0,
      region: '',
      subregion: '',
      languages: const <String>[],
    );
  }

  DateTime _dateFromDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return _normalizedDate(DateTime.now().toLocal());
    }

    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final day = int.tryParse(parts[2]) ?? DateTime.now().day;
    return DateTime(year, month, day);
  }

  String _readableError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.toLowerCase().contains('already completed')) {
      return 'Daily challenge already completed today.';
    }
    return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
  }

  Future<void> _refreshCurrentUserRank({required bool notify}) async {
    final user = _authService.currentUser;
    if (user == null) {
      if (_simulatedLeaderboardRank != 999) {
        _simulatedLeaderboardRank = 999;
        if (notify) {
          notifyListeners();
        }
      }
      return;
    }

    try {
      final rank = await _firestoreService.fetchCurrentUserRank(user);
      if (rank != null && rank != _simulatedLeaderboardRank) {
        _simulatedLeaderboardRank = rank;
        if (notify) {
          notifyListeners();
        }
      }
    } catch (_) {
      // Non-blocking UI enhancement. Ignore rank refresh failures.
    }
  }

  void _resetPersistentProgress({required bool notify}) {
    _gamesPlayed = 0;
    _lifetimeScore = 0;
    _bestScore = 0;
    _dailyChallengeStreak = 0;
    _lastDailyChallengeDate = null;
    _simulatedLeaderboardRank = 999;
    _syncError = null;
    _earnedBadges.clear();
    _playedModes.clear();
    _newBadgesThisRound = <BadgeType>{};
    _lastRoundResult = null;
    _dailyChallengeDateKey = null;
    _isDailyChallengeActive = false;
    _isUsingLocalDailyChallengeFallback = false;
    _dailyChallengeNotice = null;
    _pendingDailyNextQuestion = null;

    if (notify) {
      notifyListeners();
    }
  }

  bool _startLocalDailyChallengeFallbackRound() {
    final config = _dailyChallengeConfigForToday();
    final seededGenerator = QuestionGenerator(random: Random(config.seed));
    final started = _startRoundInternal(
      mode: config.mode,
      difficulty: config.difficulty,
      questionGenerator: seededGenerator,
    );
    if (started) {
      _isDailyChallengeActive = true;
      _dailyChallengeDateKey = null;
    }
    return started;
  }

  DateTime _normalizedDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _DailyChallengeConfig {
  const _DailyChallengeConfig({
    required this.mode,
    required this.difficulty,
    required this.seed,
  });

  final QuizMode mode;
  final QuizDifficulty difficulty;
  final int seed;
}
