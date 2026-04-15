import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../screens/explorer_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/mode_select_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/result_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/summary_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/daily_challenge_service.dart';
import '../services/feedback_service.dart';
import '../services/firestore_service.dart';
import 'app_routes.dart';

class FlagGeniusApp extends StatelessWidget {
  FlagGeniusApp({super.key});

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FeedbackService _feedbackService = FeedbackService();
  final DailyChallengeService _dailyChallengeService = DailyChallengeService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        Provider<FirestoreService>.value(value: _firestoreService),
        Provider<FeedbackService>.value(value: _feedbackService),
        Provider<DailyChallengeService>.value(value: _dailyChallengeService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: _authService,
            firestoreService: _firestoreService,
          ),
        ),
        ChangeNotifierProvider<QuizProvider>(
          create: (_) => QuizProvider(
            apiService: _apiService,
            authService: _authService,
            firestoreService: _firestoreService,
            feedbackService: _feedbackService,
            dailyChallengeService: _dailyChallengeService,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flag Genius',
        theme: AppTheme.premiumDark(),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.modeSelect: (_) => const ModeSelectScreen(),
          AppRoutes.quiz: (_) => const QuizScreen(),
          AppRoutes.result: (_) => const ResultScreen(),
          AppRoutes.summary: (_) => const SummaryScreen(),
          AppRoutes.leaderboard: (_) => const LeaderboardScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.settings: (_) => const SettingsScreen(),
          AppRoutes.explorer: (_) => const ExplorerScreen(),
        },
      ),
    );
  }
}
