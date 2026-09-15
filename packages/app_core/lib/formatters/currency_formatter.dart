/// Centralized currency formatter working strictly with integer minor currency units.
///
/// NOTE (AGENTS.md rule 9 & DATA_MODELS.md rule 6):
/// Never use `double` for money calculation.
/// Minor units: ₹199.50 => 19950.
class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Formats an integer minor amount (e.g. 19950 for ₹199.50) into a clean display string.
  ///
  /// Uses integer arithmetic to avoid floating point precision loss.
  static String format(
    int minorAmount, {
    String currencyCode = 'INR',
    bool showSymbol = true,
    int decimalDigits = 2,
  }) {
    final isNegative = minorAmount < 0;
    final absMinor = minorAmount.abs();

    final divisor = _pow10(decimalDigits);
    final major = absMinor ~/ divisor;
    final minor = absMinor % divisor;

    final minorPadded = minor.toString().padLeft(decimalDigits, '0');
    final sign = isNegative ? '-' : '';

    final symbol = showSymbol
        ? _currencySymbol(currencyCode)
        : '$currencyCode ';

    if (decimalDigits == 0) {
      return '$sign$symbol$major';
    }

    return '$sign$symbol$major.$minorPadded';
  }

  static String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'AED ';
      default:
        return '$code ';
    }
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
