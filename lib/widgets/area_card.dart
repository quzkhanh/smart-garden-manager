import 'package:flutter/material.dart';
import '../models/area.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class AreaCard extends StatelessWidget {
  final Area area;
  final VoidCallback? onTap;

  const AreaCard({
    super.key,
    required this.area,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tempSensor = area.getSensor('temperature');
    final humiditySensor = area.getSensor('air_humidity');
    final soilSensor = area.getSensor('soil_moisture');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        area.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !area.isOnline
                            ? Colors.grey
                            : area.isSoilRenovation
                                ? Colors.orange
                                : area.isAutoMode
                                    ? AppColors.primaryGreen
                                    : AppColors.alertMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      area.isSoilRenovation
                          ? 'Cải tạo đất'
                          : area.isAutoMode ? l10n.t('auto_mode') : l10n.t('manual_mode'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: !area.isOnline
                            ? Colors.grey
                            : area.isSoilRenovation
                                ? Colors.orange
                                : area.isAutoMode
                                    ? AppColors.primaryGreen
                                    : AppColors.alertMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!area.isOnline) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ngoại tuyến',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Sensor data
                if (tempSensor != null)
                  _SensorRow(
                    icon: Icons.thermostat_rounded,
                    color: AppColors.temperature,
                    label: l10n.t('temperature'),
                    value: '${tempSensor.value.toStringAsFixed(0)}${tempSensor.unit}',
                  ),
                if (humiditySensor != null) ...[
                  const SizedBox(height: 10),
                  _SensorRow(
                    icon: Icons.water_drop_outlined,
                    color: AppColors.humidity,
                    label: l10n.t('air_humidity'),
                    value: '${humiditySensor.value.toStringAsFixed(0)}${humiditySensor.unit}',
                  ),
                ],
                if (soilSensor != null) ...[
                  const SizedBox(height: 10),
                  _SensorRow(
                    icon: Icons.grass_rounded,
                    color: AppColors.soilMoisture,
                    label: l10n.t('soil_moisture'),
                    value: '${soilSensor.value.toStringAsFixed(0)}${soilSensor.unit}',
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // View details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('view_details'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.textTheme.bodyMedium?.color,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SensorRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
