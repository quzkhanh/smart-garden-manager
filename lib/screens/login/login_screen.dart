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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isEmailMode = true; // Default to Email mode to save SMS quota
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

                    // Input card
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_isEmailMode),
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
                        child: _isEmailMode
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('email'),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(LucideIcons.mail, size: 20),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.t('password'),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                  if (_isRegister) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Xác nhận mật khẩu',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(LucideIcons.checkCircle, size: 20),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          context.push('/forgot-password');
                                        },
                                        child: Text(
                                          'Quên mật khẩu?',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _isRegister,
                                          onChanged: (val) {
                                            setState(() {
                                              _isRegister = val ?? false;
                                              // Clear confirm box when toggling
                                              _confirmPasswordController.clear();
                                            });
                                          },
                                          activeColor: AppColors.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isRegister = !_isRegister;
                                            _confirmPasswordController.clear();
                                          });
                                        },
                                        child: Text(
                                          l10n.t('register'),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  AppButton(
                                    text: _isRegister ? l10n.t('register') : l10n.t('login'),
                                    isLoading: auth.isLoading,
                                    onPressed: () async {
                                      final email = _emailController.text.trim();
                                      final password = _passwordController.text.trim();
                                      final confirm = _confirmPasswordController.text.trim();
                                      
                                      if (email.isEmpty || password.isEmpty) return;

                                      if (_isRegister && password != confirm) {
                                        AnimatedErrorDialog.show(
                                          context, 
                                          title: "Lỗi đăng ký", 
                                          message: "Mật khẩu xác nhận không khớp. Vui lòng kiểm tra lại.",
                                        );
                                        return;
                                      }

                                      await auth.loginWithEmail(email, password, isRegister: _isRegister);
                                      if (auth.lastError.isNotEmpty && context.mounted) {
                                        AnimatedErrorDialog.show(
                                          context, 
                                          title: "Lỗi đăng nhập", 
                                          message: auth.lastError,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              )
                            : Column(
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
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          delay: 400.ms,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 32),

                    // Navigation to Alternate Login, QR, or Tutorial
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEmailMode = !_isEmailMode;
                            });
                          },
                          icon: Icon(_isEmailMode ? LucideIcons.phone : LucideIcons.mail, size: 18),
                          label: Text(_isEmailMode ? l10n.t('login_phone') : l10n.t('login_email')),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
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
