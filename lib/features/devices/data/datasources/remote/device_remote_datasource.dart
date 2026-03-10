import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/devices/data/datasources/device_datasource.dart';
import 'package:payhive/features/devices/data/models/device_api_model.dart';

final deviceRemoteDatasourceProvider = Provider<IDeviceRemoteDatasource>((ref) {
  return DeviceRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class DeviceRemoteDatasource implements IDeviceRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  DeviceRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  @override
  Future<List<DeviceApiModel>> listDevices({String? status}) async {
    final token = _tokenService.getToken();
    final response = await _apiClient.get(
      ApiEndpoints.devices,
      queryParameters: status != null ? {'status': status} : null,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(DeviceApiModel.fromJson)
          .toList();
    }

    return [];
  }

  @override
  Future<List<DeviceApiModel>> listPendingDevices() async {
    final token = _tokenService.getToken();
    final response = await _apiClient.get(
      ApiEndpoints.devicesPending,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(DeviceApiModel.fromJson)
          .toList();
    }
    return [];
  }

  @override
  Future<DeviceApiModel> allowDevice(String deviceId) async {
    final token = _tokenService.getToken();
    final response = await _apiClient.post(
      ApiEndpoints.deviceAllow(deviceId),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return DeviceApiModel.fromJson(data);
  }

  @override
  Future<DeviceApiModel> blockDevice(String deviceId) async {
    final token = _tokenService.getToken();
    final response = await _apiClient.post(
      ApiEndpoints.deviceBlock(deviceId),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return DeviceApiModel.fromJson(data);
  }
}
