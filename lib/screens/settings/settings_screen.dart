import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/garden_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final garden = context.watch<GardenProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Text(
              l10n.t('settings'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // User info card
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('user'),
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              auth.phoneNumber.isNotEmpty ? auth.phoneNumber : '091 234 5678',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  // UID Display
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('user_id'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              auth.uid ?? 'Unknown',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: auth.uid ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.t('copied'))),
                          );
                        },
                        icon: const Icon(LucideIcons.copy, size: 20),
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                  
                  // Area IDs Display
                  if (garden.areas.isNotEmpty) ...garden.areas.map((area) => Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mã vườn (${area.name})', // Custom text, no l10n string guaranteed
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  area.id,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: area.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.t('copied'))),
                              );
                            },
                            icon: const Icon(LucideIcons.copy, size: 20),
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  )),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // Admin Section
            if (auth.isAdmin) ...[
              Text(
                'QUẢN TRỊ VIÊN',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 1.1,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: _ThemeOption(
                  icon: LucideIcons.users,
                  label: 'Quản lý thành viên',
                  isSelected: false,
                  onTap: () => context.push('/access-management'),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: 24),
            ],

            // Language section
            Text(
              l10n.t('language'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                letterSpacing: 1.1,
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _LanguageOption(
                    flag: '🇻🇳',
                    label: l10n.t('vietnamese'),
                    isSelected: localeProvider.isVietnamese,
                    onTap: () => localeProvider.setLocale(const Locale('vi')),
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withValues(alpha: 0.05)),
                  _LanguageOption(
                    flag: '🇺🇸',
                    label: l10n.t('english'),
                    isSelected: !localeProvider.isVietnamese,
                    onTap: () => localeProvider.setLocale(const Locale('en')),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // Theme section
            Text(
              l10n.t('theme'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                letterSpacing: 1.1,
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ThemeOption(
                    icon: LucideIcons.sun,
                    label: l10n.t('light_mode'),
                    isSelected: settings.themeMode == ThemeMode.light,
                    onTap: () => settings.setThemeMode(ThemeMode.light),
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withValues(alpha: 0.05)),
                  _ThemeOption(
                    icon: LucideIcons.moon,
                    label: l10n.t('dark_mode'),
                    isSelected: settings.themeMode == ThemeMode.dark,
                    onTap: () => settings.setThemeMode(ThemeMode.dark),
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor.withValues(alpha: 0.05)),
                  _ThemeOption(
                    icon: LucideIcons.monitor,
                    label: l10n.t('system_mode'),
                    isSelected: settings.themeMode == ThemeMode.system,
                    onTap: () => settings.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // Help & Guide
            Text(
              l10n.t('tutorial'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                letterSpacing: 1.1,
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: _ThemeOption(
                icon: LucideIcons.helpCircle,
                label: l10n.t('tutorial'),
                isSelected: false,
                onTap: () => context.push('/onboarding'),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // Logout button
            ElevatedButton(
              onPressed: () => _showLogoutDialog(context, auth, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.logOut),
                  const SizedBox(width: 8),
                  Text(
                    l10n.t('logout'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.t('logout'),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.t('logout_confirm'),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  auth.logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertHigh,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.t('confirm')),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.t('cancel')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryGreen : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                color: AppColors.primaryGreen,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primaryGreen : null),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryGreen : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                color: AppColors.primaryGreen,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
