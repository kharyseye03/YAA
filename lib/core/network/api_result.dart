/// A sealed result type for API calls.
/// Forces callers to handle both success and failure cases.
sealed class ApiResult<T> {
  const ApiResult();

  /// Creates a successful result.
  const factory ApiResult.success(T data) = ApiSuccess<T>;

  /// Creates a failure result.
  const factory ApiResult.failure(String message, {int? statusCode}) =
      ApiFailure<T>;

  /// Pattern match on the result.
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final message, :final statusCode) =>
        failure(message, statusCode),
    };
  }

  /// Returns true if the result is a success.
  bool get isSuccess => this is ApiSuccess<T>;

  /// Returns true if the result is a failure.
  bool get isFailure => this is ApiFailure<T>;

  /// Returns the data if success, null otherwise.
  T? get dataOrNull => switch (this) {
    ApiSuccess<T>(:final data) => data,
    _ => null,
  };
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

final class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  const ApiFailure(this.message, {this.statusCode});
}
