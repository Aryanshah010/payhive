import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/notifications/data/datasources/notification_datasource.dart';
import 'package:payhive/features/notifications/data/models/notification_api_model.dart';

final notificationRemoteDatasourceProvider =
    Provider<INotificationRemoteDatasource>((ref) {
      return NotificationRemoteDatasource(
        apiClient: ref.read(apiClientProvider),
        tokenService: ref.read(tokenServiceProvider),
      );
    });

class NotificationRemoteDatasource implements INotificationRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  NotificationRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  Options _authOptions() {
    final token = _tokenService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<NotificationListApiModel> getNotifications({
    required int page,
    required int limit,
    bool? isRead,
    String? type,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (isRead != null) 'isRead': isRead,
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
    };

    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: query,
      options: _authOptions(),
    );

    return NotificationListApiModel.fromJson(response.data['data']);
  }

  @override
  Future<NotificationApiModel> markNotificationRead(
    String notificationId,
  ) async {
    final response = await _apiClient.patch(
      ApiEndpoints.notificationRead(notificationId),
      options: _authOptions(),
    );

    return NotificationApiModel.fromJson(response.data['data']);
  }

  @override
  Future<void> markAllRead() async {
    await _apiClient.patch(
      ApiEndpoints.notificationsReadAll,
      options: _authOptions(),
    );
  }

  @override
  Future<void> syncDeviceFcmToken({
    required String deviceId,
    String? fcmToken,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.deviceFcmToken(deviceId),
      data: {'fcmToken': fcmToken},
      options: _authOptions(),
    );
  }
}
