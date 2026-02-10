import 'package:equatable/equatable.dart';
import 'failures.dart';

sealed class Result<T> extends Equatable {
  const Result();
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
