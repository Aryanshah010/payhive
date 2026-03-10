import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/notifications/notification_push_service.dart';
import 'package:payhive/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';

class FakeProfileViewModel extends ProfileViewModel {
  int ensureLoadedCalls = 0;
  int refreshProfileCalls = 0;

  @override
  ProfileState build() {
    return ProfileState.initial().copyWith(
      status: ProfileStatus.loaded,
      fullName: 'Test User',
      phoneNumber: '9800000002',
      email: 'test@example.com',
      hasPin: true,
      balance: 1000,
    );
  }

  @override
  Future<void> ensureLoaded() async {
    ensureLoadedCalls++;
  }

  @override
  Future<void> refreshProfile() async {
    refreshProfileCalls++;
  }
}

class FakeNotificationPushService extends NotificationPushService {
  FakeNotificationPushService(super.ref);

  int initCalls = 0;
  int resumedCalls = 0;

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  Future<void> onAppResumed() async {
    resumedCalls++;
  }
}

void main() {
  testWidgets('init path calls ensureLoaded and push init once', (
    tester,
  ) async {
    late FakeProfileViewModel profileViewModel;
    late FakeNotificationPushService pushService;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(() {
            profileViewModel = FakeProfileViewModel();
            return profileViewModel;
          }),
          notificationPushServiceProvider.overrideWith((ref) {
            pushService = FakeNotificationPushService(ref);
            return pushService;
          }),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(profileViewModel.ensureLoadedCalls, 1);
    expect(pushService.initCalls, 1);
  });

  testWidgets('resume path is throttled and avoids duplicate sync bursts', (
    tester,
  ) async {
    late FakeProfileViewModel profileViewModel;
    late FakeNotificationPushService pushService;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(() {
            profileViewModel = FakeProfileViewModel();
            return profileViewModel;
          }),
          notificationPushServiceProvider.overrideWith((ref) {
            pushService = FakeNotificationPushService(ref);
            return pushService;
          }),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final baselineRefreshCalls = profileViewModel.refreshProfileCalls;
    final baselineResumeCalls = pushService.resumedCalls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(profileViewModel.refreshProfileCalls, baselineRefreshCalls + 1);
    expect(pushService.resumedCalls, baselineResumeCalls + 1);
  });
}
