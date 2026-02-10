import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payhive/features/splash/presentation/pages/splash_page.dart';
import 'package:payhive/core/services/storage/biometric_storage_service.dart';
import 'package:payhive/features/auth/presentation/pages/login_page.dart';
import 'package:payhive/features/auth/presentation/providers/biometric_login_provider.dart';
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

class FakeBiometricStorageService implements BiometricStorageService {
  FakeBiometricStorageService(this.enabled);
  final bool enabled;

  @override
  bool isEnabled() => enabled;

  @override
  Future<void> enable({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {}

  @override
  Future<void> disable() async {}

  @override
  BiometricUser? getStoredUser() => null;
}

void main() {
  group('SplashPage navigation', () {
    testWidgets('navigates to DashboardScreen when user is logged in', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricLoginAvailableProvider.overrideWith(
              (ref) => Future.value(false),
            ),
            userSessionServiceProvider.overrideWithValue(
              FakeUserSessionService(true),
            ),
            biometricStorageServiceProvider.overrideWithValue(
              FakeBiometricStorageService(false),
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

    testWidgets('navigates to LoginPage when biometric is enabled', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricLoginAvailableProvider.overrideWith(
              (ref) => Future.value(false),
            ),
            userSessionServiceProvider.overrideWithValue(
              FakeUserSessionService(false),
            ),
            biometricStorageServiceProvider.overrideWithValue(
              FakeBiometricStorageService(true),
            ),
          ],
          child: const MaterialApp(home: SplashPage()),
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('navigates to OnboardingScreen when user is NOT logged in', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricLoginAvailableProvider.overrideWith(
              (ref) => Future.value(false),
            ),
            userSessionServiceProvider.overrideWithValue(
              FakeUserSessionService(false),
            ),
            biometricStorageServiceProvider.overrideWithValue(
              FakeBiometricStorageService(false),
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
