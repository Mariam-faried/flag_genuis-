import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/badge_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final displayName = authProvider.displayName;
    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'G';
    final accountLabel = authProvider.user?.isAnonymous ?? true
        ? 'Guest Account'
        : (authProvider.user?.email ?? 'Account Linked');
    final level = (provider.lifetimeScore / 500).floor() + 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            children: [
              Center(
                child: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outline),
                  gradient: AppTheme.profileHeroGradient,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppTheme.accentYellow,
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: AppTheme.panel,
                        child: Text(
                          avatarLetter,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.accentBlue.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'Level $level - Explorer',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      accountLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    label: 'Total Pts',
                    value: provider.lifetimeScore.toString(),
                    color: AppTheme.accentYellow,
                  ),
                  _StatCard(
                    label: 'Best',
                    value: provider.bestScore.toString(),
                    color: AppTheme.success,
                  ),
                  _StatCard(
                    label: 'Games',
                    value: provider.gamesPlayed.toString(),
                    color: AppTheme.accentBlue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Badges Collection',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.builder(
                itemCount: badgeCatalog.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  final entry = badgeCatalog.entries.elementAt(index);
                  final earned = provider.earnedBadges.contains(entry.key);
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: earned
                          ? AppTheme.accentYellow.withValues(alpha: 0.12)
                          : AppTheme.panelSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: earned ? AppTheme.accentYellow : AppTheme.outline,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          earned ? Icons.verified : Icons.lock_outline,
                          color:
                              earned ? AppTheme.accentYellow : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

