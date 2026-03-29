import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/settings_provider.dart';

class ThemeToggleIndicator extends StatelessWidget {
  const ThemeToggleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        settings.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08) 
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            isDark ? LucideIcons.moon : LucideIcons.sun,
            size: 20,
            color: isDark ? const Color(0xFF66DD6A) : Colors.orange,
          ),
        ),
      ),
    );
  }
}
