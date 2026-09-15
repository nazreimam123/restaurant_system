/// Centralized helper to format status names for user presentation.
class StatusFormatter {
  const StatusFormatter._();

  /// Converts snake_case or camelCase token into Title Case
  static String toDisplayTitle(String token) {
    if (token.isEmpty) return '';

    // Replace underscores with spaces
    final withSpaces = token.replaceAll('_', ' ');

    // Split on spaces and camelCase transitions
    final regex = RegExp(r'(?<=[a-z])(?=[A-Z])');
    final splitWords = withSpaces.split(regex);

    return splitWords
        .map((word) {
          final trimmed = word.trim();
          if (trimmed.isEmpty) return '';
          return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
