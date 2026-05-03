import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;
  bool _collectionEnabled = true;

  bool get isCollectionEnabled => _collectionEnabled;

  Future<void> setCollectionEnabled(bool enabled) async {
    _collectionEnabled = enabled;
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {
      // Analytics should never block the user experience.
    }
  }

  Future<void> setUserContext({required User? user}) async {
    if (!_collectionEnabled) {
      return;
    }

    try {
      await _analytics.setUserId(id: user?.uid);
      if (user == null) {
        return;
      }
      await _analytics.setUserProperty(
        name: 'is_anonymous',
        value: user.isAnonymous ? '1' : '0',
      );
      await _analytics.setUserProperty(
        name: 'auth_provider',
        value: user.isAnonymous ? 'anonymous' : 'authenticated',
      );
    } catch (_) {
      // Analytics should never block the user experience.
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    if (!_collectionEnabled) {
      return;
    }

    final safeName = _sanitizeEventName(name);
    if (safeName.isEmpty) {
      return;
    }

    final safeParameters = _sanitizeParameters(parameters);
    try {
      await _analytics.logEvent(name: safeName, parameters: safeParameters);
    } catch (_) {
      // Analytics should never block the user experience.
    }
  }

  String _sanitizeEventName(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_]'),
      '_',
    );
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.length <= 40) {
      return normalized;
    }
    return normalized.substring(0, 40);
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> raw) {
    final sanitized = <String, Object>{};

    for (final entry in raw.entries) {
      if (entry.value == null) {
        continue;
      }

      final key = entry.key.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9_]'),
        '_',
      );
      if (key.isEmpty || key.length > 40) {
        continue;
      }

      final value = _sanitizeValue(entry.value!);
      if (value == null) {
        continue;
      }

      sanitized[key] = value;
    }

    return sanitized;
  }

  Object? _sanitizeValue(Object value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed.length <= 100 ? trimmed : trimmed.substring(0, 100);
    }
    if (value is int || value is double) {
      return value;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    return null;
  }
}
