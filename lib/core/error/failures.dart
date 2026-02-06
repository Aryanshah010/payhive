import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

//Local Database Failure
class LocalDatabaseFailure extends Failure {
  const LocalDatabaseFailure({
    String message = 'Local database operation failed,',
  }) : super(message);
}

//API Failure with status code
class ApiFalilure extends Failure {
  final int? statusCode;

  const ApiFalilure({required String message, this.statusCode})
    : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

//Network failure
class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection failed.'})
    : super(message);
}

//Validation failure for client-side checks
class ValidationFailure extends Failure {
  const ValidationFailure({required String message}) : super(message);
}

//PIN lockout failure (HTTP 423)
class PinLockoutFailure extends Failure {
  final int remainingMs;
  final int? statusCode;

  const PinLockoutFailure({
    required String message,
    required this.remainingMs,
    this.statusCode,
  }) : super(message);

  @override
  List<Object?> get props => [message, remainingMs, statusCode];
}
