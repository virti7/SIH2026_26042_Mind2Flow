import 'package:flutter/material.dart';

/// Very subtle shadows for the white-background system — separation comes
/// from the light card border first, shadow second. Low opacity, neutral.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A123B6D),
      offset: Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x12123B6D),
      offset: Offset(0, 6),
      blurRadius: 18,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> primaryButton = [
    BoxShadow(
      color: Color(0x2619A974),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x0A123B6D),
      offset: Offset(0, -2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> illustrationGlow = [
    BoxShadow(
      color: Color(0x1219A974),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
}
