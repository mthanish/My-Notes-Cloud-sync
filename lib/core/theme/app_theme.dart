import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.iconPrimary, size: 22),
        titleTextStyle: AppTypography.screenTitle,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.cardTitle.copyWith(fontSize: 18),
        contentTextStyle: AppTypography.cardBody,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: Color(0x66F5A623),
        selectionHandleColor: AppColors.accent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 2,
        shape: CircleBorder(),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
        size: 22,
      ),
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 1,
      ),
      splashColor: Colors.transparent,
      highlightColor: const Color(0x1AFFFFFF),
    );
  }
}
