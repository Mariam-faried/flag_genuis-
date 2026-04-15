import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/leaderboard_entry_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final isSignedIn = authProvider.isSignedIn;

    if (!isSignedIn || currentUser == null) {
      return _buildAuthRequiredScaffold(context);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: StreamBuilder<List<LeaderboardEntryModel>>(
            stream: firestoreService.watchTopLeaderboard(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final permissionDenied = _isPermissionDenied(snapshot.error!);
                final errorText = permissionDenied
                    ? 'Leaderboard access is denied for this session.\nSign in again and make sure Firestore rules are deployed.'
                    : 'Could not load leaderboard.\n${snapshot.error}';

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(errorText, textAlign: TextAlign.center),
                        if (permissionDenied) ...[
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.login,
                                (_) => false,
                              );
                            },
                            child: const Text('Go to login'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final leaderboard =
                  snapshot.data ?? const <LeaderboardEntryModel>[];
              if (leaderboard.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No leaderboard entries yet.\nPlay a round to become the first listed player.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  const _LeaderboardHeader(),
                  const SizedBox(height: 12),
                  _TopThreeCard(entries: leaderboard),
                  const SizedBox(height: 12),
                  _CurrentUserRankCard(
                    firestoreService: firestoreService,
                    user: currentUser,
                  ),
                  const SizedBox(height: 10),
                  ...List<Widget>.generate(leaderboard.length, (index) {
                    final entry = leaderboard[index];
                    final isCurrentUser = currentUser.uid == entry.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? AppTheme.accentYellow.withValues(alpha: 0.12)
                            : AppTheme.panelSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCurrentUser
                              ? AppTheme.accentYellow.withValues(alpha: 0.45)
                              : AppTheme.outline,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.panel,
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: AppTheme.textPrimary),
                          ),
                        ),
                        title: Text(
                          isCurrentUser
                              ? '${entry.displayName}  <- You'
                              : entry.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: isCurrentUser
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                        ),
                        subtitle: Text(
                          'Games: ${entry.gamesPlayed}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          entry.bestScore.toString(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.accentYellow,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isPermissionDenied(Object error) {
    return error
        .toString()
        .toLowerCase()
        .contains('permission-denied');
  }

  Widget _buildAuthRequiredScaffold(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 44,
                    color: AppTheme.accentYellow,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to view the global leaderboard.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (_) => false,
                      );
                    },
                    child: const Text('Go to login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.leaderboardHeroGradient,
        border: Border.all(color: AppTheme.leaderboardHeroBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Ranks',
          style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _TabPill(label: 'All Time', isActive: true)),
              SizedBox(width: 8),
              Expanded(child: _TabPill(label: 'This Week', isActive: false)),
              SizedBox(width: 8),
              Expanded(child: _TabPill(label: 'Friends', isActive: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isActive ? AppTheme.accentYellow : AppTheme.panelSoft,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isActive ? AppTheme.onGold : AppTheme.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CurrentUserRankCard extends StatelessWidget {
  const _CurrentUserRankCard({
    required this.firestoreService,
    required this.user,
  });

  final FirestoreService firestoreService;
  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: firestoreService.fetchCurrentUserRank(user),
      builder: (context, snapshot) {
        final rank = snapshot.data;
        if (rank != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            context.read<QuizProvider>().setSimulatedLeaderboardRank(rank);
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.panelSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outline),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.panel,
              child: Text('You'),
            ),
            title: Text(
              'Your Position',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              rank == null
                  ? 'Play more rounds to earn your global rank.'
                  : 'Rank: $rank',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: snapshot.connectionState == ConnectionState.waiting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _TopThreeCard extends StatelessWidget {
  const _TopThreeCard({required this.entries});

  final List<LeaderboardEntryModel> entries;

  @override
  Widget build(BuildContext context) {
    final topThree = <LeaderboardEntryModel?>[
      entries.length > 1 ? entries[1] : null,
      entries.isNotEmpty ? entries[0] : null,
      entries.length > 2 ? entries[2] : null,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Text(
            'Top 3 Players',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PodiumTile(rank: 2, entry: topThree[0]),
              _PodiumTile(rank: 1, entry: topThree[1]),
              _PodiumTile(rank: 3, entry: topThree[2]),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.rank, required this.name});

  final int rank;
  final String name;

  @override
  Widget build(BuildContext context) {
    final frameColor = switch (rank) {
      1 => AppTheme.medalGold,
      2 => AppTheme.medalSilver,
      _ => AppTheme.medalBronze,
    };

    return CircleAvatar(
      radius: 24,
      backgroundColor: frameColor,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.panel,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntryModel? entry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (rank) {
      1 => Icons.looks_one_rounded,
      2 => Icons.looks_two_rounded,
      _ => Icons.looks_3_rounded,
    };
    final color = switch (rank) {
      1 => AppTheme.medalGold,
      2 => AppTheme.medalSilver,
      _ => AppTheme.medalBronze,
    };

    return Column(
      children: [
        if (rank == 1)
          const Icon(
            Icons.workspace_premium_rounded,
            size: 22,
            color: AppTheme.accentYellow,
          ),
        _AvatarBadge(rank: rank, name: entry?.displayName ?? '?'),
        const SizedBox(height: 6),
        Text(
          entry?.displayName ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          entry?.bestScore.toString() ?? '0',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Icon(icon, size: 22, color: color),
      ],
    );
  }
}
