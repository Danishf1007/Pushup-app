import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/achievement_entity.dart';
import '../providers/achievement_provider.dart';

/// Screen displaying all achievements and progress.
class AchievementsScreen extends ConsumerWidget {
  /// Creates an achievements screen.
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final achievementsAsync = ref.watch(achievementsProvider(currentUser.id));
    final countsAsync = ref.watch(achievementCountsProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(achievementsProvider(currentUser.id));
              ref.invalidate(achievementCountsProvider(currentUser.id));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(achievementsProvider(currentUser.id));
          ref.invalidate(achievementCountsProvider(currentUser.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverview(countsAsync),
              const SizedBox(height: AppSpacing.xl),
              _buildAchievementsList(achievementsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(AsyncValue<AchievementCounts> countsAsync) {
    return countsAsync.when(
      data: (counts) => BaseCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning,
                        AppColors.warning.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${counts.unlocked} / ${counts.total}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Achievements Unlocked',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: counts.percentage / 100,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                  strokeWidth: 6,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: counts.percentage / 100,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${counts.percentage.toInt()}% Complete',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      loading: () => const BaseCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(height: 100, child: Center(child: LoadingIndicator())),
      ),
      error: (e, _) => BaseCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Error loading achievements',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsList(
    AsyncValue<List<AchievementEntity>> achievementsAsync,
  ) {
    return achievementsAsync.when(
      data: (achievements) {
        // Group by tier
        final bronze = achievements
            .where((a) => a.tier == AchievementTier.bronze)
            .toList();
        final silver = achievements
            .where((a) => a.tier == AchievementTier.silver)
            .toList();
        final gold = achievements
            .where((a) => a.tier == AchievementTier.gold)
            .toList();
        final platinum = achievements
            .where((a) => a.tier == AchievementTier.platinum)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTierSection(
              'Bronze',
              bronze,
              _tierColor(AchievementTier.bronze),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTierSection(
              'Silver',
              silver,
              _tierColor(AchievementTier.silver),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTierSection('Gold', gold, _tierColor(AchievementTier.gold)),
            const SizedBox(height: AppSpacing.lg),
            _buildTierSection(
              'Platinum',
              platinum,
              _tierColor(AchievementTier.platinum),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: LoadingIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error loading achievements: $e',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildTierSection(
    String title,
    List<AchievementEntity> achievements,
    Color color,
  ) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(title, style: AppTextStyles.titleMedium),
            const Spacer(),
            Text(
              '$unlockedCount / ${achievements.length}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...achievements.map(
          (achievement) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _AchievementCard(achievement: achievement),
          ),
        ),
      ],
    );
  }

  Color _tierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFF7DF9FF);
    }
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementEntity achievement;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? _tierColor.withValues(alpha: 0.2)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Icon(
              _getIcon(),
              color: isUnlocked
                  ? _tierColor
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isUnlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  achievement.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: achievement.progressPercent / 100,
                            backgroundColor: AppColors.surface,
                            valueColor: AlwaysStoppedAnimation(
                              _tierColor.withValues(alpha: 0.5),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${achievement.progress}/${achievement.requirement}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isUnlocked) Icon(Icons.check_circle, color: _tierColor, size: 24),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (achievement.iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'timer':
        return Icons.timer;
      case 'star':
        return Icons.star;
      case 'assignment_turned_in':
        return Icons.assignment_turned_in;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  Color get _tierColor {
    switch (achievement.tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFF7DF9FF);
    }
  }
}
