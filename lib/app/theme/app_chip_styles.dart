import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// Centralized chip styling — pill-shaped, compact, pastel.
/// Selected = muted green. Unselected = white / light pastel with hairline border.
class AppChipStyles {
  AppChipStyles._();

  static const EdgeInsetsGeometry paddingCompact =
      EdgeInsets.symmetric(horizontal: 10, vertical: 5);
  static const EdgeInsetsGeometry paddingStandard =
      EdgeInsets.symmetric(horizontal: 14, vertical: 8);
  static const EdgeInsetsGeometry paddingLarge =
      EdgeInsets.symmetric(horizontal: 18, vertical: 10);

  static BoxDecoration decoration({required bool selected, Color? unselectedColor}) {
    return BoxDecoration(
      color: selected ? AppColors.primary : (unselectedColor ?? Colors.white),
      borderRadius: AppRadius.radiusPill,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.cardBorder,
        width: 1,
      ),
    );
  }

  static BoxDecoration get offlineReady => const BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.all(Radius.circular(999)),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.greenBorder, width: 1),
        ),
      );

  static BoxDecoration pastel(Color background) => BoxDecoration(
        color: background,
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: AppColors.cardBorder, width: 1),
      );
}
