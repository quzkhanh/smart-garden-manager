import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Nature Green
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryGreenLight = Color(0xFF81C784);
  static const Color primaryGreenDark = Color(0xFF388E3C);
  static const Color primaryGreenSurface = Color(0xFFE8F5E9);
  static const Color primaryGreenSurfaceDark = Color(0xFF1A2B20);

  // Secondary - Data Blue
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color secondaryBlueDark = Color(0xFF1E88E5);
  static const Color secondaryBlueSurface = Color(0xFFE3F2FD);

  // Alert Colors
  static const Color alertHigh = Color(0xFFEF5350);
  static const Color alertHighSurface = Color(0xFFFDE8E8);
  static const Color alertMedium = Color(0xFFFFA726);
  static const Color alertMediumSurface = Color(0xFFFFF3E0);
  static const Color alertLow = Color(0xFF42A5F5);
  static const Color alertLowSurface = Color(0xFFE3F2FD);

  // Sensor Colors
  static const Color temperature = Color(0xFFEF5350);
  static const Color humidity = Color(0xFF42A5F5);
  static const Color soilMoisture = Color(0xFF26A69A);

  // Light Theme
  static const Color lightBackground = Color(0xFFF5F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE8ECE8);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Dark Theme - Neutral dark with subtle warmth for readability
  static const Color darkBackground = Color(0xFF111318);
  static const Color darkSurface = Color(0xFF1A1D24);
  static const Color darkCardBorder = Color(0xFF2A2D35);
  static const Color darkTextPrimary = Color(0xFFF0F2F5);
  static const Color darkTextSecondary = Color(0xFFA0A8B4);
  static const Color darkTextTertiary = Color(0xFF6B7280);
  static const Color darkDivider = Color(0xFF2A2D35);

  // Status
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient loginBackgroundGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient loginBackgroundGradientDark = LinearGradient(
    colors: [Color(0xFF1A2030), Color(0xFF111318)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
