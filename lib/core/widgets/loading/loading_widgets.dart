import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Loading overlay widget.
///
/// Displays a full-screen loading overlay.
class LoadingOverlay extends StatelessWidget {
  /// Creates a loading overlay.
  const LoadingOverlay({super.key, this.message});

  /// Optional loading message.
  final String? message;

  /// Shows loading overlay.
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      builder: (context) => LoadingOverlay(message: message),
    );
  }

  /// Hides loading overlay.
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading indicator widget.
class LoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
  });

  /// Indicator size.
  final double size;

  /// Indicator color.
  final Color? color;

  /// Stroke width.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
      ),
    );
  }
}

/// Full page loading widget.
class LoadingPage extends StatelessWidget {
  /// Creates a loading page.
  const LoadingPage({super.key, this.message});

  /// Optional loading message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicator(size: 48),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder.
class ShimmerLoading extends StatefulWidget {
  /// Creates a shimmer loading widget.
  const ShimmerLoading({super.key, required this.child, this.isLoading = true});

  /// Child widget to show when not loading.
  final Widget child;

  /// Whether to show loading state.
  final bool isLoading;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Placeholder box for shimmer loading.
class ShimmerBox extends StatelessWidget {
  /// Creates a shimmer box.
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  /// Box width.
  final double? width;

  /// Box height.
  final double height;

  /// Border radius.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSpacing.radiusSm,
        ),
      ),
    );
  }
}
