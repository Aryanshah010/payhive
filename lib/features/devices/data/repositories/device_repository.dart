import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/devices/data/datasources/device_datasource.dart';
import 'package:payhive/features/devices/data/datasources/remote/device_remote_datasource.dart';
import 'package:payhive/features/devices/domain/entity/device_entity.dart';
import 'package:payhive/features/devices/domain/repositories/device_repository.dart';

final deviceRepositoryProvider = Provider<IDeviceRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(deviceRemoteDatasourceProvider);
  return DeviceRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class DeviceRepository implements IDeviceRepository {
  final NetworkInfo _networkInfo;
  final IDeviceRemoteDatasource _remoteDatasource;

  DeviceRepository({
    required NetworkInfo networkInfo,
    required IDeviceRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<DeviceEntity>>> getDevices({
    String? status,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final devices = await _remoteDatasource.listDevices(status: status);
        return Right(devices.map((e) => e.toEntity()).toList());
      } on DioException catch (e) {
        final data = e.response?.data;
        final message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to load devices';
        return Left(ApiFalilure(message: message));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return Left(ApiFalilure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, DeviceEntity>> allowDevice(String deviceId) async {
    if (await _networkInfo.isConnected) {
      try {
        final device = await _remoteDatasource.allowDevice(deviceId);
        return Right(device.toEntity());
      } on DioException catch (e) {
        final data = e.response?.data;
        final message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to allow device';
        return Left(ApiFalilure(message: message));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return Left(ApiFalilure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, DeviceEntity>> blockDevice(String deviceId) async {
    if (await _networkInfo.isConnected) {
      try {
        final device = await _remoteDatasource.blockDevice(deviceId);
        return Right(device.toEntity());
      } on DioException catch (e) {
        final data = e.response?.data;
        final message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to block device';
        return Left(ApiFalilure(message: message));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    } else {
      return Left(ApiFalilure(message: 'No Internet connection'));
    }
  }
}
