import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/profile/data/repositories/profile_repository.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';

final uploadPhotoUsecaseProvider = Provider<UploadPhotoUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UploadPhotoUsecase(repository: repository);
});

class UploadPhotoUsecase implements UsecaseWithParams<String, File> {
  final IProfileRepository _repository;
  UploadPhotoUsecase({required IProfileRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, String>> call(File params) {
    return _repository.uploadProfileImage(params);
  }
}
