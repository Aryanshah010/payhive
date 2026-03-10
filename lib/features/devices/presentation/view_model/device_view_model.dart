import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/devices/domain/usecases/allow_device_usecase.dart';
import 'package:payhive/features/devices/domain/usecases/block_device_usecase.dart';
import 'package:payhive/features/devices/domain/usecases/get_devices_usecase.dart';
import 'package:payhive/features/devices/presentation/state/device_state.dart';

final deviceViewModelProvider =
    NotifierProvider<DeviceViewModel, DeviceState>(() => DeviceViewModel());

class DeviceViewModel extends Notifier<DeviceState> {
  late final GetDevicesUsecase _getDevicesUsecase;
  late final AllowDeviceUsecase _allowDeviceUsecase;
  late final BlockDeviceUsecase _blockDeviceUsecase;

  @override
  DeviceState build() {
    _getDevicesUsecase = ref.read(getDevicesUsecaseProvider);
    _allowDeviceUsecase = ref.read(allowDeviceUsecaseProvider);
    _blockDeviceUsecase = ref.read(blockDeviceUsecaseProvider);
    return DeviceState.initial();
  }

  Future<void> loadDevices({String? status}) async {
    state = state.copyWith(
      status: DeviceViewStatus.loading,
      errorMessage: null,
      actionDeviceId: null,
    );

    final result = await _getDevicesUsecase(
      GetDevicesParams(status: status),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: DeviceViewStatus.error,
          errorMessage: failure.message,
        );
      },
      (devices) {
        state = state.copyWith(
          status: DeviceViewStatus.loaded,
          devices: devices,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> allowDevice(String deviceId) async {
    if (state.status == DeviceViewStatus.actionLoading) return;

    state = state.copyWith(
      status: DeviceViewStatus.actionLoading,
      actionDeviceId: deviceId,
      errorMessage: null,
    );

    final result = await _allowDeviceUsecase(
      AllowDeviceParams(deviceId: deviceId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: DeviceViewStatus.error,
          errorMessage: failure.message,
          actionDeviceId: null,
        );
      },
      (updated) {
        final updatedList = state.devices
            .map((device) => device.deviceId == deviceId ? updated : device)
            .toList();
        state = state.copyWith(
          status: DeviceViewStatus.loaded,
          devices: updatedList,
          errorMessage: null,
          actionDeviceId: null,
        );
      },
    );
  }

  Future<void> blockDevice(String deviceId) async {
    if (state.status == DeviceViewStatus.actionLoading) return;

    state = state.copyWith(
      status: DeviceViewStatus.actionLoading,
      actionDeviceId: deviceId,
      errorMessage: null,
    );

    final result = await _blockDeviceUsecase(
      BlockDeviceParams(deviceId: deviceId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: DeviceViewStatus.error,
          errorMessage: failure.message,
          actionDeviceId: null,
        );
      },
      (updated) {
        final updatedList = state.devices
            .map((device) => device.deviceId == deviceId ? updated : device)
            .toList();
        state = state.copyWith(
          status: DeviceViewStatus.loaded,
          devices: updatedList,
          errorMessage: null,
          actionDeviceId: null,
        );
      },
    );
  }

  void clearError() {
    if (state.status != DeviceViewStatus.error) return;
    state = state.copyWith(
      status: DeviceViewStatus.loaded,
      errorMessage: null,
      actionDeviceId: null,
    );
  }
}
