import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:payhive/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:payhive/features/profile/presentation/state/update_profile_state.dart';

final updateProfileViewModelProvider =
    NotifierProvider<UpdateProfileViewModel, UpdateProfileState>(
      UpdateProfileViewModel.new,
    );

class UpdateProfileViewModel extends Notifier<UpdateProfileState> {
  late final GetProfileUsecase _getProfileUsecase;
  late final UpdateProfileUsecase _updateProfileUsecase;

  bool _hasLoaded = false;

  @override
  UpdateProfileState build() {
    _getProfileUsecase = ref.read(getProfileUsecaseProvider);
    _updateProfileUsecase = ref.read(updateProfileUsecaseProvider);

    if (!_hasLoaded) {
      _hasLoaded = true;
      Future.microtask(loadProfile);
    }

    return UpdateProfileState.initial();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(
      status: UpdateProfileStatus.loading,
      errorMessage: null,
      infoMessage: null,
    );

    final result = await _getProfileUsecase();
    result.fold(
      (failure) {
        state = state.copyWith(
          status: UpdateProfileStatus.error,
          errorMessage: failure.message,
        );
      },
      (profile) {
        state = state.copyWith(
          status: UpdateProfileStatus.loaded,
          fullName: profile.fullName,
          email: profile.email,
          phoneNumber: profile.phoneNumber,
          initialFullName: profile.fullName,
          initialEmail: profile.email,
          initialPhoneNumber: profile.phoneNumber,
          errorMessage: null,
          infoMessage: null,
        );
      },
    );
  }

  void setFullName(String value) {
    state = state.copyWith(
      fullName: value,
      errorMessage: null,
      infoMessage: null,
      status: state.status == UpdateProfileStatus.error
          ? UpdateProfileStatus.loaded
          : state.status,
    );
  }

  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      errorMessage: null,
      infoMessage: null,
      status: state.status == UpdateProfileStatus.error
          ? UpdateProfileStatus.loaded
          : state.status,
    );
  }

  Future<void> submit({
    required String password,
    required String confirmPassword,
  }) async {
    if (state.status == UpdateProfileStatus.submitting) return;

    final fullName = state.fullName.trim();
    final email = state.email.trim();
    final initialFullName = state.initialFullName.trim();
    final initialEmail = state.initialEmail.trim();

    final fullNameChanged =
        fullName.isNotEmpty && fullName != initialFullName;
    final emailChanged =
        email.isNotEmpty && email.toLowerCase() != initialEmail.toLowerCase();

    final trimmedPassword = password.trim();
    String? passwordToSend;
    if (trimmedPassword.isNotEmpty) {
      if (trimmedPassword != confirmPassword.trim()) {
        state = state.copyWith(
          status: UpdateProfileStatus.loaded,
          errorMessage: 'Passwords do not match.',
        );
        return;
      }
      passwordToSend = trimmedPassword;
    }

    if (!fullNameChanged && !emailChanged && passwordToSend == null) {
      state = state.copyWith(
        status: UpdateProfileStatus.loaded,
        infoMessage: 'No changes to update.',
      );
      return;
    }

    state = state.copyWith(
      status: UpdateProfileStatus.submitting,
      errorMessage: null,
      infoMessage: null,
    );

    final result = await _updateProfileUsecase(
      UpdateProfileParams(
        fullName: fullNameChanged ? fullName : null,
        email: emailChanged ? email : null,
        password: passwordToSend,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: UpdateProfileStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          status: UpdateProfileStatus.success,
          initialFullName: fullNameChanged ? fullName : state.initialFullName,
          initialEmail: emailChanged ? email : state.initialEmail,
          errorMessage: null,
        );
      },
    );
  }

  void clearMessages() {
    if (state.errorMessage == null && state.infoMessage == null) return;
    state = state.copyWith(errorMessage: null, infoMessage: null);
  }
}
