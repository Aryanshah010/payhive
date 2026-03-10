import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/devices/domain/entity/device_entity.dart';
import 'package:payhive/features/devices/domain/repositories/device_repository.dart';
import 'package:payhive/features/devices/data/repositories/device_repository.dart';

final getDevicesUsecaseProvider = Provider<GetDevicesUsecase>((ref) {
  final repository = ref.read(deviceRepositoryProvider);
  return GetDevicesUsecase(repository: repository);
});

class GetDevicesParams extends Equatable {
  final String? status;

  const GetDevicesParams({this.status});

  @override
  List<Object?> get props => [status];
}

class GetDevicesUsecase
    implements UsecaseWithParams<List<DeviceEntity>, GetDevicesParams> {
  final IDeviceRepository _repository;

  GetDevicesUsecase({required IDeviceRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, List<DeviceEntity>>> call(GetDevicesParams params) {
    return _repository.getDevices(status: params.status);
  }
}
