import 'badge_model.dart';

class UserProgressModel {
  UserProgressModel({
    required this.gamesPlayed,
    required this.lifetimeScore,
    required this.bestScore,
    required this.dailyChallengeStreak,
    required this.earnedBadges,
    this.lastDailyChallengeDate,
  });

  final int gamesPlayed;
  final int lifetimeScore;
  final int bestScore;
  final int dailyChallengeStreak;
  final Set<BadgeType> earnedBadges;
  final DateTime? lastDailyChallengeDate;

  factory UserProgressModel.fromFirestore(Map<String, dynamic> json) {
    final badgeNames = (json['earnedBadges'] as List<dynamic>? ?? const [])
        .whereType<String>();

    final earnedBadges = <BadgeType>{
      for (final badgeName in badgeNames)
        ...BadgeType.values.where((badge) => badge.name == badgeName),
    };

    final lastDailyChallengeRaw = json['lastDailyChallengeAt'];
    DateTime? lastDailyChallengeDate;
    if (lastDailyChallengeRaw is DateTime) {
      lastDailyChallengeDate = lastDailyChallengeRaw;
    }

    return UserProgressModel(
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      lifetimeScore: (json['lifetimeScore'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      dailyChallengeStreak:
          (json['dailyChallengeStreak'] as num?)?.toInt() ?? 0,
      earnedBadges: earnedBadges,
      lastDailyChallengeDate: lastDailyChallengeDate,
    );
  }
}
