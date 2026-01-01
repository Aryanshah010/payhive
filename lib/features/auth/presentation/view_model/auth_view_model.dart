import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/auth/domain/usecases/login_usecase.dart';
import 'package:payhive/features/auth/domain/usecases/register_usecase.dart';
import 'package:payhive/features/auth/presentation/state/auth_state.dart';

//provider
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  () => AuthViewModel(),
);

class AuthViewModel extends Notifier<AuthState> {
  late final RegisterUsecase _registerUsecase;
  late final LoginUsecase _loginUsecase;

  @override
  AuthState build() {
    _registerUsecase = ref.read(registerUsecaseProvider);
    _loginUsecase = ref.read(loginUsecaseProvider);

    return const AuthState();
  }

  Future<void> register({
    required String phoneNumber,
    String? authId,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final params = RegisterUsecaseParams(
      fullName: fullName,
      phoneNumber: phoneNumber,
      authId: authId,
      password: password,
    );
    final result = await _registerUsecase(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (isRegistered) {
        state = state.copyWith(status: AuthStatus.registered);
      },
    );
  }

  //login
  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final params = LoginUsecaseParams(
      phoneNumber: phoneNumber,
      password: password,
    );
    final result = await _loginUsecase(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (authEntity) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          authEntity: authEntity,
        );
      },
    );
  }
}
