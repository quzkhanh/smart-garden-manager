import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class DeviceTimerButton extends StatelessWidget {
  final bool hasTimer;
  final VoidCallback? onTap;
  final bool isDark;

  const DeviceTimerButton({
    super.key,
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

class DeviceTimerCountdown extends StatelessWidget {
  final Device device;
  final VoidCallback? onCancel;
  final bool isDark;

  const DeviceTimerCountdown({
    super.key,
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
          const Icon(
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
            child: const Padding(
              padding: EdgeInsets.all(4),
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
