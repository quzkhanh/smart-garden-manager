import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';

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
