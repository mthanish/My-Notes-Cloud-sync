import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Screen Title / Large Headers
  static const TextStyle screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Note Detail Title
  static const TextStyle noteDetailTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // Note Detail Metadata ("11 September 9:23 PM | 18598 characters")
  static const TextStyle noteMetadata = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    letterSpacing: -0.1,
  );

  // Note Detail & Editor Body Text
  static const TextStyle noteBody = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFFE5E5EA),
    height: 1.55,
    letterSpacing: -0.2,
  );

  // Note Card Title (Grid)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Note Card Body Preview
  static const TextStyle cardBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.35,
    letterSpacing: -0.1,
  );

  // Note Card Date & Footer
  static const TextStyle cardDate = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // Category Filter Chips
  static const TextStyle chipSelected = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.chipTextSelected,
  );

  static const TextStyle chipUnselected = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.chipTextUnselected,
  );

  // Task Tile Text
  static const TextStyle taskTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle taskTitleCompleted = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.textTertiary,
  );

  // Empty State Text
  static const TextStyle emptyStateText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // Mind Map Node Text
  static const TextStyle mindMapRoot = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const TextStyle mindMapBranch = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
