import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:payhive/features/profile/domain/usecases/upload_photo_usecase.dart';

import 'package:payhive/features/profile/presentation/state/profile_state.dart';

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(() => ProfileViewModel());

class ProfileViewModel extends Notifier<ProfileState> {
  late final GetProfileUsecase _getProfileUsecase;
  late final UploadPhotoUsecase _uploadPhotoUsecase;

  bool _hasLoaded = false;

  @override
  ProfileState build() {
    _getProfileUsecase = ref.read(getProfileUsecaseProvider);
    _uploadPhotoUsecase = ref.read(uploadPhotoUsecaseProvider);

    if (!_hasLoaded) {
      _hasLoaded = true;
      Future.microtask(loadProfile);
    }

    return ProfileState.initial();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(status: ProfileStatus.loading, errorMessage: null);

    final result = await _getProfileUsecase();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        );
      },
      (profile) {
        state = state.copyWith(
          status: ProfileStatus.loaded,
          fullName: profile.fullName,
          phoneNumber: profile.phoneNumber,
          imageUrl: profile.imageUrl,
          hasPin: profile.hasPin,
        );
      },
    );
  }

  Future<void> uploadImage(File photo) async {
    state = state.copyWith(status: ProfileStatus.loading, errorMessage: null);

    final result = await _uploadPhotoUsecase(photo);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        );
      },
      (imageUrl) async {
        state = state.copyWith(
          status: ProfileStatus.updated,
          imageUrl: imageUrl,
        );

        await loadProfile();
      },
    );
  }
}
