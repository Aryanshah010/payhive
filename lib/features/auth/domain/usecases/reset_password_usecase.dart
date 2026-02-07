import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/auth/data/repositories/auth_repository.dart';
import 'package:payhive/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordParams extends Equatable {
  final String token;
  final String newPassword;

  const ResetPasswordParams({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [token, newPassword];
}

final resetPasswordUsecaseProvider = Provider<ResetPasswordUsecase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return ResetPasswordUsecase(authRepository: authRepository);
});

class ResetPasswordUsecase
    implements UsecaseWithParams<bool, ResetPasswordParams> {
  final IAuthRepository _authRepository;

  ResetPasswordUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call(ResetPasswordParams params) {
    return _authRepository.resetPassword(
      token: params.token,
      newPassword: params.newPassword,
    );
  }
}
