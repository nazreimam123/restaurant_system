import 'package:meta/meta.dart';
import 'api_error.dart';

@immutable
class ApiResult<T> {
  final bool ok;
  final T? data;
  final ApiError? error;

  const ApiResult.success(T this.data) : ok = true, error = null;

  const ApiResult.failure(ApiError this.error) : ok = false, data = null;

  const ApiResult({required this.ok, this.data, this.error})
    : assert(
        (ok && data != null && error == null) ||
            (!ok && data == null && error != null),
      );

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final isOk = json['ok'] as bool? ?? false;
    if (isOk) {
      return ApiResult.success(fromJsonT(json['data']));
    } else {
      final errorJson = json['error'] is Map<String, dynamic>
          ? json['error'] as Map<String, dynamic>
          : <String, dynamic>{
              'code': 'UNKNOWN',
              'message': 'Unknown error',
              'details': const <String, dynamic>{},
            };
      return ApiResult.failure(ApiError.fromJson(errorJson));
    }
  }

  bool get isSuccess => ok && data != null;
  bool get isFailure => !ok && error != null;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiError error) failure,
  }) {
    if (ok && data != null) {
      return success(data as T);
    }
    return failure(
      error ?? const ApiError(code: 'UNKNOWN', message: 'Unknown failure'),
    );
  }
}
