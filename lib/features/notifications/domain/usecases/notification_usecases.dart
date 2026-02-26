import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/notifications/data/repositories/notification_repository.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsParams extends Equatable {
  final int page;
  final int limit;
  final bool? isRead;
  final String? type;

  const GetNotificationsParams({
    required this.page,
    required this.limit,
    this.isRead,
    this.type,
  });

  @override
  List<Object?> get props => [page, limit, isRead, type];
}

class MarkNotificationReadParams extends Equatable {
  final String notificationId;

  const MarkNotificationReadParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class SyncDeviceFcmTokenParams extends Equatable {
  final String deviceId;
  final String? fcmToken;

  const SyncDeviceFcmTokenParams({required this.deviceId, this.fcmToken});

  @override
  List<Object?> get props => [deviceId, fcmToken];
}

final getNotificationsUsecaseProvider = Provider<GetNotificationsUsecase>((
  ref,
) {
  final repository = ref.read(notificationRepositoryProvider);
  return GetNotificationsUsecase(repository: repository);
});

final markNotificationReadUsecaseProvider =
    Provider<MarkNotificationReadUsecase>((ref) {
      final repository = ref.read(notificationRepositoryProvider);
      return MarkNotificationReadUsecase(repository: repository);
    });

final markAllNotificationsReadUsecaseProvider =
    Provider<MarkAllNotificationsReadUsecase>((ref) {
      final repository = ref.read(notificationRepositoryProvider);
      return MarkAllNotificationsReadUsecase(repository: repository);
    });

final syncDeviceFcmTokenUsecaseProvider = Provider<SyncDeviceFcmTokenUsecase>((
  ref,
) {
  final repository = ref.read(notificationRepositoryProvider);
  return SyncDeviceFcmTokenUsecase(repository: repository);
});

class GetNotificationsUsecase
    implements
        UsecaseWithParams<NotificationListEntity, GetNotificationsParams> {
  final INotificationRepository _repository;

  GetNotificationsUsecase({required INotificationRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, NotificationListEntity>> call(
    GetNotificationsParams params,
  ) {
    if (params.page <= 0 || params.limit <= 0) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Invalid notification page/limit values'),
        ),
      );
    }

    return _repository.getNotifications(
      page: params.page,
      limit: params.limit,
      isRead: params.isRead,
      type: params.type,
    );
  }
}

class MarkNotificationReadUsecase
    implements
        UsecaseWithParams<NotificationEntity, MarkNotificationReadParams> {
  final INotificationRepository _repository;

  MarkNotificationReadUsecase({required INotificationRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, NotificationEntity>> call(
    MarkNotificationReadParams params,
  ) {
    if (params.notificationId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Notification ID is required')),
      );
    }

    return _repository.markNotificationRead(params.notificationId.trim());
  }
}

class MarkAllNotificationsReadUsecase implements UsecaseWithoutParams<bool> {
  final INotificationRepository _repository;

  MarkAllNotificationsReadUsecase({required INotificationRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, bool>> call() {
    return _repository.markAllRead();
  }
}

class SyncDeviceFcmTokenUsecase
    implements UsecaseWithParams<bool, SyncDeviceFcmTokenParams> {
  final INotificationRepository _repository;

  SyncDeviceFcmTokenUsecase({required INotificationRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(SyncDeviceFcmTokenParams params) {
    if (params.deviceId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Device ID is required')),
      );
    }

    final normalizedToken = params.fcmToken?.trim();

    return _repository.syncDeviceFcmToken(
      deviceId: params.deviceId.trim(),
      fcmToken: normalizedToken == null || normalizedToken.isEmpty
          ? null
          : normalizedToken,
    );
  }
}
