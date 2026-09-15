/// Centralized responsive breakpoint tokens specified by APP_DESIGN_SYSTEM_AND_UI_SPEC.md.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;

  // Maximum content widths
  static const double maxContentWidthCustomerWeb = 1100.0;
  static const double maxContentWidthAdminDesktop = 1600.0;
  static const double maxFormWidth = 720.0;
  static const double maxAuthFormWidth = 420.0;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}
