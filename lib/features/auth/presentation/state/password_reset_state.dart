import 'package:equatable/equatable.dart';

enum PasswordResetStatus { initial, loading, emailSent, resetSuccess, error }

class PasswordResetState extends Equatable {
  final PasswordResetStatus status;
  final String? token;
  final String? errorMessage;

  const PasswordResetState({
    this.status = PasswordResetStatus.initial,
    this.token,
    this.errorMessage,
  });

  static const _unset = Object();

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    Object? token = _unset,
    Object? errorMessage = _unset,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      token: token == _unset ? this.token : token as String?,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, token, errorMessage];
}
