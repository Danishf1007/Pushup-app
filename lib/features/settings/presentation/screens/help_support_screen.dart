import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Help & Support screen with FAQs and contact info.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Quick Help Section
          _buildSectionHeader('Quick Help'),
          _buildHelpCard(
            icon: Icons.play_circle_outline,
            title: 'Getting Started',
            content:
                'Welcome to PushUp! Here\'s how to get started:\n\n'
                '1. Athletes: Your coach will assign you a training plan. Check your dashboard for today\'s workout.\n\n'
                '2. Coaches: Add athletes using your Coach ID (found in Profile). Create training plans and assign them to athletes.',
          ),
          _buildHelpCard(
            icon: Icons.fitness_center,
            title: 'Logging Workouts',
            content:
                'To log a workout:\n\n'
                '1. Go to your Dashboard\n'
                '2. Tap on the assigned activity\n'
                '3. Complete the workout\n'
                '4. Tap "Log Activity" to record your progress\n\n'
                'Your coach will be notified of your progress!',
          ),
          _buildHelpCard(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            content:
                'Earn achievements by:\n\n'
                '• Completing workout streaks\n'
                '• Hitting push-up milestones\n'
                '• Finishing training plans\n'
                '• Consistent daily activity\n\n'
                'Check the Achievements tab to see your progress!',
          ),
          const SizedBox(height: AppSpacing.lg),

          // FAQ Section
          _buildSectionHeader('Frequently Asked Questions'),
          _buildFaqItem(
            question: 'How do I connect with my coach?',
            answer:
                'Ask your coach for their Coach ID. Go to your Profile and enter the Coach ID to link your accounts.',
          ),
          _buildFaqItem(
            question: 'Can I change my training plan?',
            answer:
                'Training plans are assigned by your coach. Contact your coach if you need modifications.',
          ),
          _buildFaqItem(
            question: 'How are streaks calculated?',
            answer:
                'Streaks count consecutive days with at least one logged activity. Missing a day resets your streak!',
          ),
          _buildFaqItem(
            question: 'Is my data synced across devices?',
            answer:
                'Yes! All your data is stored in the cloud and syncs automatically when you sign in.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Contact Section
          _buildSectionHeader('Contact Us'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'support@pushupapp.com',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'We typically respond within 24-48 hours.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Feedback Button
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback feature coming soon!')),
              );
            },
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Send Feedback'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.bodyLarge),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              answer,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
