import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/database_seeder.dart';
import '../../core/widgets/widgets.dart';

/// Developer screen for seeding the database with test data.
class DevSeedScreen extends StatefulWidget {
  const DevSeedScreen({super.key});

  @override
  State<DevSeedScreen> createState() => _DevSeedScreenState();
}

class _DevSeedScreenState extends State<DevSeedScreen> {
  bool _isSeeding = false;
  bool _isClearing = false;
  String? _resultMessage;
  bool? _resultSuccess;

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _resultMessage = null;
    });

    final seeder = DatabaseSeeder();
    final result = await seeder.seedAll();

    setState(() {
      _isSeeding = false;
      _resultMessage = result.toString();
      _resultSuccess = result.success;
    });
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Database?'),
        content: const Text(
          'This will delete ALL data including users, plans, and activity logs. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _resultMessage = null;
    });

    try {
      final seeder = DatabaseSeeder();
      await seeder.clearAllData();
      setState(() {
        _isClearing = false;
        _resultMessage = 'Database cleared successfully';
        _resultSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isClearing = false;
        _resultMessage = 'Error clearing database: $e';
        _resultSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'These tools are for development only. Use with caution!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Seed Database
            Text('Database Seeding', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Populate the database with sample coaches, athletes, training plans, '
              'assignments, and activity logs for testing.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'Seed Database',
              onPressed: _isSeeding ? null : _seedDatabase,
              isLoading: _isSeeding,
            ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.xl),

            // Clear Database
            Text('Clear Database', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Remove ALL data from the database. This cannot be undone.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: _isClearing ? null : _clearDatabase,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: _isClearing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Clear All Data'),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Result message
            if (_resultMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color:
                      (_resultSuccess == true
                              ? AppColors.success
                              : AppColors.error)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: _resultSuccess == true
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _resultSuccess == true ? Icons.check_circle : Icons.error,
                      color: _resultSuccess == true
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Test accounts info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Account Credentials',
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Note: Seeded users are Firestore documents only.\n'
                    'You still need to register via Firebase Auth to login.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
