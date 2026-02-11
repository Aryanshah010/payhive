import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:payhive/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:payhive/features/auth/presentation/state/password_reset_state.dart';

final passwordResetViewModelProvider =
    NotifierProvider<PasswordResetViewModel, PasswordResetState>(
      () => PasswordResetViewModel(),
    );

class PasswordResetViewModel extends Notifier<PasswordResetState> {
  late final RequestPasswordResetUsecase _requestPasswordResetUsecase;
  late final ResetPasswordUsecase _resetPasswordUsecase;

  @override
  PasswordResetState build() {
    _requestPasswordResetUsecase = ref.read(requestPasswordResetUsecaseProvider);
    _resetPasswordUsecase = ref.read(resetPasswordUsecaseProvider);
    return const PasswordResetState();
  }

  void clearStatus() {
    state = const PasswordResetState();
  }

  Future<void> requestPasswordReset({required String email}) async {
    state = state.copyWith(
      status: PasswordResetStatus.loading,
      errorMessage: null,
      token: null,
    );

    final params = RequestPasswordResetParams(email: email);
    final result = await _requestPasswordResetUsecase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PasswordResetStatus.error,
          errorMessage: failure.message,
        );
      },
      (token) {
        state = state.copyWith(
          status: PasswordResetStatus.emailSent,
          token: token,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(
      status: PasswordResetStatus.loading,
      errorMessage: null,
    );

    final params = ResetPasswordParams(token: token, newPassword: newPassword);
    final result = await _resetPasswordUsecase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PasswordResetStatus.error,
          errorMessage: failure.message,
        );
      },
      (success) {
        state = state.copyWith(
          status: PasswordResetStatus.resetSuccess,
          errorMessage: null,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
