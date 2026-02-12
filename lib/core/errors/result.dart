import 'package:equatable/equatable.dart';
import 'failures.dart';

sealed class Result<T> extends Equatable {
  const Result();

  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else if (this is FailureResult<T>) {
      return onFailure((this as FailureResult<T>).failure);
    } else {
      throw Exception('Unhandled Result type');
    }
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  @override
  List<Object?> get props => [data];
}

class FailureResult<T> extends Result<T> {
  final Failure failure;
  const FailureResult(this.failure);

  @override
  List<Object?> get props => [failure];
}
