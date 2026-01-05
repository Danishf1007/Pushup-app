import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/achievement_entity.dart';

/// Dialog that celebrates newly unlocked achievements.
class AchievementCelebrationDialog extends StatelessWidget {
  /// Creates the celebration dialog.
  const AchievementCelebrationDialog({required this.achievements, super.key});

  /// The newly unlocked achievements.
  final List<AchievementEntity> achievements;

  /// Shows the celebration dialog.
  static Future<void> show(
    BuildContext context,
    List<AchievementEntity> achievements,
  ) async {
    if (achievements.isEmpty) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          AchievementCelebrationDialog(achievements: achievements),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child:
          Container(
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.warning, Color(0xFFFFA726)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.lg),
                          topRight: Radius.circular(AppSpacing.lg),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                                Icons.emoji_events,
                                color: AppColors.white,
                                size: 48,
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: 600.ms,
                              )
                              .shimmer(duration: 1000.ms),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            achievements.length == 1
                                ? 'Achievement Unlocked!'
                                : '${achievements.length} Achievements Unlocked!',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Achievement list
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          ...achievements.map(
                            (achievement) =>
                                _AchievementItem(achievement: achievement),
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: 'Awesome!',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  const _AchievementItem({required this.achievement});

  final AchievementEntity achievement;

  Color get _tierColor {
    switch (achievement.tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return AppColors.warning;
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  IconData get _icon {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: _tierColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_tierColor, _tierColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Icon(_icon, color: AppColors.white, size: 24),
              )
              .animate(delay: 200.ms)
              .shimmer(duration: 800.ms)
              .then()
              .shake(hz: 2, duration: 400.ms),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievement.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _tierColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    achievement.tier.name.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _tierColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.3, end: 0);
  }
}
