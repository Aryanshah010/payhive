import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/devices/domain/entity/device_entity.dart';
import 'package:payhive/features/devices/domain/repositories/device_repository.dart';
import 'package:payhive/features/devices/data/repositories/device_repository.dart';

final allowDeviceUsecaseProvider = Provider<AllowDeviceUsecase>((ref) {
  final repository = ref.read(deviceRepositoryProvider);
  return AllowDeviceUsecase(repository: repository);
});

class AllowDeviceParams extends Equatable {
  final String deviceId;

  const AllowDeviceParams({required this.deviceId});

  @override
  List<Object?> get props => [deviceId];
}

class AllowDeviceUsecase
    implements UsecaseWithParams<DeviceEntity, AllowDeviceParams> {
  final IDeviceRepository _repository;

  AllowDeviceUsecase({required IDeviceRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, DeviceEntity>> call(AllowDeviceParams params) {
    return _repository.allowDevice(params.deviceId);
  }
}
