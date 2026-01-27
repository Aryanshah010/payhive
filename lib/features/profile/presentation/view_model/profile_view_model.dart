import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/profile/domain/usecase/upload_photo_usecase.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';

// Provider
final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(() => ProfileViewModel());

class ProfileViewModel extends Notifier<ProfileState> {
  late final UploadPhotoUsecase _uploadPhotoUsecase;

  @override
  ProfileState build() {
    _uploadPhotoUsecase = ref.read(uploadPhotoUsecaseProvider);
    return ProfileState.initial();
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
      (imageUrl) {
        state = state.copyWith(
          status: ProfileStatus.updated,
          imageUrl: imageUrl,
        );
      },
    );
  }
}
