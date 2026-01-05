import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Forgot Password screen for password reset.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Creates a forgot password screen.
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(email);

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
    // Error handling is done via ref.listen in initState
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

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and show errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        _showErrorSnackBar(next.message);
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: _emailSent
              ? _buildSuccessContent()
              : _buildFormContent(isLoading),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Check Your Email',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'We\'ve sent a password reset link to:',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _emailController.text.trim(),
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Check your inbox and spam folder. '
                'The link will expire in 1 hour.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          text: 'Back to Login',
          icon: Icons.login,
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: const Text('Try a different email'),
        ),
      ],
    );
  }

  Widget _buildFormContent(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          Center(
            child: Text(
              'Forgot Password?',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Enter your email address and we\'ll send you\na link to reset your password.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Email Field
          CustomTextField(
            label: 'Email Address',
            controller: _emailController,
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleResetPassword(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Reset Button
          PrimaryButton(
            text: 'Send Reset Link',
            icon: Icons.send,
            onPressed: isLoading ? null : _handleResetPassword,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Back to Login
          Center(
            child: TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Login'),
            ),
          ),
        ],
      ),
    );
  }
}
