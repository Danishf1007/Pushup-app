import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Register screen for new users.
class RegisterScreen extends ConsumerStatefulWidget {
  /// Creates a register screen.
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _coachCodeController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _coachCodeFocusNode = FocusNode();

  UserRole _selectedRole = UserRole.athlete;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _coachCodeController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _coachCodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showErrorSnackBar('Please accept the terms and conditions');
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final coachCode =
        _selectedRole == UserRole.athlete &&
            _coachCodeController.text.trim().isNotEmpty
        ? _coachCodeController.text.trim()
        : null;

    await ref
        .read(authProvider.notifier)
        .signUpWithEmail(
          email: email,
          password: password,
          displayName: name,
          role: _selectedRole,
          coachId: coachCode,
        );
    // Error handling is done via ref.listen in initState
    // Navigation is handled by router redirect
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and show errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        _showErrorSnackBar(next.message);
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: AppSpacing.lg),

                // Role Selection
                _buildRoleSelection(),
                const SizedBox(height: AppSpacing.lg),

                // Name Field
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                  onSubmitted: (_) => _emailFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Email Field
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Password Field
                PasswordTextField(
                  label: 'Password',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hintText: 'Create a strong password',
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                  onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Confirm Password Field
                PasswordTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  hintText: 'Re-enter your password',
                  textInputAction: _selectedRole == UserRole.athlete
                      ? TextInputAction.next
                      : TextInputAction.done,
                  validator: _validateConfirmPassword,
                  onSubmitted: (_) => _selectedRole == UserRole.athlete
                      ? _coachCodeFocusNode.requestFocus()
                      : _handleRegister(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Coach Code Field (only for athletes)
                if (_selectedRole == UserRole.athlete) ...[
                  CustomTextField(
                    label: 'Coach Code (Optional)',
                    controller: _coachCodeController,
                    focusNode: _coachCodeFocusNode,
                    hintText: 'Enter your coach\'s ID',
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRegister(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ask your coach for their ID to link your account',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Terms Checkbox
                _buildTermsCheckbox(),
                const SizedBox(height: AppSpacing.lg),

                // Register Button
                PrimaryButton(
                  text: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: authState is AuthLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Login Link
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: AppTextStyles.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Join PushUp and start your fitness journey',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I am a', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                role: UserRole.athlete,
                icon: Icons.directions_run,
                title: 'Athlete',
                description: 'Track workouts & progress',
                isSelected: _selectedRole == UserRole.athlete,
                onTap: () => setState(() => _selectedRole = UserRole.athlete),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _RoleCard(
                role: UserRole.coach,
                icon: Icons.sports,
                title: 'Coach',
                description: 'Create plans & guide athletes',
                isSelected: _selectedRole == UserRole.coach,
                onTap: () => setState(() => _selectedRole = UserRole.coach),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (value) =>
                setState(() => _acceptedTerms = value ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TertiaryButton(
          text: 'Sign In',
          onPressed: () {
            ref.read(authProvider.notifier).clearError();
            context.push(RoutePaths.login);
          },
        ),
      ],
    );
  }
}

/// Role selection card widget.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
