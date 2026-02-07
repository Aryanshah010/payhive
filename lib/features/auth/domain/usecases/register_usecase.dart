import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/auth/data/repositories/auth_repository.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';
import 'package:payhive/features/auth/domain/repositories/auth_repository.dart';

class RegisterUsecaseParams extends Equatable {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String password;

  const RegisterUsecaseParams({
    required this.fullName,
    required this.password,
    required this.phoneNumber,
    required this.email,
  });

  @override
  List<Object?> get props => [fullName, phoneNumber, email, password];
}

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return RegisterUsecase(authRepository: authRepository);
});

class RegisterUsecase
    implements UsecaseWithParams<bool, RegisterUsecaseParams> {
  final IAuthRepository _authRepository;
  RegisterUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call(RegisterUsecaseParams params) {
    final entity = AuthEntity(
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
      email: params.email,
      password: params.password,
    );
    return _authRepository.register(entity);
  }
}
