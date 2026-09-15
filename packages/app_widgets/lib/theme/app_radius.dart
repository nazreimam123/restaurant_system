import 'package:flutter/material.dart';

/// Centralized radius tokens specified by APP_DESIGN_SYSTEM_AND_UI_SPEC.md.
class AppRadius {
  const AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xl = 20.0;
  static const double pill = 999.0;

  // BorderRadius helpers
  static const BorderRadius smallBorderRadius = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius mediumBorderRadius = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius largeBorderRadius = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius xlBorderRadius = BorderRadius.all(
    Radius.circular(xl),
  );
  static const BorderRadius pillBorderRadius = BorderRadius.all(
    Radius.circular(pill),
  );

  // BottomSheet top corners
  static const BorderRadius bottomSheetBorderRadius = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
