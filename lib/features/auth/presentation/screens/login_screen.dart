import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Login screen for existing users.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a login screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref
        .read(authProvider.notifier)
        .signInWithEmail(email: email, password: password);
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
                const SizedBox(height: AppSpacing.lg),

                // Header
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),

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
                  hintText: 'Enter your password',
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TertiaryButton(
                    text: 'Forgot Password?',
                    onPressed: () => context.push(RoutePaths.forgotPassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Login Button
                PrimaryButton(
                  text: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: authState is AuthLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Or Divider
                _buildDivider(),
                const SizedBox(height: AppSpacing.lg),

                // Social Login Buttons
                _buildSocialButtons(),
                const SizedBox(height: AppSpacing.xl),

                // Register Link
                _buildRegisterLink(),
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
          'Welcome Back!',
          style: AppTextStyles.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in to continue your fitness journey',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _SocialButton(
          icon: Icons.g_mobiledata,
          text: 'Continue with Google',
          onPressed: () {
            // TODO: Implement Google Sign In
          },
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TertiaryButton(
          text: 'Sign Up',
          onPressed: () {
            ref.read(authProvider.notifier).clearError();
            context.push(RoutePaths.register);
          },
        ),
      ],
    );
  }
}

/// Social login button widget.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeightLarge,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              text,
              style: AppTextStyles.buttonLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
