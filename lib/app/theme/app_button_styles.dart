import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// Centralized button styling — single source of truth.
/// Widgets in `core/widgets/app_buttons.dart` consume these values so every
/// screen shares the same green-filled primary and white secondary treatment.
class AppButtonStyles {
  AppButtonStyles._();

  static const double height = 52;
  static const double heightCompact = 44;
  static const EdgeInsetsGeometry paddingPrimary =
      EdgeInsets.symmetric(horizontal: 24, vertical: 14);
  static const EdgeInsetsGeometry paddingSecondary =
      EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  static ButtonStyle get primary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Color(0x409AA3B5),
        elevation: 0,
        padding: paddingPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
      );

  static ButtonStyle get secondary => OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        padding: paddingSecondary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
      );
}
