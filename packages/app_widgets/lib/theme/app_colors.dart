import 'package:flutter/material.dart';

/// Centralized color tokens specified by APP_DESIGN_SYSTEM_AND_UI_SPEC.md.
class AppColors {
  const AppColors._();

  // Primary brand palette
  static const Color primary = Color(0xFF1F7A4C);
  static const Color primaryDark = Color(0xFF155D39);
  static const Color primaryLight = Color(0xFFEAF6EF);

  // Accent
  static const Color accent = Color(0xFFF59E0B);

  // Neutrals / Surfaces
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F3F5);
  static const Color border = Color(0xFFE4E7EC);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textTertiary = Color(0xFF98A2B3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status / Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Disabled
  static const Color disabled = Color(0xFFD0D5DD);
  static const Color disabledText = Color(0xFF98A2B3);
}
