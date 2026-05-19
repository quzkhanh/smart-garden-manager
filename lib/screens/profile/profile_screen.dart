import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final userId = auth.uid ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('profile')),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 24),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header / Avatar
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGreen, Color(0xFF81C784)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  auth.phoneNumber.isNotEmpty ? auth.phoneNumber : 'No Phone Number',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Smart Garden User',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // User ID Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vpn_key_rounded, size: 20, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      l10n.t('user_id'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          userId,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: userId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.t('copied')),
                              behavior: SnackBarBehavior.floating,
                              width: 200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        color: AppColors.primaryGreen,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                   'Cung cấp mã này cho bạn của bạn để kết nối ESP32.',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 16),
          
          // Settings Section
          Text(
            l10n.t('settings'),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (auth.isAdmin) ...[
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Quản lý thành viên',
                    subtitle: 'Thêm/Xóa người dùng',
                    onTap: () => context.push('/access-management'),
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: theme.dividerColor.withValues(alpha: 0.05),
                  ),
                ],
                _buildMenuItem(
                  icon: Icons.language_rounded,
                  title: l10n.t('language'),
                  subtitle: 'Tiếng Việt',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
                _buildMenuItem(
                  icon: Icons.dark_mode_rounded,
                  title: l10n.t('appearance'),
                  subtitle: isDark ? 'Tối' : 'Sáng',
                  onTap: () {},
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),
          
          // Logout Button
          ElevatedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.t('logout')),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                auth.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
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
                const Icon(Icons.logout_rounded),
                const SizedBox(width: 8),
                Text(
                  l10n.t('logout'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
          
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Smart Garden v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
