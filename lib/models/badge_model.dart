enum BadgeType {
  firstGame,
  perfectFlagQuiz,
  perfectCapitalQuiz,
  streakTen,
  topTenLeaderboard,
  fiftyRounds,
  dailySevenStreak,
  allModesPlayed,
}

class BadgeDefinition {
  const BadgeDefinition({required this.title, required this.description});

  final String title;
  final String description;
}

const Map<BadgeType, BadgeDefinition> badgeCatalog = {
  BadgeType.firstGame: BadgeDefinition(
    title: 'World Explorer',
    description: 'Play your first game.',
  ),
  BadgeType.perfectFlagQuiz: BadgeDefinition(
    title: 'Flag Master',
    description: 'Score 100% in Flag Quiz.',
  ),
  BadgeType.perfectCapitalQuiz: BadgeDefinition(
    title: 'Capital King',
    description: 'Score 100% in Capital Quiz.',
  ),
  BadgeType.streakTen: BadgeDefinition(
    title: 'On Fire',
    description: 'Reach a 10-answer streak.',
  ),
  BadgeType.topTenLeaderboard: BadgeDefinition(
    title: 'Top 10',
    description: 'Reach top 10 on global leaderboard.',
  ),
  BadgeType.fiftyRounds: BadgeDefinition(
    title: 'Geography Nerd',
    description: 'Play 50 rounds.',
  ),
  BadgeType.dailySevenStreak: BadgeDefinition(
    title: 'Daily Champion',
    description: 'Finish daily challenge 7 days in a row.',
  ),
  BadgeType.allModesPlayed: BadgeDefinition(
    title: 'Mode Master',
    description: 'Play all four core quiz modes.',
  ),
};
