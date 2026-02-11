import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/devices/domain/entity/device_entity.dart';
import 'package:payhive/features/devices/domain/repositories/device_repository.dart';
import 'package:payhive/features/devices/data/repositories/device_repository.dart';

final blockDeviceUsecaseProvider = Provider<BlockDeviceUsecase>((ref) {
  final repository = ref.read(deviceRepositoryProvider);
  return BlockDeviceUsecase(repository: repository);
});

class BlockDeviceParams extends Equatable {
  final String deviceId;

  const BlockDeviceParams({required this.deviceId});

  @override
  List<Object?> get props => [deviceId];
}

class BlockDeviceUsecase
    implements UsecaseWithParams<DeviceEntity, BlockDeviceParams> {
  final IDeviceRepository _repository;

  BlockDeviceUsecase({required IDeviceRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, DeviceEntity>> call(BlockDeviceParams params) {
    return _repository.blockDevice(params.deviceId);
  }
}
