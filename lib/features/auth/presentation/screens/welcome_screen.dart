import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// Welcome screen - entry point for new users.
///
/// Displays app branding and options to login or register.
class WelcomeScreen extends StatelessWidget {
  /// Creates a welcome screen.
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App Logo and Branding
              _buildBranding(),

              const Spacer(flex: 3),

              // Features Highlight
              _buildFeatures(),

              const Spacer(flex: 2),

              // Action Buttons
              _buildButtons(context),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 60,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // App Name
        Text(
          AppConstants.appName,
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Tagline
        Text(
          'Train Smarter. Achieve More.',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.assignment_outlined,
          title: 'Personalized Training',
          description: 'Custom plans tailored to your goals',
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureItem(
          icon: Icons.trending_up,
          title: 'Track Progress',
          description: 'Visualize your fitness journey',
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureItem(
          icon: Icons.people_outline,
          title: 'Coach Connection',
          description: 'Get guidance from expert coaches',
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // Sign Up Button
        PrimaryButton(
          text: 'Sign Up',
          icon: Icons.person_add_outlined,
          onPressed: () => context.push(RoutePaths.register),
        ),
        const SizedBox(height: AppSpacing.md),

        // Login Button
        SecondaryButton(
          text: 'Login',
          icon: Icons.login,
          onPressed: () => context.push(RoutePaths.login),
        ),
        const SizedBox(height: AppSpacing.md),

        // Dev Tools Button (visible for testing)
        TextButton(
          onPressed: () {
            context.push(RoutePaths.devSeed);
          },
          child: Text(
            '🛠️ Developer Tools',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Version
        GestureDetector(
          onLongPress: () => context.push(RoutePaths.devSeed),
          child: Text(
            'v1.0.0',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Feature item widget for welcome screen.
class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
