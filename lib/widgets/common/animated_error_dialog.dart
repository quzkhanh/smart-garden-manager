import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class AnimatedErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AnimatedErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
  });

  static void show(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AnimatedErrorDialog(
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon Ring
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.alertHigh.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: AppColors.alertHigh,
                    size: 36,
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shake(hz: 3, duration: 1000.ms, curve: Curves.easeInOut)
                      .then(delay: 2000.ms),
                ),
              ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 28),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertHigh,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Đã hiểu",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
