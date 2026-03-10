import 'package:payhive/features/devices/data/models/device_api_model.dart';

abstract interface class IDeviceRemoteDatasource {
  Future<List<DeviceApiModel>> listDevices({String? status});
  Future<List<DeviceApiModel>> listPendingDevices();
  Future<DeviceApiModel> allowDevice(String deviceId);
  Future<DeviceApiModel> blockDevice(String deviceId);
}
