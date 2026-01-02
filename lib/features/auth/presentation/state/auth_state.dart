import 'package:equatable/equatable.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  registered,
  error,
}


class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  final AuthEntity? authEntity;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.authEntity,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    AuthEntity? authEntity,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      authEntity: authEntity ?? this.authEntity,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, authEntity];
}
