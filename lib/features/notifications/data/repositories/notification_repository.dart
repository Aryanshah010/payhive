import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/notifications/data/datasources/notification_datasource.dart';
import 'package:payhive/features/notifications/data/datasources/remote/notification_remote_datasource.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(notificationRemoteDatasourceProvider);
  return NotificationRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class NotificationRepository implements INotificationRepository {
  final NetworkInfo _networkInfo;
  final INotificationRemoteDatasource _remoteDatasource;

  NotificationRepository({
    required NetworkInfo networkInfo,
    required INotificationRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, NotificationListEntity>> getNotifications({
    required int page,
    required int limit,
    bool? isRead,
    String? type,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(ApiFalilure(message: 'No Internet connection'));
    }

    try {
      final data = await _remoteDatasource.getNotifications(
        page: page,
        limit: limit,
        isRead: isRead,
        type: type,
      );
      return Right(data.toEntity());
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to load notifications';
      return Left(
        ApiFalilure(message: message, statusCode: e.response?.statusCode),
      );
    } catch (e) {
      return Left(ApiFalilure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> markNotificationRead(
    String notificationId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Left(ApiFalilure(message: 'No Internet connection'));
    }

    try {
      final data = await _remoteDatasource.markNotificationRead(notificationId);
      return Right(data.toEntity());
    } on DioException catch (e) {
      final raw = e.response?.data;
      final message = raw is Map && raw['message'] != null
          ? raw['message'].toString()
          : 'Failed to mark notification as read';
      return Left(
        ApiFalilure(message: message, statusCode: e.response?.statusCode),
      );
    } catch (e) {
      return Left(ApiFalilure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markAllRead() async {
    if (!await _networkInfo.isConnected) {
      return Left(ApiFalilure(message: 'No Internet connection'));
    }

    try {
      await _remoteDatasource.markAllRead();
      return const Right(true);
    } on DioException catch (e) {
      final raw = e.response?.data;
      final message = raw is Map && raw['message'] != null
          ? raw['message'].toString()
          : 'Failed to mark all notifications as read';
      return Left(
        ApiFalilure(message: message, statusCode: e.response?.statusCode),
      );
    } catch (e) {
      return Left(ApiFalilure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> syncDeviceFcmToken({
    required String deviceId,
    String? fcmToken,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(ApiFalilure(message: 'No Internet connection'));
    }

    try {
      await _remoteDatasource.syncDeviceFcmToken(
        deviceId: deviceId,
        fcmToken: fcmToken,
      );
      return const Right(true);
    } on DioException catch (e) {
      final raw = e.response?.data;
      final message = raw is Map && raw['message'] != null
          ? raw['message'].toString()
          : 'Failed to sync push token';
      return Left(
        ApiFalilure(message: message, statusCode: e.response?.statusCode),
      );
    } catch (e) {
      return Left(ApiFalilure(message: e.toString()));
    }
  }
}
