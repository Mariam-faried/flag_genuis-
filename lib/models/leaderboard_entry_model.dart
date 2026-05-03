class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.uid,
    required this.displayName,
    required this.bestScore,
    required this.gamesPlayed,
    this.photoUrl,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final int bestScore;
  final int gamesPlayed;
  final String? photoUrl;
  final DateTime? updatedAt;
}
