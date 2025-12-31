import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/auth/data/datasources/auth_datasource.dart';
import 'package:payhive/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:payhive/features/auth/data/models/auth_hive_model.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';
import 'package:payhive/features/auth/domain/repositories/auth_repository.dart';

//provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(authDataSource: ref.read(authLocalDatasourceProvider));
});

class AuthRepository implements IAuthRepository {
  final IAuthDataSource _authDataSource;

  AuthRepository({required IAuthDataSource authDataSource})
    : _authDataSource = authDataSource;

  @override
  Future<Either<Failure, AuthEntity>> getUserByPhoneNumber(
    String phoneNumber,
  ) async {
    try {
      final result = await _authDataSource.getUserByPhoneNumber(phoneNumber);

      if (result != null) {
        return Right(result.toEntity());
      }

      return Left(LocalDatabaseFailure(message: "User not found"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isPhoneNumberExists(String phoneNumber) async {
    try {
      final result = await _authDataSource.isPhoneNumberExists(phoneNumber);
      return Right(result);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final result = await _authDataSource.login(phoneNumber, password);
      if (result != null) {
        final entity = result.toEntity();
        return Right(entity);
      }
      return Left(
        LocalDatabaseFailure(message: "Invalid phone number or password"),
      );
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> registerUser(AuthEntity entity) async {
    try {
      final model = AuthHiveModel.fromEntity(entity);
      final result = await _authDataSource.registerUser(model);
      if (result) {
        return Right(true);
      }
      return Left(LocalDatabaseFailure(message: "Registration failed"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}
