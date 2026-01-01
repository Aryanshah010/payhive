import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Either<Failure, bool>> registerUser(AuthEntity user);
  Future<Either<Failure, AuthEntity>> getUserByPhoneNumber(String phoneNumber);
  Future<Either<Failure, AuthEntity>> login(
    String phoneNumber,
    String password,
  );
  Future<Either<Failure, bool>> isPhoneNumberExists(String phoneNumber);
}
