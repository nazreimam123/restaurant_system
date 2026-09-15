import 'package:flutter/material.dart';

/// Centralized elevation and shadow tokens specified by APP_DESIGN_SYSTEM_AND_UI_SPEC.md.
class AppShadows {
  const AppShadows._();

  /// Standard card elevation shadow (subtle blur 12, offset 0,4, opacity 0.06)
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F111827), blurRadius: 12.0, offset: Offset(0, 4)),
  ];

  /// Floating bar / CTA shadow (blur 20, offset 0,8, opacity 0.10)
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1A111827), blurRadius: 20.0, offset: Offset(0, 8)),
  ];
}
