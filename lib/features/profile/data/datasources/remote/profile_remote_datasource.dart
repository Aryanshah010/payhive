import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/profile/data/datasources/profile_datasource.dart';
import 'package:payhive/features/profile/data/models/profile_api_model.dart';

final profileRemoteDatasourceProvider = Provider<IProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class ProfileRemoteDataSource implements IProfileRemoteDataSource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  ProfileRemoteDataSource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  @override
  Future<String> uploadProfileImage(File image) async {
    final fileName = image.path.split('/').last;
    final formData = FormData.fromMap({
      'profilePicture': await MultipartFile.fromFile(
        image.path,
        filename: fileName,
      ),
    });

    final token = _tokenService.getToken();
    final response = await _apiClient.uploadFile(
      ApiEndpoints.profilePicture,
      formData: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data['data']['imageUrl'] as String;
  }

  @override
  Future<ProfileApiModel> getProfile() async {
    final token = _tokenService.getToken();

    final response = await _apiClient.get(
      ApiEndpoints.profile,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data['data'] as Map<String, dynamic>;

    return ProfileApiModel.fromJson(data);
  }

  @override
  Future<void> setPin({required String newPin, String? oldPin}) async {
    final token = _tokenService.getToken();
    await _apiClient.put(
      ApiEndpoints.profilePin,
      data: {
        'pin': newPin,
        if (oldPin != null && oldPin.trim().isNotEmpty) 'oldPin': oldPin.trim(),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
