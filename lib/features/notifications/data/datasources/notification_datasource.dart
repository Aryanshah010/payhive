import 'package:payhive/features/notifications/data/models/notification_api_model.dart';

abstract interface class INotificationRemoteDatasource {
  Future<NotificationListApiModel> getNotifications({
    required int page,
    required int limit,
    bool? isRead,
    String? type,
  });

  Future<NotificationApiModel> markNotificationRead(String notificationId);

  Future<void> markAllRead();

  Future<void> syncDeviceFcmToken({required String deviceId, String? fcmToken});
}
