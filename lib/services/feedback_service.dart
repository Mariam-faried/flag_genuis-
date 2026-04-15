import 'dart:async';

import 'package:flutter/services.dart';

import '../core/storage/local_prefs.dart';

class FeedbackService {
  FeedbackService({LocalPrefs? prefs}) : _prefs = prefs ?? LocalPrefs() {
    unawaited(refreshSettings());
  }

  final LocalPrefs _prefs;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> refreshSettings() async {
    _soundEnabled = await _prefs.isSoundEnabled();
    _vibrationEnabled = await _prefs.isVibrationEnabled();
    _musicEnabled = await _prefs.isMusicEnabled();
  }

  Future<void> playTap() async {
    if (!_soundEnabled) {
      return;
    }
    await _safe(() => SystemSound.play(SystemSoundType.click));
  }

  Future<void> playCorrect() async {
    await playTap();
    await successHaptic();
  }

  Future<void> playWrong() async {
    if (_soundEnabled) {
      await _safe(() => SystemSound.play(SystemSoundType.alert));
    }
    await errorHaptic();
  }

  Future<void> playRoundComplete() async {
    await playTap();
    await _safe(() => Future<void>.delayed(const Duration(milliseconds: 70)));
    await playTap();
    await successHaptic();
  }

  Future<void> selectionHaptic() async {
    if (!_vibrationEnabled) {
      return;
    }
    await _safe(HapticFeedback.selectionClick);
  }

  Future<void> successHaptic() async {
    if (!_vibrationEnabled) {
      return;
    }
    await _safe(HapticFeedback.mediumImpact);
  }

  Future<void> errorHaptic() async {
    if (!_vibrationEnabled) {
      return;
    }
    await _safe(HapticFeedback.heavyImpact);
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Best-effort UX enhancement; ignore platform-specific failures.
    }
  }
}
