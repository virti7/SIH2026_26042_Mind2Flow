import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography system for Maatribhasha.
/// Uses Poppins with seamless Devanagari and Latin rendering.
class AppTypography {
  AppTypography._();

  static TextStyle get largeTitle => GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get pageTitle => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: -0.4,
        height: 1.25,
      );

  static TextStyle get screenTitle => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: -0.3,
      );

  static TextStyle get sectionHeading => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionTitle => GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
        letterSpacing: -0.2,
      );

  static TextStyle get cardTitle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      );

  static TextStyle get cardTitleSmall => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get captionSmall => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get buttonText => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get chipLabel => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get devanagariHeading => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get devanagariBody => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get tribalVernacular => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: AppColors.primary,
      );
}
