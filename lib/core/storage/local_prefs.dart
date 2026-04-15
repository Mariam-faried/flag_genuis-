import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  static const String _onboardingSeenKey = 'onboarding_seen';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _defaultDifficultyKey = 'default_difficulty';

  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> setOnboardingSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, value);
  }

  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
  }

  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, value);
  }

  Future<bool> isMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicEnabledKey) ?? true;
  }

  Future<void> setMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, value);
  }

  Future<String?> getDefaultDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultDifficultyKey);
  }

  Future<void> setDefaultDifficulty(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultDifficultyKey, value);
  }
}
