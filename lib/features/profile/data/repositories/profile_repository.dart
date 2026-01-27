import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/profile/data/datasources/profile_datasource.dart';
import 'package:payhive/features/profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:payhive/features/profile/domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final profileRemoteDatasource = ref.read(profileRemoteDatasourceProvider);
  return ProfileRepository(
    networkInfo: networkInfo,
    profileRemoteDatasource: profileRemoteDatasource,
  );
});

class ProfileRepository implements IProfileRepository {
  final NetworkInfo _networkInfo;
  final IProfileRemoteDataSource _profileRemoteDatasource;

  ProfileRepository({
    required NetworkInfo networkInfo,
    required IProfileRemoteDataSource profileRemoteDatasource,
  }) : _networkInfo = networkInfo,
       _profileRemoteDatasource = profileRemoteDatasource;

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
}
