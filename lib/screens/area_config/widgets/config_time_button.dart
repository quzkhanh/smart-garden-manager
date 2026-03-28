import 'package:flutter/material.dart';

class ConfigTimeButton extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final IconData? secondaryIcon;
  final Color color;
  final VoidCallback onTap;

  const ConfigTimeButton({
    super.key,
    required this.label,
    required this.time,
    required this.icon,
    this.secondaryIcon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          // If the color already has high alpha, use it directly (with slight reduction for depth)
          // otherwise use the theme-matching faint background
          color: color.a > 0.5 
              ? color.withValues(alpha: 0.95) 
              : color.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.a > 0.5 ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color.a > 0.5 ? Colors.white : color, size: 20),
                if (secondaryIcon != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(secondaryIcon, color: color.a > 0.5 ? Colors.white.withValues(alpha: 0.8) : color, size: 10),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.a > 0.5 ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color.a > 0.5 ? Colors.white : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
