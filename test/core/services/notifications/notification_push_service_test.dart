import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/services/notifications/notification_push_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingTokenSyncService extends NotificationPushService {
  RecordingTokenSyncService(
    super.ref, {
    super.nowProvider,
    super.fcmTokenReader,
  });

  int syncBackendCalls = 0;
  String? syncedDeviceId;
  String? syncedToken;

  @override
  Future<void> syncTokenWithBackend({
    required String deviceId,
    String? fcmToken,
  }) async {
    syncBackendCalls++;
    syncedDeviceId = deviceId;
    syncedToken = fcmToken;
  }
}

class CountingSessionSyncService extends NotificationPushService {
  CountingSessionSyncService(super.ref, {super.nowProvider});

  int sessionSyncCalls = 0;

  @override
  Future<void> performSessionSync() async {
    sessionSyncCalls++;
  }
}

class MockMarkNotificationReadUsecase extends Mock
    implements MarkNotificationReadUsecase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MarkNotificationReadParams(notificationId: 'fallback'),
    );
  });

  test(
    'syncCurrentToken does not clear backend token when token is null',
    () async {
      SharedPreferences.setMockInitialValues({'device_id': 'device-1'});
      final prefs = await SharedPreferences.getInstance();
      late RecordingTokenSyncService service;

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationPushServiceProvider.overrideWith((ref) {
            service = RecordingTokenSyncService(
              ref,
              fcmTokenReader: () async => null,
            );
            return service;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationPushServiceProvider).syncCurrentToken();

      expect(service.syncBackendCalls, 0);
    },
  );

  test('clearServerFcmTokenOnLogout syncs explicit null token', () async {
    SharedPreferences.setMockInitialValues({'device_id': 'device-1'});
    final prefs = await SharedPreferences.getInstance();
    late RecordingTokenSyncService service;

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationPushServiceProvider.overrideWith((ref) {
          service = RecordingTokenSyncService(
            ref,
            fcmTokenReader: () async => 'ignored-token',
          );
          return service;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(notificationPushServiceProvider)
        .clearServerFcmTokenOnLogout();

    expect(service.syncBackendCalls, 1);
    expect(service.syncedDeviceId, 'device-1');
    expect(service.syncedToken, isNull);
  });

  test('onAppResumed uses throttle to avoid duplicate session sync', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 2, 27, 15, 0, 0);
    late CountingSessionSyncService service;

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationPushServiceProvider.overrideWith((ref) {
          service = CountingSessionSyncService(ref, nowProvider: () => now);
          return service;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(notificationPushServiceProvider).onAppResumed();
    await container.read(notificationPushServiceProvider).onAppResumed();

    expect(service.sessionSyncCalls, 1);

    now = now.add(const Duration(seconds: 11));
    await container.read(notificationPushServiceProvider).onAppResumed();

    expect(service.sessionSyncCalls, 2);
  });

  test('markPayloadAsRead accepts both notificationId and id keys', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockUsecase = MockMarkNotificationReadUsecase();

    when(() => mockUsecase(any())).thenAnswer(
      (_) async => Right(
        NotificationEntity(
          id: 'notif-1',
          userId: 'user-1',
          title: 'Title',
          body: 'Body',
          type: 'REQUEST_MONEY',
          isRead: true,
          createdAt: DateTime(2026, 2, 27),
          updatedAt: DateTime(2026, 2, 27),
        ),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        markNotificationReadUsecaseProvider.overrideWithValue(mockUsecase),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(notificationPushServiceProvider);
    service.markPayloadAsRead({'notificationId': 'notif-1'});
    service.markPayloadAsRead({'id': 'notif-2'});

    verify(
      () => mockUsecase(
        const MarkNotificationReadParams(notificationId: 'notif-1'),
      ),
    ).called(1);
    verify(
      () => mockUsecase(
        const MarkNotificationReadParams(notificationId: 'notif-2'),
      ),
    ).called(1);
  });
}
