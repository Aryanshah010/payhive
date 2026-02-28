import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/services/notifications/app_badge_service.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:payhive/features/notifications/presentation/view_model/notification_view_model.dart';

class MockGetNotificationsUsecase extends Mock
    implements GetNotificationsUsecase {}

class MockMarkNotificationReadUsecase extends Mock
    implements MarkNotificationReadUsecase {}

class MockMarkAllNotificationsReadUsecase extends Mock
    implements MarkAllNotificationsReadUsecase {}

class RecordingBadgeService extends AppBadgeService {
  RecordingBadgeService();

  final List<int> counts = [];

  @override
  Future<void> setBadgeCount(int count) async {
    counts.add(count);
  }
}

void main() {
  late MockGetNotificationsUsecase mockGetUsecase;
  late MockMarkNotificationReadUsecase mockMarkReadUsecase;
  late MockMarkAllNotificationsReadUsecase mockMarkAllUsecase;
  late RecordingBadgeService badgeService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const GetNotificationsParams(page: 1, limit: 10));
    registerFallbackValue(
      const MarkNotificationReadParams(notificationId: 'notif-1'),
    );
  });

  setUp(() {
    mockGetUsecase = MockGetNotificationsUsecase();
    mockMarkReadUsecase = MockMarkNotificationReadUsecase();
    mockMarkAllUsecase = MockMarkAllNotificationsReadUsecase();
    badgeService = RecordingBadgeService();

    container = ProviderContainer(
      overrides: [
        getNotificationsUsecaseProvider.overrideWithValue(mockGetUsecase),
        markNotificationReadUsecaseProvider.overrideWithValue(
          mockMarkReadUsecase,
        ),
        markAllNotificationsReadUsecaseProvider.overrideWithValue(
          mockMarkAllUsecase,
        ),
        appBadgeServiceProvider.overrideWithValue(badgeService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  NotificationEntity notification({required String id, required bool isRead}) {
    return NotificationEntity(
      id: id,
      userId: 'user-1',
      title: 'Title',
      body: 'Body',
      type: 'REQUEST_MONEY',
      isRead: isRead,
      createdAt: DateTime(2026, 2, 27),
      updatedAt: DateTime(2026, 2, 27),
    );
  }

  NotificationListEntity page({
    required List<NotificationEntity> items,
    required int unreadCount,
  }) {
    return NotificationListEntity(
      items: items,
      total: items.length,
      page: 1,
      limit: 10,
      totalPages: 1,
      unreadCount: unreadCount,
    );
  }

  test('loadInitial syncs unread badge count', () async {
    when(() => mockGetUsecase(any())).thenAnswer(
      (_) async => Right(
        page(items: [notification(id: 'n1', isRead: false)], unreadCount: 1),
      ),
    );

    await container.read(notificationViewModelProvider.notifier).loadInitial();

    expect(container.read(notificationViewModelProvider).unreadCount, 1);
    expect(badgeService.counts, [1]);
  });

  test('markNotificationRead syncs unread badge count', () async {
    when(() => mockGetUsecase(any())).thenAnswer(
      (_) async => Right(
        page(items: [notification(id: 'n1', isRead: false)], unreadCount: 1),
      ),
    );
    when(
      () => mockMarkReadUsecase(any()),
    ).thenAnswer((_) async => Right(notification(id: 'n1', isRead: true)));

    final vm = container.read(notificationViewModelProvider.notifier);
    await vm.loadInitial();
    await vm.markNotificationRead('n1');

    expect(container.read(notificationViewModelProvider).unreadCount, 0);
    expect(badgeService.counts, [1, 0]);
  });

  test('markAllRead syncs badge count to zero', () async {
    when(() => mockGetUsecase(any())).thenAnswer(
      (_) async => Right(
        page(
          items: [
            notification(id: 'n1', isRead: false),
            notification(id: 'n2', isRead: false),
          ],
          unreadCount: 2,
        ),
      ),
    );
    when(() => mockMarkAllUsecase()).thenAnswer((_) async => const Right(true));

    final vm = container.read(notificationViewModelProvider.notifier);
    await vm.loadInitial();
    await vm.markAllRead();

    expect(container.read(notificationViewModelProvider).unreadCount, 0);
    expect(badgeService.counts, [2, 0]);
  });
}
