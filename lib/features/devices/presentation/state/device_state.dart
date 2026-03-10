import 'package:equatable/equatable.dart';
import 'package:payhive/features/devices/domain/entity/device_entity.dart';

enum DeviceViewStatus { initial, loading, loaded, actionLoading, error }

class DeviceState extends Equatable {
  final DeviceViewStatus status;
  final List<DeviceEntity> devices;
  final String? errorMessage;
  final String? actionDeviceId;

  const DeviceState({
    required this.status,
    required this.devices,
    this.errorMessage,
    this.actionDeviceId,
  });

  factory DeviceState.initial() {
    return const DeviceState(
      status: DeviceViewStatus.initial,
      devices: [],
      errorMessage: null,
      actionDeviceId: null,
    );
  }

  DeviceState copyWith({
    DeviceViewStatus? status,
    List<DeviceEntity>? devices,
    String? errorMessage,
    String? actionDeviceId,
  }) {
    return DeviceState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      errorMessage: errorMessage,
      actionDeviceId: actionDeviceId,
    );
  }

  @override
  List<Object?> get props => [status, devices, errorMessage, actionDeviceId];
}
