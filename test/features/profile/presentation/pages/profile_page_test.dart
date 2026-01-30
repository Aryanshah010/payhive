// test/features/profile/profile_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/profile/presentation/pages/profile_page.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';

class FakeProfileViewModel extends ProfileViewModel {
  @override
  ProfileState build() {
    return const ProfileState(
      status: ProfileStatus.loaded,
      fullName: 'Test User',
      phoneNumber: '9800000000',
      imageUrl: null,
      errorMessage: null,
    );
  }

  @override
  Future<void> loadProfile() async {}

  @override
  Future<void> uploadImage(dynamic photo) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfilePage widget tests', () {
    testWidgets('renders header, name, phone and menu items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileViewModelProvider.overrideWith(() => FakeProfileViewModel()),
          ],
          child: const MaterialApp(home: ProfilePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('9800000000'), findsOneWidget);

      expect(find.text('Update KYC'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Manage Devices'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      expect(find.text('Logout'), findsWidgets);
    });

    testWidgets(
      'tapping logout opens confirmation dialog and Cancel dismisses it',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileViewModelProvider.overrideWith(
                () => FakeProfileViewModel(),
              ),
            ],
            child: const MaterialApp(home: ProfilePage()),
          ),
        );

        await tester.pumpAndSettle();

        final logoutText = find.text('Logout');
        expect(logoutText, findsWidgets);

        await tester.ensureVisible(logoutText.first);
        await tester.pumpAndSettle();

        await tester.tap(logoutText.first);
        await tester.pumpAndSettle();

        expect(find.text('Are you sure you want to logout?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Are you sure you want to logout?'), findsNothing);
      },
    );

    testWidgets('build produces no render exceptions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileViewModelProvider.overrideWith(() => FakeProfileViewModel()),
          ],
          child: const MaterialApp(home: ProfilePage()),
        ),
      );

      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull);
    });
  });
}
