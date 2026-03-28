import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/language_switcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

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
                right: isWide ? (screenWidth - 440) / 2 : 24,
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
                            Icons.eco_rounded,
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
                            decoration: InputDecoration(
                              hintText: l10n.t('phone_hint'),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            text: l10n.t('send_otp'),
                            isLoading: auth.isLoading,
                            onPressed: () {
                              final phone = _phoneController.text.trim();
                              if (phone.isNotEmpty) {
                                auth.sendOtp(phone);
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

                    const SizedBox(height: 24),

                    // QR Login link
                    TextButton.icon(
                      onPressed: () {
                        auth.startQrLogin();
                      },
                      icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                      label: Text(l10n.t('login_qr')),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.textTheme.bodyMedium?.color,
                      ),
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
