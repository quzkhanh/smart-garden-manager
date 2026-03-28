import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ConfigDurationRow extends StatelessWidget {
  final TimeOfDay on;
  final TimeOfDay off;

  const ConfigDurationRow({
    super.key,
    required this.on,
    required this.off,
  });

  int _durationMinutes() {
    final onMins = on.hour * 60 + on.minute;
    final offMins = off.hour * 60 + off.minute;
    // Handle overnight (e.g. 22:00 → 06:00)
    return offMins >= onMins
        ? offMins - onMins
        : (24 * 60 - onMins) + offMins;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final durationMins = _durationMinutes();
    final h = durationMins ~/ 60;
    final m = durationMins % 60;
    
    // Custom logic for duration display
    final hSuffix = l10n.t('hours_short');
    final mSuffix = l10n.t('minutes_short');
    final durationStr = h > 0
        ? (m > 0 ? '$h $hSuffix $m $mSuffix' : '$h $hSuffix')
        : '$m $mSuffix';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, size: 14, color: Colors.amber),
        const SizedBox(width: 6),
        Text(
          '${l10n.t('config_light_duration')}: $durationStr',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.amber.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
