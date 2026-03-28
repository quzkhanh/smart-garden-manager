import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/device_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_skeleton.dart';
import '../../widgets/common/empty_state.dart';
import '../../models/logged_device.dart';
import 'qr_scanner_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final deviceProvider = context.watch<DeviceProvider>();

    return Scaffold(
      body: SafeArea(
        child: deviceProvider.isLoading
            ? _buildLoadingState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Text(
                      l10n.t('logged_devices'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      '${deviceProvider.deviceCount} ${l10n.t('device_count')}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  // QR Scan button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QrScannerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(l10n.t('scan_qr_login')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primaryGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  Expanded(
                    child: deviceProvider.devices.isEmpty
                        ? EmptyState(
                            icon: Icons.devices_rounded,
                            title: l10n.t('no_devices'),
                          )
                        : RefreshIndicator(
                            onRefresh: deviceProvider.refreshDevices,
                            color: AppColors.primaryGreen,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: deviceProvider.devices.length,
                              itemBuilder: (context, index) {
                                final device = deviceProvider.devices[index];
                                return _DeviceCard(
                                  device: device,
                                  onLogout: () =>
                                      deviceProvider.logoutDevice(device.id),
                                  onRename: () => _showRenameDialog(
                                    context,
                                    device,
                                    deviceProvider,
                                    l10n,
                                  ),
                                ).animate().fadeIn(
                                      delay: Duration(
                                          milliseconds: 200 + index * 80),
                                      duration: 400.ms,
                                    );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    LoggedDevice device,
    DeviceProvider provider,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController(text: device.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.t('rename_device')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.t('enter_device_name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameDevice(device.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.t('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingSkeleton(width: 200, height: 32),
          SizedBox(height: 8),
          LoadingSkeleton(width: 80, height: 16),
          SizedBox(height: 24),
          CardSkeleton(),
          SizedBox(height: 8),
          CardSkeleton(),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final LoggedDevice device;
  final VoidCallback onLogout;
  final VoidCallback onRename;

  const _DeviceCard({
    required this.device,
    required this.onLogout,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getPlatformIcon(device.platform),
                  size: 26,
                  color: device.isCurrentDevice
                      ? AppColors.primaryGreen
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device name on its own line
                    Text(
                      device.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Badges row: current device + online status
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (device.isCurrentDevice)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.t('current_device'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: device.isOnline
                                    ? AppColors.online
                                    : AppColors.offline,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              device.isOnline
                                  ? l10n.t('online')
                                  : l10n.t('offline_status'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: device.isOnline
                                    ? AppColors.online
                                    : AppColors.offline,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t(device.platform),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.t('last_active')}: ${_formatLastActive(device.lastActive, l10n)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Actions (only for non-current devices)
          if (!device.isCurrentDevice) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(l10n.t('logout_device')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.alertHigh,
                    textStyle: theme.textTheme.labelMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'mobile':
        return Icons.phone_iphone_rounded;
      case 'web':
        return Icons.computer_rounded;
      case 'tablet':
        return Icons.tablet_mac_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  String _formatLastActive(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${l10n.t('minutes_ago')}';
    } else if (diff.inHours < 24) {
      return '${l10n.t('about')} ${diff.inHours} ${l10n.t('hours_ago')}';
    } else {
      return '${diff.inDays} ${l10n.t('days_ago')}';
    }
  }
}
