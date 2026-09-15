import 'package:meta/meta.dart';
import 'error_code.dart';

/// Base class for all application-level exceptions.
///
/// Views must NEVER display raw PostgrestException or SQL errors.
/// Repositories map all transport and backend errors to a typed [AppException].
@immutable
abstract class AppException implements Exception {
  final String message;
  final String code;
  final Map<String, dynamic> details;
  final Object? cause;

  const AppException({
    required this.message,
    this.code = ErrorCode.unknown,
    this.details = const {},
    this.cause,
  });

  @override
  String toString() =>
      '$runtimeType(code: $code, message: $message, details: $details)';
}

/// Thrown when an authentication error occurs or user is unauthenticated.
class AppAuthException extends AppException {
  const AppAuthException({
    required super.message,
    super.code = ErrorCode.unauthenticated,
    super.details,
    super.cause,
  });
}

/// Thrown when permission or role check fails (unauthorized / forbidden).
class PermissionDeniedException extends AppException {
  const PermissionDeniedException({
    required super.message,
    super.code = ErrorCode.forbidden,
    super.details,
    super.cause,
  });
}

/// Thrown when a requested resource (QR, table, product, order, restaurant) is not found.
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = ErrorCode.unknown,
    super.details,
    super.cause,
  });
}

/// Thrown when a business logic violation occurs (ordering paused, invalid status transition, etc.).
class DomainException extends AppException {
  const DomainException({
    required super.message,
    required super.code,
    super.details,
    super.cause,
  });
}

/// Thrown when network transport fails, connection times out, or host is unreachable.
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code = ErrorCode.networkError,
    super.details,
    super.cause,
  });
}

/// Thrown when a state conflict or concurrency collision occurs (e.g. concurrent order status update).
class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.code = ErrorCode.conflict,
    super.details,
    super.cause,
  });
}

/// Thrown when input data fails client-side or pre-validation rules.
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = ErrorCode.unknown,
    super.details,
    super.cause,
  });
}

/// Thrown when unexpected server errors occur (5xx or unhandled SQL exception).
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code = ErrorCode.serverError,
    super.details,
    super.cause,
  });
}

/// Thrown when data fails to deserialize or has an invalid schema shape.
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code = ErrorCode.parseError,
    super.details,
    super.cause,
  });
}
