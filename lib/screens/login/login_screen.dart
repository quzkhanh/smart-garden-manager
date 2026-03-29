import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/animated_error_dialog.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_toggle_indicator.dart';
import '../../providers/settings_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.lastError.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: AppColors.alertHigh),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).t('error')),
              ],
            ),
            content: Text(auth.lastError),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppColors.primaryGreen)),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.loginBackgroundGradientDark
              : AppColors.loginBackgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language switcher at the very top
              Positioned(
                top: 12,
                left: isWide ? (screenWidth - 440) / 2 : 16,
                child: const ThemeToggleIndicator()
                    .animate()
                    .fadeIn(duration: 400.ms),
              ),
              // Language switcher at the very top right
              Positioned(
                top: 12,
                right: isWide ? (screenWidth - 440) / 2 : 16,
                child: const LanguageSwitcher()
                    .animate()
                    .fadeIn(duration: 400.ms),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 56),

                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.sprout,
                            color: Colors.white,
                            size: 42,
                          ),
                        ).animate().scale(
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          l10n.t('app_name'),
                          style: theme.textTheme.headlineLarge,
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                        const SizedBox(height: 4),
                        Text(
                          l10n.t('login'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                        const SizedBox(height: 40),

                    // Phone input card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('phone_number'),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              hintText: null,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🇻🇳', style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Text('+84', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 8),
                                    Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.3)),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            text: l10n.t('send_otp'),
                            isLoading: auth.isLoading,
                            onPressed: () async {
                              final phone = _phoneController.text.trim();
                              if (phone.isNotEmpty) {
                                await auth.sendOtp(phone);
                                if (auth.lastError.isNotEmpty && context.mounted) {
                                  AnimatedErrorDialog.show(
                                    context, 
                                    title: "Lỗi đăng nhập", 
                                    message: auth.lastError,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          delay: 400.ms,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 32),

                    // Navigation to QR or Tutorial
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            auth.startQrLogin();
                          },
                          icon: const Icon(LucideIcons.scanQrCode, size: 18),
                          label: Text(l10n.t('login_qr')),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            context.push('/onboarding');
                          },
                          icon: const Icon(LucideIcons.helpCircle, size: 18),
                          label: Text(l10n.t('tutorial')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
