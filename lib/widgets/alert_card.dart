import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = _getSeverityConfig(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: alert.isRead
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06))
                    : config.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, color: config.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.areaName,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.t(config.labelKey),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: config.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alert.message,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(alert.time, l10n),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _SeverityConfig _getSeverityConfig(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return _SeverityConfig(
          icon: Icons.error_outline_rounded,
          color: AppColors.alertHigh,
          labelKey: 'high',
        );
      case AlertSeverity.medium:
        return _SeverityConfig(
          icon: Icons.warning_amber_rounded,
          color: AppColors.alertMedium,
          labelKey: 'medium',
        );
      case AlertSeverity.low:
        return _SeverityConfig(
          icon: Icons.info_outline_rounded,
          color: AppColors.alertLow,
          labelKey: 'low',
        );
    }
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${l10n.t('minutes_ago')}';
    } else if (diff.inHours < 24) {
      return '${l10n.t('about')} ${diff.inHours} ${l10n.t('hours_ago')}';
    } else {
      return '${l10n.t('about')} ${diff.inDays} ${l10n.t('days_ago')}';
    }
  }
}

class _SeverityConfig {
  final IconData icon;
  final Color color;
  final String labelKey;

  _SeverityConfig({
    required this.icon,
    required this.color,
    required this.labelKey,
  });
}
