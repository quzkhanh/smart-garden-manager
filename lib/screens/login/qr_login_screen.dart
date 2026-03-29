import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_switcher.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key});

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _countdown = 120;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 120;
    _isExpired = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
            _isExpired = true;
            // Auto-cleanup expired session from Firestore
            final auth = context.read<AuthProvider>();
            if (auth.qrSessionId.isNotEmpty) {
              FirebaseFirestore.instance
                  .collection('qr_sessions')
                  .doc(auth.qrSessionId)
                  .update({'status': 'expired'}).catchError((_) {});
            }
          }
        });
      }
    });
  }

  void _regenerateQr() {
    final auth = context.read<AuthProvider>();
    auth.cancelQrLogin();
    auth.startQrLogin();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          auth.cancelQrLogin();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
            onPressed: () {
              auth.cancelQrLogin();
              // Router will handle navigation back to /login because state changes to unauthenticated
            },
          ),
        ),
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
                  constraints:
                      BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Language switcher
                      Align(
                        alignment: Alignment.topRight,
                        child: const LanguageSwitcher(),
                      ),
                      const SizedBox(height: 20),

                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.3),
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
                      l10n.t('login_qr'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // QR Card
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
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.t('qr_scan_instruction'),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // QR Code with expiry overlay
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // QR Code
                              AnimatedOpacity(
                                opacity: _isExpired ? 0.15 : 1.0,
                                duration: const Duration(milliseconds: 400),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: QrImageView(
                                    data: auth.qrSessionId.isEmpty
                                        ? 'generating...'
                                        : auth.qrSessionId,
                                    version: QrVersions.auto,
                                    size: 180,
                                    gapless: true,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape:
                                          QrDataModuleShape.square,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                              ),

                              // Expired overlay
                              if (_isExpired)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_off_rounded,
                                      size: 48,
                                      color: AppColors.alertHigh,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.t('qr_expired'),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: AppColors.alertHigh,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _regenerateQr,
                                      icon: const Icon(Icons.refresh_rounded,
                                          size: 18),
                                      label: Text(l10n.t('regenerate_qr')),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          )
                              .animate()
                              .scale(duration: 500.ms, curve: Curves.easeOut),
                          const SizedBox(height: 20),

                          // Status indicator
                          if (!_isExpired) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.t('waiting_approval'),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Countdown timer
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: (_countdown < 30
                                        ? AppColors.alertHigh
                                        : AppColors.primaryGreen)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: _countdown < 30
                                        ? AppColors.alertHigh
                                        : AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${l10n.t('qr_expires')} ${_formatCountdown()}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: _countdown < 30
                                          ? AppColors.alertHigh
                                          : AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 24),

                    // Phone login link
                    TextButton.icon(
                      onPressed: () {
                        auth.cancelQrLogin();
                      },
                      icon: const Icon(Icons.phone_outlined, size: 20),
                      label: Text(l10n.t('login_phone')),
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
      ),
    );
  }
}
