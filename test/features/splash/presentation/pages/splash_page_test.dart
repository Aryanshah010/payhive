import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:payhive/features/splash/presentation/pages/splash_page.dart';
import 'package:payhive/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:payhive/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';

class FakeUserSessionService implements UserSessionService {
  FakeUserSessionService(this.loggedIn);
  final bool loggedIn;

  @override
  bool isLoggedIn() => loggedIn;

  @override
  Future<void> clearUserSession() async {}

  @override
  String? getUserFullName() => null;

  @override
  String? getUserId() => null;

  @override
  String? getUserPhoneNumber() => null;

  Future<void> setUserSession(
    String userId,
    String fullName,
    String phoneNumber,
  ) async {}

  @override
  Future<void> saveUserSession({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('SplashPage navigation', () {
    testWidgets('navigates to DashboardScreen when user is logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSessionServiceProvider.overrideWithValue(
              FakeUserSessionService(true),
            ),
          ],
          child: const MaterialApp(home: SplashPage()),
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('navigates to OnboardingScreen when user is NOT logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSessionServiceProvider.overrideWithValue(
              FakeUserSessionService(false),
            ),
          ],
          child: const MaterialApp(home: SplashPage()),
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });
  });
}
