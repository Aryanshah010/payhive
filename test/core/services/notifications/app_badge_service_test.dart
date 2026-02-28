import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/core/services/notifications/app_badge_service.dart';

void main() {
  test('does nothing when not running on iOS', () async {
    var setCalls = 0;

    final service = AppBadgeService(
      isIos: () => false,
      setBadgeCountInvoker: (_) => setCalls++,
    );

    await service.setBadgeCount(3);

    expect(setCalls, 0);
  });

  test('sets badge count on iOS for positive values', () async {
    var setCalls = 0;
    var lastCount = 0;

    final service = AppBadgeService(
      isIos: () => true,
      setBadgeCountInvoker: (count) {
        setCalls++;
        lastCount = count;
      },
    );

    await service.setBadgeCount(7);

    expect(setCalls, 1);
    expect(lastCount, 7);
  });

  test('normalizes negative values to zero', () async {
    var setCalls = 0;
    var lastCount = -1;

    final service = AppBadgeService(
      isIos: () => true,
      setBadgeCountInvoker: (count) {
        setCalls++;
        lastCount = count;
      },
    );

    await service.setBadgeCount(-5);

    expect(setCalls, 1);
    expect(lastCount, 0);
  });

  test('swallows platform errors safely', () async {
    final service = AppBadgeService(
      isIos: () => true,
      setBadgeCountInvoker: (_) => throw Exception('channel failed'),
    );

    await expectLater(service.setBadgeCount(10), completes);
  });
}
