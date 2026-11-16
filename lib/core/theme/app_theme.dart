import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.champagneGold,
      brightness: Brightness.light,
      primary: AppColors.champagneGold,
      secondary: AppColors.warmGold,
      surface: AppColors.warmIvory,
      onSurface: AppColors.espresso,
      error: AppColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      cardColor: AppColors.glassSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.espresso,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.glassSurface,
        selectedItemColor: AppColors.champagneGold,
        unselectedItemColor: AppColors.mutedTaupe,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.glassSurface,
        indicatorColor: AppColors.cream,
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.caption),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(
            color: AppColors.champagneGold,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.secondary,
        ),
        floatingLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.secondary,
        ),
        helperStyle: AppTextStyles.caption.copyWith(
          color: AppColors.mutedTaupe,
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.secondary,
        suffixIconColor: AppColors.secondary,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      dividerColor: AppColors.border,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.glassSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.glassSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        headerBackgroundColor: AppColors.graphite,
        headerForegroundColor: AppColors.espresso,
        weekdayStyle: AppTextStyles.caption.copyWith(
          color: AppColors.secondary,
        ),
        dayStyle: AppTextStyles.bodySmall,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.disabled;
          if (states.contains(WidgetState.selected)) return AppColors.graphite;
          return AppColors.secondary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.champagneGold;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.champagneGold),
        todayBorder: const BorderSide(color: AppColors.champagneGold),
        yearStyle: AppTextStyles.bodyMedium,
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.graphite;
          return AppColors.secondary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.champagneGold;
          }
          return Colors.transparent;
        }),
        rangePickerBackgroundColor: AppColors.glassSurface,
        rangePickerHeaderBackgroundColor: AppColors.graphite,
        rangePickerHeaderForegroundColor: AppColors.espresso,
        rangeSelectionBackgroundColor: AppColors.cream,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.champagneGold,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.champagneGold,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassSurface,
        selectedColor: AppColors.cream,
        checkmarkColor: AppColors.espresso,
        labelStyle: AppTextStyles.bodySmall,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );

    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.champagneGold,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.champagneGold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.champagneGold,
          foregroundColor: AppColors.buttonText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.espresso,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppColors.glassSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
        ),
      ),
    );
  }
}
