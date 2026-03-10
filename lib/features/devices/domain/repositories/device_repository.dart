import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/devices/domain/entity/device_entity.dart';

abstract interface class IDeviceRepository {
  Future<Either<Failure, List<DeviceEntity>>> getDevices({String? status});
  Future<Either<Failure, DeviceEntity>> allowDevice(String deviceId);
  Future<Either<Failure, DeviceEntity>> blockDevice(String deviceId);
}
