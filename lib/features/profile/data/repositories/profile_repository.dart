import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/core/services/hive/hive_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/profile/data/datasources/profile_datasource.dart';
import 'package:payhive/features/profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:payhive/features/profile/data/models/profile_hive_model.dart';
import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final profileRemoteDatasource = ref.read(profileRemoteDatasourceProvider);
  final hiveService = ref.read(hiveServiceProvider);
  final userSessionService = ref.read(userSessionServiceProvider);
  return ProfileRepository(
    networkInfo: networkInfo,
    profileRemoteDatasource: profileRemoteDatasource,
    hiveService: hiveService,
    userSessionService: userSessionService,
  );
});

class ProfileRepository implements IProfileRepository {
  final INetworkInfo _networkInfo;
  final IProfileRemoteDataSource _profileRemoteDatasource;
  final HiveService _hiveService;
  final UserSessionService _userSessionService;

  ProfileRepository({
    required INetworkInfo networkInfo,
    required IProfileRemoteDataSource profileRemoteDatasource,
    required HiveService hiveService,
    required UserSessionService userSessionService,
  }) : _networkInfo = networkInfo,
       _profileRemoteDatasource = profileRemoteDatasource,
       _hiveService = hiveService,
       _userSessionService = userSessionService;

  @override
  Future<Either<Failure, String>> uploadProfileImage(File image) async {
    if (await _networkInfo.isConnected) {
      try {
        final fileName = await _profileRemoteDatasource.uploadProfileImage(
          image,
        );
        return Right(fileName);
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return Left(ApiFalilure(message: "No Internet connection"));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    final userId = _userSessionService.getUserId();
    final hasUserId = userId != null && userId.trim().isNotEmpty;

    if (await _networkInfo.isConnected) {
      try {
        final profileApiModel = await _profileRemoteDatasource.getProfile();

        final profileEntity = profileApiModel.toEntity();
        await _cacheProfile(profileEntity);

        return Right(profileEntity);
      } catch (e) {
        final cachedProfile = await _getCachedProfile();
        if (cachedProfile != null) {
          return Right(cachedProfile);
        }
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      final cachedProfile = await _getCachedProfile();
      if (cachedProfile != null) {
        return Right(cachedProfile);
      }
      if (!hasUserId) {
        return const Left(ApiFalilure(message: "No active user session"));
      }
      return const Left(ApiFalilure(message: "No Internet connection"));
    }
  }

  @override
  Future<Either<Failure, bool>> setPin({
    required String newPin,
    String? oldPin,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _profileRemoteDatasource.setPin(newPin: newPin, oldPin: oldPin);
        return const Right(true);
      } on DioException catch (e) {
        final data = e.response?.data;
        final message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'PIN update failed';
        return Left(
          ApiFalilure(message: message, statusCode: e.response?.statusCode),
        );
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return Left(ApiFalilure(message: "No Internet connection"));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin({required String pin}) async {
    if (await _networkInfo.isConnected) {
      try {
        await _profileRemoteDatasource.verifyPin(pin);
        return const Right(true);
      } on DioException catch (e) {
        final data = e.response?.data;
        final message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'PIN verification failed';
        return Left(
          ApiFalilure(message: message, statusCode: e.response?.statusCode),
        );
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return Left(ApiFalilure(message: "No Internet connection"));
    }
  }

  Future<void> _cacheProfile(ProfileEntity profile) async {
    final userId = profile.id ?? _userSessionService.getUserId();
    if (userId == null || userId.trim().isEmpty) return;

    final cacheModel = ProfileHiveModel(
      userId: userId,
      fullName: profile.fullName,
      phoneNumber: profile.phoneNumber,
      email: profile.email,
      imageUrl: profile.imageUrl,
      balance: profile.balance,
      updatedAt: DateTime.now(),
    );

    await _hiveService.saveProfile(cacheModel);
  }

  Future<ProfileEntity?> _getCachedProfile() async {
    final userId = _userSessionService.getUserId();
    if (userId == null || userId.trim().isEmpty) return null;

    final cache = await _hiveService.getProfileByUserId(userId);
    return cache?.toEntity();
  }
}
