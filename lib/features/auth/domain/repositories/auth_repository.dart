import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Either<Failure, bool>> register(AuthEntity entity);
  Future<Either<Failure, AuthEntity>> getUserByPhoneNumber(String phoneNumber);
  Future<Either<Failure, AuthEntity>> login(
    String phoneNumber,
    String password,
  );
  Future<Either<Failure, bool>> isPhoneNumberExists(String phoneNumber);
  Future<Either<Failure, bool>> logout();
  Future<Either<Failure, String?>> requestPasswordReset(String email);
  Future<Either<Failure, bool>> resetPassword({
    required String token,
    required String newPassword,
  });
}
