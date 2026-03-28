import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/language_switcher.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _countdown = 58;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus the first OTP input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startCountdown() {
    _countdown = 58;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
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
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
                padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language switcher
                    Align(
                      alignment: Alignment.topRight,
                      child: const LanguageSwitcher(),
                    ),
                    const SizedBox(height: 40),

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
                    ),
                    const SizedBox(height: 20),

                    Text(
                      l10n.t('app_name'),
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('login'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP card
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
                        children: [
                          Text(
                            l10n.t('enter_otp'),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.t('otp_sent_to')} ${auth.phoneNumber}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),

                          // OTP inputs
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 44,
                                height: 52,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  onChanged: (val) => _onOtpChanged(index, val),
                                ),
                              );
                            }),
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 24),

                          // Verify button
                          AppButton(
                            text: l10n.t('verify'),
                            isLoading: auth.isLoading,
                            onPressed: _otp.length == 6
                                ? () => auth.verifyOtp(_otp)
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Countdown
                          Text(
                            _countdown > 0
                                ? '${l10n.t('resend_after')} ${_countdown}s'
                                : '',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (_countdown == 0)
                            TextButton(
                              onPressed: () {
                                _startCountdown();
                                // Simulate resend
                              },
                              child: Text(
                                l10n.t('send_otp'),
                                style: TextStyle(color: AppColors.primaryGreen),
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 24),

                    // QR Login link
                    TextButton.icon(
                      onPressed: () {
                        auth.goBackToPhone();
                        auth.startQrLogin();
                      },
                      icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                      label: Text(l10n.t('login_qr')),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
