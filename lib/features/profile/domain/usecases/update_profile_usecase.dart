import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/profile/data/repositories/profile_repository.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileParams extends Equatable {
  final String? fullName;
  final String? email;
  final String? password;

  const UpdateProfileParams({this.fullName, this.email, this.password});

  @override
  List<Object?> get props => [fullName, email, password];
}

final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UpdateProfileUsecase(repository: repository);
});

class UpdateProfileUsecase
    implements UsecaseWithParams<bool, UpdateProfileParams> {
  final IProfileRepository _repository;

  UpdateProfileUsecase({required IProfileRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(UpdateProfileParams params) {
    final fullName = params.fullName?.trim();
    final email = params.email?.trim();
    final password = params.password?.trim();

    if (fullName != null && fullName.isNotEmpty) {
      if (fullName.length < 3) {
        return Future.value(
          const Left(ValidationFailure(message: 'Name must be at least 3 characters long.')),
        );
      }
    }

    if (email != null && email.isNotEmpty) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        return Future.value(
          const Left(ValidationFailure(message: 'Please enter a valid email address.')),
        );
      }
    }

    if (password != null && password.isNotEmpty) {
      if (password.length < 6) {
        return Future.value(
          const Left(
            ValidationFailure(message: 'Password must be at least 6 characters long.'),
          ),
        );
      }
      if (!RegExp(r'[A-Z]').hasMatch(password)) {
        return Future.value(
          const Left(
            ValidationFailure(message: 'Password must contain at least one uppercase letter.'),
          ),
        );
      }
      if (!RegExp(r'[a-z]').hasMatch(password)) {
        return Future.value(
          const Left(
            ValidationFailure(message: 'Password must contain at least one lowercase letter.'),
          ),
        );
      }
      if (!RegExp(r'\d').hasMatch(password)) {
        return Future.value(
          const Left(
            ValidationFailure(message: 'Password must contain at least one number.'),
          ),
        );
      }
    }

    return _repository.updateProfile(
      fullName: fullName,
      email: email,
      password: password,
    );
  }
}
