import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/core/services/storage/device_storage_service.dart';
import 'package:payhive/features/auth/data/datasources/auth_datasource.dart';
import 'package:payhive/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:payhive/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:payhive/features/auth/data/models/auth_api_model.dart';
import 'package:payhive/features/auth/data/models/auth_hive_model.dart';
import 'package:payhive/features/auth/domain/entities/auth_entity.dart';
import 'package:payhive/features/auth/domain/repositories/auth_repository.dart';

//provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authDatasource = ref.read(authLocalDatasourceProvider);
  final authRemoteDatasource = ref.read(authRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  final deviceStorageService = ref.read(deviceStorageServiceProvider);
  return AuthRepository(
    authDatasource: authDatasource,
    authRemoteDatasource: authRemoteDatasource,
    networkInfo: networkInfo,
    deviceStorageService: deviceStorageService,
  );
});

class AuthRepository implements IAuthRepository {
  final IAuthLocalDatasource _authDatasource;
  final IAuthRemoteDatasource _authRemoteDatasource;
  final NetworkInfo _networkInfo;
  final DeviceStorageService _deviceStorageService;

  AuthRepository({
    required IAuthLocalDatasource authDatasource,
    required IAuthRemoteDatasource authRemoteDatasource,
    required NetworkInfo networkInfo,
    required DeviceStorageService deviceStorageService,
  }) : _authDatasource = authDatasource,
       _authRemoteDatasource = authRemoteDatasource,
       _networkInfo = networkInfo,
       _deviceStorageService = deviceStorageService;

  @override
  Future<Either<Failure, AuthEntity>> getUserByPhoneNumber(
    String phoneNumber,
  ) async {
    try {
      final result = await _authDatasource.getUserByPhoneNumber(phoneNumber);

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
      final result = await _authDatasource.isPhoneNumberExists(phoneNumber);
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
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = await _authRemoteDatasource.login(
          phoneNumber,
          password,
        );
        if (apiModel != null) {
          final entity = apiModel.toEntity();
          return Right(entity);
        }
        return const Left(ApiFalilure(message: "Invalid credientials"));
      } on DioException catch (e) {
        final data = e.response?.data;
        final deviceId =
            data is Map && data['deviceId'] is String
                ? data['deviceId'] as String
                : null;
        if (deviceId != null && deviceId.trim().isNotEmpty) {
          await _deviceStorageService.saveDeviceId(deviceId);
        }
        return Left(
          ApiFalilure(
            message: e.response?.data['message'] ?? 'Login Failed',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    } else {
      try {
        final model = await _authDatasource.login(phoneNumber, password);
        if (model != null) {
          final entity = model.toEntity();
          return Right(entity);
        }
        return const Left(
          LocalDatabaseFailure(message: "Invalid phonenumber or password"),
        );
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> register(AuthEntity entity) async {
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = AuthApiModel.fromEntity(entity);
        await _authRemoteDatasource.register(apiModel);
        return const Right(true);
      } on DioException catch (e) {
        return Left(
          ApiFalilure(
            message: e.response?.data['message'] ?? 'Registration Failed from api',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      try {
        final existingUser = await _authDatasource.isPhoneNumberExists(
          entity.phoneNumber,
        );
        if (existingUser) {
          return const Left(
            LocalDatabaseFailure(message: "Phone Number already registered"),
          );
        }
        final authModel = AuthHiveModel(
          fullName: entity.fullName,
          phoneNumber: entity.phoneNumber,
          email: entity.email,
          password: entity.password,
        );
        await _authDatasource.register(authModel);
        return const Right(true);
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

   @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await _authDatasource.logout();
      if (result) {
        return const Right(true);
      }
      return const Left(LocalDatabaseFailure(message: "Failed to logout"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> requestPasswordReset(String email) async {
    if (await _networkInfo.isConnected) {
      try {
        final token = await _authRemoteDatasource.requestPasswordReset(email);
        if (token != null && token.isNotEmpty) {
          return Right(token);
        }
        return const Left(
          ApiFalilure(message: "Failed to send password reset email"),
        );
      } on DioException catch (e) {
        return Left(
          ApiFalilure(
            message:
                e.response?.data['message'] ?? 'Failed to send reset email',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final success = await _authRemoteDatasource.resetPassword(
          token: token,
          newPassword: newPassword,
        );
        if (success) {
          return const Right(true);
        }
        return const Left(ApiFalilure(message: "Password reset failed"));
      } on DioException catch (e) {
        return Left(
          ApiFalilure(
            message: e.response?.data['message'] ?? 'Password reset failed',
            statusCode: e.response?.statusCode,
          ),
        );
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
