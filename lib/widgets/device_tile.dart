import 'package:flutter/material.dart';
import '../models/device.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class DeviceTile extends StatelessWidget {
  final Device device;
  final bool isAutoMode;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTimerTap;
  final VoidCallback? onCancelTimer;

  const DeviceTile({
    super.key,
    required this.device,
    this.isAutoMode = false,
    this.onToggle,
    this.onTimerTap,
    this.onCancelTimer,
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
        border: Border.all(
          color: isActive
              ? AppColors.primaryGreen.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: 1,
        ),
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
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: isActive
                      ? AppColors.primaryGreen
                      : theme.textTheme.bodyMedium?.color,
                  size: 22,
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
                _TimerButton(
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
                    onChanged:
                        isAutoMode ? null : (val) => onToggle?.call(val),
                    activeTrackColor: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          // Timer countdown display
          if (hasTimer && !isAutoMode) ...[
            const SizedBox(height: 10),
            _TimerCountdown(
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
        return Icons.water_rounded;
      case 'mist':
        return Icons.cloud_rounded;
      case 'fan':
        return Icons.air_rounded;
      case 'light':
        return Icons.light_mode_rounded;
      case 'valve':
        return Icons.toggle_on_rounded;
      default:
        return Icons.devices_other;
    }
  }
}

class _TimerButton extends StatelessWidget {
  final bool hasTimer;
  final VoidCallback? onTap;
  final bool isDark;

  const _TimerButton({
    required this.hasTimer,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasTimer
              ? AppColors.secondaryBlue.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
          border: hasTimer
              ? Border.all(
                  color: AppColors.secondaryBlue.withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Icon(
          hasTimer ? Icons.timer : Icons.timer_outlined,
          color: hasTimer
              ? AppColors.secondaryBlue
              : (isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.4)),
          size: 20,
        ),
      ),
    );
  }
}

class _TimerCountdown extends StatelessWidget {
  final Device device;
  final VoidCallback? onCancel;
  final bool isDark;

  const _TimerCountdown({
    required this.device,
    this.onCancel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final remaining = device.timerRemaining;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    final timeString = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Calculate progress
    final totalSeconds = device.timerDuration?.inSeconds ?? 1;
    final remainingSeconds = remaining.inSeconds;
    final progress = remainingSeconds / totalSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryBlue.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: AppColors.secondaryBlue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${l10n.t('timer_remaining')}: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryBlue,
            ),
          ),
          Text(
            timeString,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.secondaryBlue,
              fontWeight: FontWeight.w700,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          // Progress indicator
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor:
                    AppColors.secondaryBlue.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.secondaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.secondaryBlue,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for picking a timer duration
class TimerPickerDialog extends StatefulWidget {
  const TimerPickerDialog({super.key});

  @override
  State<TimerPickerDialog> createState() => _TimerPickerDialogState();
}

class _TimerPickerDialogState extends State<TimerPickerDialog> {
  int _hours = 0;
  int _minutes = 30;

  // Quick presets
  static const _presets = [
    {'label': '5m', 'minutes': 5},
    {'label': '15m', 'minutes': 15},
    {'label': '30m', 'minutes': 30},
    {'label': '1h', 'minutes': 60},
    {'label': '2h', 'minutes': 120},
    {'label': '4h', 'minutes': 240},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.timer_rounded,
                    color: AppColors.secondaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t('set_timer'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick presets
            Text(
              l10n.t('quick_presets'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final mins = preset['minutes'] as int;
                final isSelected = (_hours * 60 + _minutes) == mins;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _hours = mins ~/ 60;
                      _minutes = mins % 60;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondaryBlue.withValues(alpha: 0.15)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondaryBlue.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      preset['label'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isSelected ? AppColors.secondaryBlue : null,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Custom time picker
            Text(
              l10n.t('custom_time'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours
                _NumberPicker(
                  value: _hours,
                  minValue: 0,
                  maxValue: 23,
                  label: l10n.t('hours_short'),
                  onChanged: (v) => setState(() => _hours = v),
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    ':',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                ),
                // Minutes
                _NumberPicker(
                  value: _minutes,
                  minValue: 0,
                  maxValue: 59,
                  label: l10n.t('minutes_short'),
                  onChanged: (v) => setState(() => _minutes = v),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.t('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_hours == 0 && _minutes == 0)
                        ? null
                        : () {
                            final duration = Duration(
                              hours: _hours,
                              minutes: _minutes,
                            );
                            Navigator.of(context).pop(duration);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.t('start_timer')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final String label;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _NumberPicker({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.label,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Up button
        IconButton(
          onPressed: value < maxValue ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          iconSize: 28,
          color: AppColors.secondaryBlue,
        ),
        // Value display
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        // Down button
        IconButton(
          onPressed: value > minValue ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 28,
          color: AppColors.secondaryBlue,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
