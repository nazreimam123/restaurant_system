import 'package:meta/meta.dart';

@immutable
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const ApiError({
    required this.code,
    required this.message,
    this.details = const {},
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'An unexpected error occurred.',
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'details': details,
  };

  @override
  String toString() =>
      'ApiError(code: $code, message: $message, details: $details)';
}
