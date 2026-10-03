import 'package:flutter/material.dart';

/// Centralized color palette derived directly from the MI Notes reference screenshots.
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF000000); // Pure pitch black
  static const Color cardBackground = Color(0xFF202020); // Warm charcoal card
  static const Color cardBackgroundHover = Color(0xFF2A2A2A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF262626);
  static const Color dialogBackground = Color(0xFF1E1E1E);

  // Brand Accent (Warm Golden Amber / Orange from MI Notes)
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFB84D);
  static const Color accentDark = Color(0xFFD48B12);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);
  static const Color textMuted = Color(0xFF48484A);

  // Category Filter Chips
  static const Color chipBackgroundUnselected = Color(0xFF252525);
  static const Color chipBackgroundSelected = Color(0xFF3A3A3C);
  static const Color chipTextUnselected = Color(0xFF8E8E93);
  static const Color chipTextSelected = Color(0xFFFFFFFF);

  // Icons
  static const Color iconPrimary = Color(0xFFFFFFFF);
  static const Color iconSecondary = Color(0xFF8E8E93);
  static const Color iconAccent = Color(0xFFF5A623);
  static const Color iconDisabled = Color(0xFF48484A);

  // Dividers & Borders
  static const Color divider = Color(0xFF2C2C2E);
  static const Color border = Color(0xFF38383A);

  // Status & Sync
  static const Color syncSuccess = Color(0xFF34C759);
  static const Color syncPending = Color(0xFFF5A623);
  static const Color syncOffline = Color(0xFFFF453A);

  // Checkbox & Task
  static const Color checkboxBorder = Color(0xFF636366);
  static const Color checkboxActive = Color(0xFFF5A623);
}
