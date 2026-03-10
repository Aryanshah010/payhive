import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';

abstract interface class INotificationRepository {
  Future<Either<Failure, NotificationListEntity>> getNotifications({
    required int page,
    required int limit,
    bool? isRead,
    String? type,
  });

  Future<Either<Failure, NotificationEntity>> markNotificationRead(
    String notificationId,
  );

  Future<Either<Failure, bool>> markAllRead();

  Future<Either<Failure, bool>> syncDeviceFcmToken({
    required String deviceId,
    String? fcmToken,
  });
}
