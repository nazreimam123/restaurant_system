/// Utility for safely parsing and validating QR code payloads.
///
/// Follows AGENTS.md rule 48:
/// "Canonical QR: `https://order.example.com/q/<uuid-token>`
/// Do not trust URL query parameters for price/branch/table authority."
class QrTokenParser {
  const QrTokenParser._();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Extracts the opaque UUID token from a raw QR code string or deep link URL.
  ///
  /// Returns the valid lowercase UUID string if successfully extracted, or `null` if invalid.
  static String? parse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Direct UUID match
    if (_uuidRegex.hasMatch(trimmed)) {
      return trimmed.toLowerCase();
    }

    // 2. URI parsing
    try {
      final uri = Uri.parse(trimmed);
      final segments = uri.pathSegments
          .where((s) => s.trim().isNotEmpty)
          .toList();

      // Look for pattern /q/<uuid>
      final qIndex = segments.indexOf('q');
      if (qIndex != -1 && qIndex + 1 < segments.length) {
        final candidate = segments[qIndex + 1];
        if (_uuidRegex.hasMatch(candidate)) {
          return candidate.toLowerCase();
        }
      }

      // If the last segment is a UUID
      if (segments.isNotEmpty) {
        final last = segments.last;
        if (_uuidRegex.hasMatch(last)) {
          return last.toLowerCase();
        }
      }
    } catch (_) {
      // Not a valid URI
    }

    // 3. Fallback regex search within raw string for embedded UUID
    final match = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(trimmed);

    if (match != null) {
      return match.group(0)!.toLowerCase();
    }

    return null;
  }
}
