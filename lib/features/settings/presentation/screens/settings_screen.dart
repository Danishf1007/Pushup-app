import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Settings screen with app preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _soundEffects = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive notifications about workouts and updates',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _showSettingSaved();
            },
          ),
          _buildSwitchTile(
            icon: Icons.alarm_outlined,
            title: 'Workout Reminders',
            subtitle: 'Daily reminders to complete your workout',
            value: _workoutReminders,
            onChanged: (value) {
              setState(() => _workoutReminders = value);
              _showSettingSaved();
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // App Preferences Section
          _buildSectionHeader('App Preferences'),
          _buildSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Sound Effects',
            subtitle: 'Play sounds for achievements and actions',
            value: _soundEffects,
            onChanged: (value) {
              setState(() => _soundEffects = value);
              _showSettingSaved();
            },
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Use dark theme (Coming Soon)',
            value: _darkMode,
            onChanged: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dark mode coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Data & Privacy Section
          _buildSectionHeader('Data & Privacy'),
          _buildActionTile(
            icon: Icons.download_outlined,
            title: 'Export My Data',
            subtitle: 'Download all your workout data',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.delete_outline,
            title: 'Clear Activity Cache',
            subtitle: 'Remove cached workout data',
            onTap: () {
              _showClearCacheDialog();
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Version Info
          Center(
            child: Text(
              'PushUp App v1.0.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showSettingSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Setting saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove locally cached data. Your workout history will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
