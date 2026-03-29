import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class SensorBar extends StatelessWidget {
  final String type;
  final double value;
  final String unit;
  final double percentage;

  const SensorBar({
    super.key,
    required this.type,
    required this.value,
    required this.unit,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final config = _getConfig(type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(config.icon, color: config.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.t(config.labelKey),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(
                '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$unit',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: config.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: config.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(config.color),
            ),
          ),
        ],
      ),
    );
  }

  _SensorConfig _getConfig(String type) {
    switch (type) {
      case 'temperature':
        return _SensorConfig(
          icon: LucideIcons.thermometer,
          color: AppColors.temperature,
          labelKey: 'temperature',
        );
      case 'air_humidity':
        return _SensorConfig(
          icon: LucideIcons.droplets,
          color: AppColors.humidity,
          labelKey: 'air_humidity',
        );
      case 'soil_moisture':
        return _SensorConfig(
          icon: LucideIcons.sprout,
          color: AppColors.soilMoisture,
          labelKey: 'soil_moisture',
        );
      default:
        return _SensorConfig(
          icon: LucideIcons.gauge,
          color: AppColors.primaryGreen,
          labelKey: type,
        );
    }
  }
}

class _SensorConfig {
  final IconData icon;
  final Color color;
  final String labelKey;

  _SensorConfig({
    required this.icon,
    required this.color,
    required this.labelKey,
  });
}
