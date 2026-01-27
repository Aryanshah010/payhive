import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/profile/data/repositories/profile_repository.dart';
import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';

final getProfileUsecaseProvider = Provider<GetProfileUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return GetProfileUsecase(repository: repository);
});

class GetProfileUsecase implements UsecaseWithoutParams<ProfileEntity> {
  final IProfileRepository _repository;

  GetProfileUsecase({required IProfileRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, ProfileEntity>> call() {
    return _repository.getProfile();
  }
}
