import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/auth/data/datasources/auth_datasource.dart';
import 'package:payhive/features/auth/data/models/auth_api_model.dart';

final authRemoteDatasourceProvider = Provider<IAuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDatasource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;
  final TokenService _tokenService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService,
       _userSessionService = userSessionService;

  @override
  Future<AuthApiModel?> login(String phoneNumber, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.authLogin,
      data: {'phoneNumber': phoneNumber, 'password': password},
    );
    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final user = AuthApiModel.fromJson(data);

      await _userSessionService.saveUserSession(
        userId: user.id!,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
      );
      final token = response.data['token'];
      await _tokenService.saveToken(token);
      return user;
    }
    return null;
  }

  @override
  Future<AuthApiModel> register(AuthApiModel model) async {
    final response = await _apiClient.post(
      ApiEndpoints.authRegister,
      data: model.toJson(),
    );
    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final registerUser = AuthApiModel.fromJson(data);
      return registerUser;
    }

    return model;
  }

  @override
  Future<String?> requestPasswordReset(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.authRequestPasswordReset,
      data: {'email': email},
    );

    if (response.data['success'] == true) {
      return response.data['token'] as String?;
    }

    return null;
  }

  @override
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final encodedToken = Uri.encodeComponent(token);
    final response = await _apiClient.post(
      ApiEndpoints.authResetPassword(encodedToken),
      data: {'newPassword': newPassword},
    );

    return response.data['success'] == true;
  }
}
