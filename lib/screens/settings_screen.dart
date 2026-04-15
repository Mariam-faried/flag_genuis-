import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/storage/local_prefs.dart';
import '../core/theme/app_theme.dart';
import '../models/question_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/feedback_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalPrefs _prefs = LocalPrefs();
  bool _loading = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _musicEnabled = true;
  QuizDifficulty _defaultDifficulty = QuizDifficulty.medium;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storedDifficulty = await _prefs.getDefaultDifficulty();
    final mappedDifficulty = QuizDifficulty.values.firstWhere(
      (item) => item.name == storedDifficulty,
      orElse: () => QuizDifficulty.medium,
    );

    _soundEnabled = await _prefs.isSoundEnabled();
    _vibrationEnabled = await _prefs.isVibrationEnabled();
    _musicEnabled = await _prefs.isMusicEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _defaultDifficulty = mappedDifficulty;
      _loading = false;
    });
  }

  Future<void> _saveDifficulty(QuizDifficulty difficulty) async {
    setState(() {
      _defaultDifficulty = difficulty;
    });
    await _prefs.setDefaultDifficulty(difficulty.name);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Sound & Feedback',
                children: [
                  _SwitchRow(
                    icon: Icons.campaign_outlined,
                    label: 'Sound Effects',
                    value: _soundEnabled,
                    onChanged: (value) async {
                      final feedbackService = context.read<FeedbackService>();
                      setState(() {
                        _soundEnabled = value;
                      });
                      await _prefs.setSoundEnabled(value);
                      await feedbackService.refreshSettings();
                      if (value) {
                        unawaited(feedbackService.playTap());
                      }
                    },
                  ),
                  _SwitchRow(
                    icon: Icons.vibration,
                    label: 'Vibration',
                    value: _vibrationEnabled,
                    onChanged: (value) async {
                      final feedbackService = context.read<FeedbackService>();
                      setState(() {
                        _vibrationEnabled = value;
                      });
                      await _prefs.setVibrationEnabled(value);
                      await feedbackService.refreshSettings();
                      if (value) {
                        unawaited(feedbackService.selectionHaptic());
                      }
                    },
                  ),
                  _SwitchRow(
                    icon: Icons.music_note_outlined,
                    label: 'Background Music',
                    value: _musicEnabled,
                    onChanged: (value) async {
                      final feedbackService = context.read<FeedbackService>();
                      setState(() {
                        _musicEnabled = value;
                      });
                      await _prefs.setMusicEnabled(value);
                      await feedbackService.refreshSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Game',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Default Difficulty',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: QuizDifficulty.values.map((difficulty) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Text(difficulty.label),
                                  selected: _defaultDifficulty == difficulty,
                                  onSelected: (_) =>
                                      _saveDifficulty(difficulty),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: authProvider.isBusy
                    ? null
                    : () async {
                        final auth = context.read<AuthProvider>();
                        final quizProvider = context.read<QuizProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        final signedOut = await auth.signOut();
                        if (!mounted) {
                          return;
                        }
                        if (!signedOut) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ??
                                    'Could not logout. Please try again.',
                              ),
                            ),
                          );
                          return;
                        }

                        quizProvider.clearCloudBackedProgress();

                        navigator.pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (_) => false,
                        );
                      },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(letterSpacing: 1),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
