import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/leaderboard_entry_model.dart';
import '../models/user_progress_model.dart';

class FirestoreProgressSyncResult {
  const FirestoreProgressSyncResult({
    required this.usedSecureWrite,
    required this.usedClientFallback,
  });

  final bool usedSecureWrite;
  final bool usedClientFallback;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _leaderboard =>
      _firestore.collection('leaderboard');

  Future<void> ensureUserDocument(User user) async {
    final userRef = _users.doc(user.uid);
    final leaderboardRef = _leaderboard.doc(user.uid);
    final snapshot = await userRef.get();
    final leaderboardSnapshot = await leaderboardRef.get();
    final rawData = snapshot.data();
    final rawLeaderboardData = leaderboardSnapshot.data();

    final identityFields = <String, dynamic>{
      'displayName': _displayNameFor(user),
      'email': user.email,
      'photoUrl': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final existingGamesPlayed =
        ((rawData?['gamesPlayed'] as num?)?.toInt() ?? 0)
            .clamp(0, 1000000)
            .toInt();
    final existingBestScore = ((rawData?['bestScore'] as num?)?.toInt() ?? 0)
        .clamp(0, 100000000)
        .toInt();
    final existingLeaderboardGamesPlayed =
        ((rawLeaderboardData?['gamesPlayed'] as num?)?.toInt() ?? 0)
            .clamp(0, 1000000)
            .toInt();
    final existingLeaderboardBestScore =
        ((rawLeaderboardData?['bestScore'] as num?)?.toInt() ?? 0)
            .clamp(0, 1000)
            .toInt();
    final canonicalGamesPlayed = max(
      existingGamesPlayed,
      existingLeaderboardGamesPlayed,
    );
    final canonicalBestScore = max(
      existingBestScore,
      existingLeaderboardBestScore,
    );
    final rawLifetimeScore = ((rawData?['lifetimeScore'] as num?)?.toInt() ?? 0)
        .clamp(0, 100000000)
        .toInt();
    final existingLifetimeScore = rawLifetimeScore < canonicalBestScore
        ? canonicalBestScore
        : rawLifetimeScore;
    final existingDailyChallengeStreak =
        ((rawData?['dailyChallengeStreak'] as num?)?.toInt() ?? 0)
            .clamp(0, 10000)
            .toInt();
    final existingEarnedBadges =
        (rawData?['earnedBadges'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList()
          ..sort();
    final existingLastDailyChallengeAt = rawData?['lastDailyChallengeAt'];
    final existingCreatedAt = rawData?['createdAt'];
    final createdAtValue = existingCreatedAt is Timestamp
        ? existingCreatedAt
        : FieldValue.serverTimestamp();

    if (snapshot.exists) {
      await userRef.set({
        ...identityFields,
        'gamesPlayed': canonicalGamesPlayed,
        'lifetimeScore': existingLifetimeScore,
        'bestScore': canonicalBestScore,
        'dailyChallengeStreak': existingDailyChallengeStreak,
        'earnedBadges': existingEarnedBadges,
        'lastDailyChallengeAt': existingLastDailyChallengeAt,
        'createdAt': createdAtValue,
      }, SetOptions(merge: true));
    } else {
      await userRef.set({
        ...identityFields,
        'gamesPlayed': canonicalGamesPlayed,
        'lifetimeScore': existingLifetimeScore,
        'bestScore': canonicalBestScore,
        'dailyChallengeStreak': 0,
        'earnedBadges': <String>[],
        'lastDailyChallengeAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserProgressModel?> fetchUserProgress(User user) async {
    final snapshot = await _users.doc(user.uid).get();
    final rawData = snapshot.data();
    if (!snapshot.exists || rawData == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(rawData);
    final timestamp = data['lastDailyChallengeAt'];
    if (timestamp is Timestamp) {
      data['lastDailyChallengeAt'] = timestamp.toDate();
    }

    return UserProgressModel.fromFirestore(data);
  }

  Future<FirestoreProgressSyncResult> upsertUserProgress({
    required User user,
    required int gamesPlayed,
    required int lifetimeScore,
    required int bestScore,
    required int dailyChallengeStreak,
    required Set<String> earnedBadgeNames,
    DateTime? lastDailyChallengeDate,
    int? latestRoundScore,
    bool secureWriteEnabled = true,
    bool requireSecureWrite = false,
  }) async {
    if (secureWriteEnabled) {
      final secureWriteApplied = await _trySecureProgressUpsert(
        user: user,
        gamesPlayed: gamesPlayed,
        lifetimeScore: lifetimeScore,
        bestScore: bestScore,
        dailyChallengeStreak: dailyChallengeStreak,
        earnedBadgeNames: earnedBadgeNames,
        lastDailyChallengeDate: lastDailyChallengeDate,
        latestRoundScore: latestRoundScore,
      );
      if (secureWriteApplied) {
        return const FirestoreProgressSyncResult(
          usedSecureWrite: true,
          usedClientFallback: false,
        );
      }

      if (requireSecureWrite) {
        throw Exception(
          'Secure cloud sync is required but the secure endpoint is unavailable.',
        );
      }
    }

    await _upsertUserProgressDirect(
      user: user,
      gamesPlayed: gamesPlayed,
      lifetimeScore: lifetimeScore,
      bestScore: bestScore,
      dailyChallengeStreak: dailyChallengeStreak,
      earnedBadgeNames: earnedBadgeNames,
      lastDailyChallengeDate: lastDailyChallengeDate,
    );

    return FirestoreProgressSyncResult(
      usedSecureWrite: false,
      usedClientFallback: true,
    );
  }

  Future<bool> _trySecureProgressUpsert({
    required User user,
    required int gamesPlayed,
    required int lifetimeScore,
    required int bestScore,
    required int dailyChallengeStreak,
    required Set<String> earnedBadgeNames,
    required DateTime? lastDailyChallengeDate,
    required int? latestRoundScore,
  }) async {
    final callable = _functions.httpsCallable('syncUserProgressSecure');
    final payload = <String, dynamic>{
      'gamesPlayed': gamesPlayed,
      'lifetimeScore': lifetimeScore,
      'bestScore': bestScore,
      'dailyChallengeStreak': dailyChallengeStreak,
      'earnedBadgeNames': earnedBadgeNames.toList()..sort(),
      'lastDailyChallengeDateIso': lastDailyChallengeDate
          ?.toUtc()
          .toIso8601String(),
      'latestRoundScore': latestRoundScore,
      'clientUpdatedAtIso': DateTime.now().toUtc().toIso8601String(),
      'clientDisplayName': _displayNameFor(user),
    };

    try {
      await callable.call(payload);
      return true;
    } on FirebaseFunctionsException catch (error) {
      final recoverable =
          error.code == 'unavailable' ||
          error.code == 'not-found' ||
          error.code == 'unimplemented' ||
          error.code == 'deadline-exceeded';
      if (recoverable) {
        return false;
      }
      throw Exception(error.message ?? 'Secure cloud sync failed.');
    } catch (_) {
      return false;
    }
  }

  Future<void> _upsertUserProgressDirect({
    required User user,
    required int gamesPlayed,
    required int lifetimeScore,
    required int bestScore,
    required int dailyChallengeStreak,
    required Set<String> earnedBadgeNames,
    required DateTime? lastDailyChallengeDate,
  }) async {
    final displayName = _displayNameFor(user);
    final userRef = _users.doc(user.uid);
    final leaderboardRef = _leaderboard.doc(user.uid);
    final sortedBadges = earnedBadgeNames.toList()..sort();
    final userSnapshot = await userRef.get();
    final leaderboardSnapshot = await leaderboardRef.get();
    final userRawData = userSnapshot.data();
    final leaderboardRawData = leaderboardSnapshot.data();

    final existingLeaderboardGamesPlayed =
        ((leaderboardRawData?['gamesPlayed'] as num?)?.toInt() ?? 0)
            .clamp(0, 1000000)
            .toInt();
    final existingLeaderboardBestScore =
        ((leaderboardRawData?['bestScore'] as num?)?.toInt() ?? 0)
            .clamp(0, 1000)
            .toInt();

    final safeGamesPlayed = max(
      gamesPlayed,
      existingLeaderboardGamesPlayed,
    ).clamp(0, 1000000).toInt();
    final safeBestScore = max(
      bestScore.clamp(0, 1000).toInt(),
      existingLeaderboardBestScore,
    );
    final safeLifetimeScore = max(
      lifetimeScore,
      safeBestScore,
    ).clamp(0, 100000000).toInt();

    final existingCreatedAt = userRawData?['createdAt'];
    final createdAtValue = existingCreatedAt is Timestamp
        ? existingCreatedAt
        : FieldValue.serverTimestamp();

    await userRef.set({
      'displayName': displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'gamesPlayed': safeGamesPlayed,
      'lifetimeScore': safeLifetimeScore,
      'bestScore': safeBestScore,
      'dailyChallengeStreak': dailyChallengeStreak,
      'earnedBadges': sortedBadges,
      'lastDailyChallengeAt': lastDailyChallengeDate,
      'createdAt': createdAtValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await leaderboardRef.set({
        'displayName': displayName,
        'photoUrl': user.photoURL,
        'bestScore': safeBestScore,
        'gamesPlayed': safeGamesPlayed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
      // Leaderboard writes can be blocked in hardened rules.
    }
  }

  Stream<List<LeaderboardEntryModel>> watchTopLeaderboard({int limit = 50}) {
    return _leaderboard
        .orderBy('bestScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .map(_entryFromSnapshot)
              .where((entry) {
                return entry.bestScore > 0;
              })
              .toList(growable: false);
          return _sortLeaderboard(entries);
        });
  }

  Stream<Set<String>> watchFriendUids(User user) {
    return _users.doc(user.uid).snapshots().map((snapshot) {
      return _friendUidsFromData(snapshot.data(), selfUid: user.uid);
    });
  }

  Stream<List<LeaderboardEntryModel>> watchFriendsLeaderboard({
    required User user,
    int limit = 50,
  }) {
    return watchFriendUids(user).asyncExpand((friendUids) {
      final allowedUids = <String>{user.uid, ...friendUids};
      if (allowedUids.isEmpty) {
        return Stream<List<LeaderboardEntryModel>>.value(
          const <LeaderboardEntryModel>[],
        );
      }

      return _leaderboard.snapshots().map((snapshot) {
        final entries = snapshot.docs
            .map(_entryFromSnapshot)
            .where((entry) {
              return entry.bestScore > 0 && allowedUids.contains(entry.uid);
            })
            .toList(growable: false);

        final sorted = _sortLeaderboard(entries);
        if (sorted.length <= limit) {
          return sorted;
        }
        return sorted.sublist(0, limit);
      });
    });
  }

  Future<int?> fetchCurrentUserRank(User user) async {
    final snapshot = await _leaderboard.doc(user.uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    final bestScore = (data['bestScore'] as num?)?.toInt() ?? 0;
    if (bestScore <= 0) {
      return null;
    }

    final higherScoresSnapshot = await _leaderboard
        .where('bestScore', isGreaterThan: bestScore)
        .count()
        .get();

    final usersWithSameScore = await _leaderboard
        .where('bestScore', isEqualTo: bestScore)
        .get();

    final tieBreakerUsers = usersWithSameScore.docs.where((doc) {
      return doc.id.compareTo(user.uid) < 0;
    }).length;

    final higherScores = higherScoresSnapshot.count ?? 0;
    return higherScores + tieBreakerUsers + 1;
  }

  LeaderboardEntryModel _entryFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final rawUpdatedAt = data['updatedAt'];
    final updatedAt = switch (rawUpdatedAt) {
      Timestamp() => rawUpdatedAt.toDate(),
      DateTime() => rawUpdatedAt,
      _ => null,
    };
    return LeaderboardEntryModel(
      uid: snapshot.id,
      displayName: _readDisplayName(data),
      bestScore: (data['bestScore'] as num?)?.toInt() ?? 0,
      gamesPlayed: (data['gamesPlayed'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
      updatedAt: updatedAt,
    );
  }

  String _displayNameFor(User user) {
    if (user.displayName?.trim().isNotEmpty ?? false) {
      return user.displayName!.trim();
    }

    if (user.email?.trim().isNotEmpty ?? false) {
      final email = user.email!.trim();
      return email.split('@').first;
    }

    return 'Guest ${user.uid.substring(0, 6)}';
  }

  String _readDisplayName(Map<String, dynamic> data) {
    final displayName = (data['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return 'Guest';
  }

  Set<String> _friendUidsFromData(
    Map<String, dynamic>? data, {
    required String selfUid,
  }) {
    if (data == null) {
      return <String>{};
    }

    final raw = data['friendUids'] ?? data['friends'];
    if (raw is! List<dynamic>) {
      return <String>{};
    }

    return raw
        .whereType<String>()
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty && uid != selfUid)
        .toSet();
  }

  List<LeaderboardEntryModel> _sortLeaderboard(
    List<LeaderboardEntryModel> entries,
  ) {
    final sorted = List<LeaderboardEntryModel>.from(entries);
    sorted.sort((a, b) {
      final scoreCompare = b.bestScore.compareTo(a.bestScore);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.uid.compareTo(b.uid);
    });
    return sorted;
  }
}
