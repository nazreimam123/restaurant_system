import 'app_exception.dart';
import 'error_code.dart';

/// Centralized mapper that converts transport, backend, and unexpected exceptions
/// into safe, domain-typed [AppException] instances.
///
/// NOTE:
/// Raw database / SQL error strings (e.g. relation names, constraint violations,
/// PostgrestException) must NEVER be exposed directly to UI presentation.
class ErrorMapper {
  const ErrorMapper._();

  /// Maps an unknown error or exception to a typed [AppException].
  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    // Inspect error string representation safely
    final errStr = error.toString();

    // Check for network/socket issues
    if (errStr.contains('SocketException') ||
        errStr.contains('Failed host lookup') ||
        errStr.contains('Connection refused') ||
        errStr.contains('Network is unreachable') ||
        errStr.contains('ClientException')) {
      return NetworkException(
        message:
            'Unable to connect to the server. Please check your internet connection.',
        cause: error,
      );
    }

    // Check for timeout
    if (errStr.contains('TimeoutException') ||
        errStr.contains('deadline exceeded')) {
      return NetworkException(
        message: 'The request timed out. Please try again.',
        code: ErrorCode.timeout,
        cause: error,
      );
    }

    // Check for Auth / JWT / session expired
    if (errStr.contains('AuthException') ||
        errStr.contains('JWT expired') ||
        errStr.contains('invalid_token') ||
        errStr.contains('session_not_found')) {
      return AppAuthException(
        message: 'Your session has expired. Please log in again.',
        code: ErrorCode.unauthenticated,
        cause: error,
      );
    }

    // Check for 403 / 401 / permission denied
    if (errStr.contains('403') ||
        errStr.contains('row-level security policy') ||
        errStr.contains('permission denied')) {
      return PermissionDeniedException(
        message: 'You do not have permission to perform this action.',
        code: ErrorCode.forbidden,
        cause: error,
      );
    }

    // Check for 404
    if (errStr.contains('404') || errStr.contains('not found')) {
      return NotFoundException(
        message: 'The requested resource was not found.',
        cause: error,
      );
    }

    // Check for format / JSON parse exceptions
    if (error is FormatException || errStr.contains('FormatException')) {
      return ParseException(
        message: 'Failed to process server response.',
        cause: error,
      );
    }

    // Default sanitized server error
    return ServerException(
      message: 'An unexpected error occurred. Please try again later.',
      cause: error,
    );
  }

  /// Maps an API error payload (from RPC response `{ "code": ..., "message": ..., "details": ... }`)
  /// to an appropriate [AppException].
  static AppException fromApiError({
    required String code,
    required String message,
    Map<String, dynamic> details = const {},
  }) {
    switch (code) {
      case ErrorCode.unauthenticated:
        return AppAuthException(message: message, details: details);
      case ErrorCode.unauthorized:
      case ErrorCode.forbidden:
        return PermissionDeniedException(
          message: message,
          code: code,
          details: details,
        );
      case ErrorCode.qrNotFound:
      case ErrorCode.branchNotFound:
      case ErrorCode.restaurantNotFound:
      case ErrorCode.tableNotFound:
      case ErrorCode.productNotFound:
      case ErrorCode.orderNotFound:
        return NotFoundException(
          message: message,
          code: code,
          details: details,
        );
      case ErrorCode.conflict:
        return ConflictException(message: message, details: details);
      default:
        return DomainException(message: message, code: code, details: details);
    }
  }
}
