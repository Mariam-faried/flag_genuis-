import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/leaderboard_entry_model.dart';
import '../models/user_progress_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    final canonicalBestScore = max(existingBestScore, existingLeaderboardBestScore);
    final rawLifetimeScore = ((rawData?['lifetimeScore'] as num?)?.toInt() ?? 0)
        .clamp(0, 100000000)
        .toInt();
    final existingLifetimeScore = rawLifetimeScore < canonicalBestScore
        ? canonicalBestScore
        : rawLifetimeScore;
    final leaderboardBestScore = canonicalBestScore.clamp(0, 1000).toInt();
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

    await leaderboardRef.set({
      'displayName': _displayNameFor(user),
      'photoUrl': user.photoURL,
      'bestScore': leaderboardBestScore,
      'gamesPlayed': canonicalGamesPlayed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Future<void> upsertUserProgress({
    required User user,
    required int gamesPlayed,
    required int lifetimeScore,
    required int bestScore,
    required int dailyChallengeStreak,
    required Set<String> earnedBadgeNames,
    DateTime? lastDailyChallengeDate,
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

    final safeGamesPlayed =
        max(gamesPlayed, existingLeaderboardGamesPlayed).clamp(0, 1000000).toInt();
    final safeBestScore = max(
      bestScore.clamp(0, 1000).toInt(),
      existingLeaderboardBestScore,
    );
    final safeLifetimeScore = max(lifetimeScore, safeBestScore)
        .clamp(0, 100000000)
        .toInt();

    final existingCreatedAt = userRawData?['createdAt'];
    final createdAtValue = existingCreatedAt is Timestamp
        ? existingCreatedAt
        : FieldValue.serverTimestamp();

    final batch = _firestore.batch();

    batch.set(userRef, {
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

    batch.set(leaderboardRef, {
      'displayName': displayName,
      'photoUrl': user.photoURL,
      'bestScore': safeBestScore,
      'gamesPlayed': safeGamesPlayed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<List<LeaderboardEntryModel>> watchTopLeaderboard({int limit = 50}) {
    return _leaderboard
        .orderBy('bestScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(_entryFromSnapshot)
              .where((entry) {
                return entry.bestScore > 0;
              })
              .toList(growable: false);
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
    return LeaderboardEntryModel(
      uid: snapshot.id,
      displayName: _readDisplayName(data),
      bestScore: (data['bestScore'] as num?)?.toInt() ?? 0,
      gamesPlayed: (data['gamesPlayed'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
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
}
