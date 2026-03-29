import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/device.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'device/device_timer_widgets.dart';

class DeviceTile extends StatelessWidget {
  final Device device;
  final bool isAutoMode;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTimerTap;
  final VoidCallback? onCancelTimer;
  final VoidCallback? onDelete;

  const DeviceTile({
    super.key,
    required this.device,
    this.isAutoMode = false,
    this.onToggle,
    this.onTimerTap,
    this.onCancelTimer,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final iconData = _getDeviceIcon(device.type);
    final isActive = device.isOn;
    final hasTimer = device.hasActiveTimer;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.06)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryGreen.withValues(alpha: 0.15)
                      : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: isActive ? AppColors.primaryGreen : theme.textTheme.bodyMedium?.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive ? l10n.t('on') : l10n.t('off'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isActive ? AppColors.primaryGreen : null,
                      ),
                    ),
                  ],
                ),
              ),
              // Timer button (only in manual mode)
              if (!isAutoMode) ...[
                DeviceTimerButton(
                  hasTimer: hasTimer,
                  onTap: hasTimer ? onCancelTimer : onTimerTap,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
              ],
              IgnorePointer(
                ignoring: isAutoMode,
                child: Opacity(
                  opacity: isAutoMode ? 0.4 : 1.0,
                  child: Switch.adaptive(
                    value: device.isOn,
                    onChanged: isAutoMode ? null : (val) => onToggle?.call(val),
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  color: AppColors.alertHigh.withValues(alpha: 0.6),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          // Timer countdown display
          if (hasTimer && !isAutoMode) ...[
            const SizedBox(height: 10),
            DeviceTimerCountdown(
              device: device,
              onCancel: onCancelTimer,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'pump':
        return LucideIcons.droplets;
      case 'mist':
        return LucideIcons.cloudFog;
      case 'fan':
        return LucideIcons.wind;
      case 'light':
        return LucideIcons.sun;
      case 'valve':
        return LucideIcons.power;
      default:
        return LucideIcons.cpu;
    }
  }
}
