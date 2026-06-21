// lib/core/network/api_result.dart

sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiError<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  const ApiError(this.message, {this.statusCode});
}

// Extension for easy handling
extension ApiResultX<T> on ApiResult<T> {
  bool get isSuccess => this is ApiSuccess<T>;
  bool get isError => this is ApiError<T>;

  T? get data => switch (this) {
        ApiSuccess<T> s => s.data,
        ApiError<T> _ => null,
      };

  String? get errorMessage => switch (this) {
        ApiSuccess<T> _ => null,
        ApiError<T> e => e.message,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) error,
  }) =>
      switch (this) {
        ApiSuccess<T> s => success(s.data),
        ApiError<T> e => error(e.message, e.statusCode),
      };
}
