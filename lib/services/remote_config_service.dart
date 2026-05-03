import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../core/constants/app_constants.dart';

class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;
  bool _analyticsEnabled = true;
  bool _secureLeaderboardWriteEnabled = false;
  bool _secureLeaderboardWriteRequired = false;
  int _questionTimeLimitSeconds = AppConstants.questionTimeLimitSeconds;
  int _maxClientRoundScore = 1000;

  static const String _analyticsEnabledKey = 'analytics_enabled';
  static const String _secureWriteEnabledKey = 'leaderboard_secure_write_enabled';
  static const String _secureWriteRequiredKey =
      'leaderboard_secure_write_required';
  static const String _questionTimeLimitKey = 'question_time_limit_seconds';
  static const String _maxClientRoundScoreKey = 'max_client_round_score';

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) {
      return;
    }

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: forceRefresh
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(<String, dynamic>{
        _analyticsEnabledKey: true,
        _secureWriteEnabledKey: false,
        _secureWriteRequiredKey: false,
        _questionTimeLimitKey: AppConstants.questionTimeLimitSeconds,
        _maxClientRoundScoreKey: 1000,
      });
      await _remoteConfig.fetchAndActivate();

      _analyticsEnabled = _remoteConfig.getBool(_analyticsEnabledKey);
      _secureLeaderboardWriteEnabled =
          _remoteConfig.getBool(_secureWriteEnabledKey);
      _secureLeaderboardWriteRequired =
          _remoteConfig.getBool(_secureWriteRequiredKey);
      _questionTimeLimitSeconds = _remoteConfig
          .getInt(_questionTimeLimitKey)
          .clamp(6, 20)
          .toInt();
      _maxClientRoundScore = _remoteConfig
          .getInt(_maxClientRoundScoreKey)
          .clamp(100, 1000)
          .toInt();
    } catch (_) {
      // Keep defaults when Remote Config is unavailable.
    } finally {
      _initialized = true;
    }
  }

  bool get analyticsEnabled => _analyticsEnabled;
  bool get secureLeaderboardWriteEnabled => _secureLeaderboardWriteEnabled;
  bool get secureLeaderboardWriteRequired => _secureLeaderboardWriteRequired;
  int get questionTimeLimitSeconds => _questionTimeLimitSeconds;
  int get maxClientRoundScore => _maxClientRoundScore;
}
