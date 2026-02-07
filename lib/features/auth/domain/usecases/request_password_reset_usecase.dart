import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/auth/data/repositories/auth_repository.dart';
import 'package:payhive/features/auth/domain/repositories/auth_repository.dart';

class RequestPasswordResetParams extends Equatable {
  final String email;

  const RequestPasswordResetParams({required this.email});

  @override
  List<Object?> get props => [email];
}

final requestPasswordResetUsecaseProvider = Provider<RequestPasswordResetUsecase>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    return RequestPasswordResetUsecase(authRepository: authRepository);
  },
);

class RequestPasswordResetUsecase
    implements UsecaseWithParams<String?, RequestPasswordResetParams> {
  final IAuthRepository _authRepository;

  RequestPasswordResetUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, String?>> call(
    RequestPasswordResetParams params,
  ) {
    return _authRepository.requestPasswordReset(params.email);
  }
}
