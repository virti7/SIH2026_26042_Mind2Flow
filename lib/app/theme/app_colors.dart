import 'package:flutter/material.dart';

/// Master visual system for Maatribhasha — Premium Educational Palette.
///
/// Rules:
/// - Page background: #F7F8FA (subtle off-white)
/// - Card backgrounds: pure white (#FFFFFF)
/// - Color lives in buttons, icons, chips, badges, selected states, small highlights.
/// - Card separation: 1px border #D9E0E7 + very subtle shadow.
/// - Semantic accents: green=primary/success, blue=info/translation, amber=pending/warning, red=error/priority-high, purple=special/Co-Pilot.
/// - Most cards remain WHITE with NAVY text + ONE small accent.
/// - Colored surfaces only where semantic meaning requires them.
class AppColors {
  AppColors._();

  // PRIMARY NAVY
  static const Color primaryNavy = Color(0xFF123B68);
  static const Color darkNavy = Color(0xFF0B2D4F);

  // PRIMARY GREEN
  static const Color primaryGreen = Color(0xFF0B9B68);
  static const Color darkGreen = Color(0xFF087A54);
  static const Color lightGreenSurface = Color(0xFFE8F5EF);

  // BLUE (information / translation / input)
  static const Color blue = Color(0xFF2F6FD6);
  static const Color lightBlueSurface = Color(0xFFEAF2FC);

  // AMBER (pending / warning / attention)
  static const Color amber = Color(0xFFD98200);
  static const Color lightAmberSurface = Color(0xFFFFF3D9);

  // RED (errors / high priority)
  static const Color red = Color(0xFFD94A4A);

  // PURPLE (special / Co-Pilot / activities)
  static const Color purple = Color(0xFF7656C7);

  // PAGE & CARD BACKGROUNDS
  static const Color pageBackground = Color(0xFFF7F8FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD9E0E7);

  // TYPOGRAPHY
  static const Color textHeading = Color(0xFF0B2D4F); // darkest navy
  static const Color textBody = Color(0xFF35516F);   // dark navy body
  static const Color textPrimary = textBody;         // alias for existing code
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF8291A5);
  static const Color textLight = Color(0xFFFFFFFF);

  // LEGACY ALIASES (preserved for existing code compatibility)
  // Primary — primary actions / success / continue
  static const Color primary = primaryGreen;
  static const Color primaryDark = darkGreen;
  static const Color primaryLight = Color(0xFF34C78A);
  static const Color primaryAccent = primaryGreen;

  // Soft green tints — small highlights, chips, icon washes only
  static const Color greenLight = lightGreenSurface;
  static const Color greenSurface = lightGreenSurface;
  static const Color greenBorder = Color(0xFFB8E0CC);

  // Background & surfaces
  static const Color background = cardBackground;
  static const Color backgroundSoft = pageBackground;
  static const Color surface = cardBackground;
  static const Color surfaceSubtle = pageBackground;
  static const Color cardCream = cardBackground;
  static const Color cardBorder = border;

  // Light accent washes — icon containers, chips, badges, never page fills
  static const Color pastelGreen = lightGreenSurface;
  static const Color pastelBlue = lightBlueSurface;
  static const Color pastelPeach = lightAmberSurface;
  static const Color pastelLavender = Color(0xFFF0ECFC);
  static const Color pastelYellow = lightAmberSurface;
  static const Color pastelCream = pageBackground;

  // Strand accents — subtle icon/label tints, cards stay white
  static const Color strandGreenBg = lightGreenSurface;
  static const Color strandBlueBg = lightBlueSurface;
  static const Color strandAmberBg = lightAmberSurface;
  static const Color strandOrangeBg = Color(0xFFFFF0E0);

  // Functional accents — meaning is fixed
  static const Color accentAmber = amber;
  static const Color accentAmberLight = lightAmberSurface;
  static const Color accentBlue = blue;
  static const Color accentBlueLight = lightBlueSurface;
  static const Color accentOrange = Color(0xFFE07B00);
  static const Color accentOrangeLight = Color(0xFFFFF0E0);
  static const Color accentLavender = purple;
  static const Color accentLavenderLight = Color(0xFFF0ECFC);

  // Extended accents (same meaning system)
  static const Color accentRed = red;
  static const Color accentRedLight = Color(0xFFFDEAE8);
  static const Color accentPurple = purple;
  static const Color accentPurpleLight = Color(0xFFF0ECFC);
  static const Color accentYellow = Color(0xFFE0A800);
  static const Color accentYellowLight = lightAmberSurface;

  // Status
  static const Color statusAchieved = primaryGreen;
  static const Color statusAchievedBg = lightGreenSurface;

  static const Color statusDeveloping = amber;
  static const Color statusDevelopingBg = lightAmberSurface;

  static const Color statusNeedsSupport = red;
  static const Color statusNeedsSupportBg = Color(0xFFFDEAE8);

  // Typography — darker navy for confident hierarchy
  static const Color navy = primaryNavy;
  static const Color navySoft = Color(0xFF1D4A7E);

  // Dividers & borders — subtle neutral
  static const Color divider = Color(0xFFE8EEF4);
  // border already defined above as #D9E0E7

  // Bottom nav — white bar, green active, muted inactive
  static const Color bottomNavBg = cardBackground;
  static const Color bottomNavActive = primaryGreen;
  static const Color bottomNavInactive = textMuted;
}