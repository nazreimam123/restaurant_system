import 'package:intl/intl.dart';

/// Centralized date and time formatter.
class AppDateFormatter {
  const AppDateFormatter._();

  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • h:mm a');
  static final DateFormat _shortTimeFormat = DateFormat('HH:mm');

  /// Formats date (e.g. "Sep 15, 2026")
  static String formatDate(DateTime dateTime) =>
      _dateFormat.format(dateTime.toLocal());

  /// Formats time (e.g. "1:45 PM")
  static String formatTime(DateTime dateTime) =>
      _timeFormat.format(dateTime.toLocal());

  /// Formats full date and time (e.g. "Sep 15, 2026 • 1:45 PM")
  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime.toLocal());

  /// Formats 24h short time (e.g. "13:45")
  static String formatShortTime(DateTime dateTime) =>
      _shortTimeFormat.format(dateTime.toLocal());

  /// Returns elapsed duration string for KDS and live orders (e.g. "4m", "1h 12m", "Just now").
  static String formatElapsed(DateTime from, [DateTime? to]) {
    final target = to ?? DateTime.now();
    final difference = target.difference(from);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    final hours = difference.inHours;
    final remainingMinutes = difference.inMinutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h ago';
    }
    return '${hours}h ${remainingMinutes}m ago';
  }
}
