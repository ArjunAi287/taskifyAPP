import 'package:flutter/material.dart';

class AppColors {
  // Private constructor
  AppColors._();

  // Arctic Stealth Palette (Monochrome & Deep Void)
  static const Color background = Color(0xFF050505); // Pure Void Black
  static const Color surface = Color(0xFF0F0F0F);    // Obsidian Surface
  static const Color surfaceElevated = Color(0xFF141414); // Slightly Lighter Obsidian
  static const Color surfaceHighlight = Color(0xFF202020); // Dark Graphite

  // Primary Accents (Stealth White/Silver)
  static const Color primary = Color(0xFFEAEAEA); // Off-White / Platinum
  static const Color primaryVariant = Color(0xFFAAAAAA); // Silver

  // Secondary Accents (Charcoal/Graphite)
  static const Color secondary = Color(0xFF4A4A4A); // Graphite
  static const Color secondaryVariant = Color(0xFF2C2C2C); // Dark Charcoal

  // Tertiary Accents (Clean Slate)
  static const Color tertiary = Color(0xFF606060); // Slate Grey

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F0F0); // Off-White Text
  static const Color textSecondary = Color(0xFFA0A0A0); // Silver Grey
  static const Color textDisabled = Color(0xFF404040); // Dark Grey

  // Semantic Colors (Muted)
  static const Color error = Color(0xFFCF6679);  // Muted Red
  static const Color success = Color(0xFFEAEAEA); // Platinum (Success = Primary)
  static const Color warning = Color(0xFFFFD54F); // Muted Amber
  static const Color info = Color(0xFF90CAF9);   // Muted Blue

  // Borders & Dividers
  static const Color border = Color(0xFF252525);
  static const Color divider = Color(0xFF1A1A1A);
  
  // Special Effects
  static const Color glowPrimary = Color(0x33EAEAEA); // Subtle White Glow (Low Opacity)
  static const Color glowSecondary = Color(0x334A4A4A); // Subtle Graphite Glow
  static const Color scrim = Color(0xB3000000); // 70% opacity black

  // Gradients
  static const LinearGradient stealthGradient = LinearGradient(
    colors: [Color(0xFFEAEAEA), Color(0xFFB0B0B0)], // Off-White to Silver
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
