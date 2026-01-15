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
  final AuthEntity? user;
  final AuthEntity? authEntity;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
    this.authEntity,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    AuthEntity? user,
    AuthEntity? authEntity,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
      authEntity: authEntity ?? this.authEntity,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage,user, authEntity];
}
