import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';

/// Profile screen for viewing and editing user profile.
class ProfileScreen extends ConsumerStatefulWidget {
  /// Creates a profile screen.
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.displayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(displayName: _nameController.text.trim());

    setState(() {
      _isSaving = false;
      if (success) {
        _isEditing = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _handleChangePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final success = await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: currentPasswordController.text,
            newPassword: newPasswordController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Password changed successfully!'
                  : 'Failed to change password. Please check your current password.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: AppSpacing.xl),
              _buildProfileInfo(user),
              const SizedBox(height: AppSpacing.xl),
              _buildAccountSection(user),
              const SizedBox(height: AppSpacing.xl),
              _buildDangerZone(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        // Avatar
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo upload coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Name (editable)
        if (_isEditing)
          SizedBox(
            width: 250,
            child: CustomTextField(
              label: 'Name',
              controller: _nameController,
              hintText: 'Your name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
          )
        else
          Text(
            user.displayName,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),

        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: user.isCoach
                ? AppColors.info.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
          ),
          child: Text(
            user.isCoach ? 'Coach' : 'Athlete',
            style: AppTextStyles.labelMedium.copyWith(
              color: user.isCoach ? AppColors.info : AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Edit mode buttons
        if (_isEditing) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SecondaryButton(
                text: 'Cancel',
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _nameController.text = user.displayName;
                  });
                },
              ),
              const SizedBox(width: AppSpacing.md),
              PrimaryButton(
                text: 'Save',
                onPressed: _isSaving ? null : _saveProfile,
                isLoading: _isSaving,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProfileInfo(user) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: user.email));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copied to clipboard')),
              );
            },
          ),
          const Divider(height: AppSpacing.lg),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: _formatDate(user.createdAt),
          ),

          if (user.isCoach) ...[
            const Divider(height: AppSpacing.lg),
            _buildInfoRow(
              icon: Icons.tag,
              label: 'Coach ID',
              value: user.id.substring(0, 8).toUpperCase(),
              onCopy: () {
                Clipboard.setData(ClipboardData(text: user.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coach ID copied! Share with athletes.'),
                  ),
                );
              },
            ),
          ],

          if (user.isAthlete && user.coachId != null) ...[
            const Divider(height: AppSpacing.lg),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Linked to Coach',
              value: user.coachId!.substring(0, 8).toUpperCase(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: onCopy,
            color: AppColors.textSecondary,
          ),
      ],
    );
  }

  Widget _buildAccountSection(user) {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            subtitle: const Text('Send password reset email'),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: EdgeInsets.zero,
            onTap: _handleChangePassword,
          ),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              context.push(RoutePaths.notificationSettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return BaseCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.warning),
            title: const Text('Sign Out'),
            subtitle: const Text('Sign out of your account'),
            contentPadding: EdgeInsets.zero,
            onTap: _handleSignOut,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Permanently delete your account'),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Account deletion coming soon. Contact support.',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
