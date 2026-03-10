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

  bool _hasLoadedSuccessfully = false;
  Future<void>? _loadingFuture;

  @override
  ProfileState build() {
    _getProfileUsecase = ref.read(getProfileUsecaseProvider);
    _uploadPhotoUsecase = ref.read(uploadPhotoUsecaseProvider);
    return ProfileState.initial();
  }

  Future<void> ensureLoaded() async {
    await _loadProfile(force: false);
  }

  Future<void> loadProfile() async {
    await _loadProfile(force: true);
  }

  Future<void> refreshProfile() async {
    await _loadProfile(force: true);
  }

  Future<void> _loadProfile({required bool force}) async {
    if (!force && _hasLoadedSuccessfully) return;

    final inFlight = _loadingFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final nextLoad = _performLoadProfile();
    _loadingFuture = nextLoad;
    try {
      await nextLoad;
    } finally {
      if (identical(_loadingFuture, nextLoad)) {
        _loadingFuture = null;
      }
    }
  }

  Future<void> _performLoadProfile() async {
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
        _hasLoadedSuccessfully = true;
        state = state.copyWith(
          status: ProfileStatus.loaded,
          fullName: profile.fullName,
          phoneNumber: profile.phoneNumber,
          email: profile.email,
          imageUrl: profile.imageUrl,
          balance: profile.balance,
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

        await refreshProfile();
      },
    );
  }
}
