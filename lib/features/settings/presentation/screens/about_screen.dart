import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// About screen with app information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),

            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // App Name & Version
            Text(
              'PushUp',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Version 1.0.0',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // App Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your Personal Push-Up Training Companion',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'PushUp helps coaches and athletes track their push-up training progress. '
                      'Create personalized training plans, log workouts, earn achievements, '
                      'and reach your fitness goals together.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Features
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureItem(
                      Icons.assignment_outlined,
                      'Custom Training Plans',
                    ),
                    _buildFeatureItem(Icons.trending_up, 'Progress Tracking'),
                    _buildFeatureItem(
                      Icons.emoji_events_outlined,
                      'Achievements & Streaks',
                    ),
                    _buildFeatureItem(
                      Icons.people_outline,
                      'Coach-Athlete Connection',
                    ),
                    _buildFeatureItem(
                      Icons.notifications_outlined,
                      'Workout Reminders',
                    ),
                    _buildFeatureItem(
                      Icons.chat_bubble_outline,
                      'In-App Messaging',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Credits
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      'Developed with ❤️',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Mobile ITT632 Project',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '© 2026 PushUp App',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Legal Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _showLegalDialog(context, 'Privacy Policy'),
                  child: const Text('Privacy Policy'),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () =>
                      _showLegalDialog(context, 'Terms of Service'),
                  child: const Text('Terms of Service'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            title == 'Privacy Policy'
                ? 'Privacy Policy\n\n'
                      'We respect your privacy and are committed to protecting your personal data. '
                      'This app collects only the data necessary to provide the service:\n\n'
                      '• Account information (email, name)\n'
                      '• Workout logs and progress\n'
                      '• Coach-athlete connections\n\n'
                      'Your data is stored securely and never shared with third parties without your consent.'
                : 'Terms of Service\n\n'
                      'By using PushUp, you agree to:\n\n'
                      '• Use the app for personal fitness tracking only\n'
                      '• Not misuse or attempt to hack the service\n'
                      '• Provide accurate information\n'
                      '• Respect other users\n\n'
                      'We reserve the right to suspend accounts that violate these terms.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
