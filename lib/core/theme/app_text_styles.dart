import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
  );

  static final TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
  );

  static final TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.espresso,
  );

  static final TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
  );

  static final TextStyle titleLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
  );

  static final TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.espresso,
  );

  static final TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: AppColors.espresso,
  );

  static final TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
  );

  static final TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedTaupe,
  );

  static final TextStyle labelLarge = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.espresso,
  );

  static final TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.buttonText,
  );

  static final TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedTaupe,
  );
}
