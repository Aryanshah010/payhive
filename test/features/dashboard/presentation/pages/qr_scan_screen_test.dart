// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/qr/presentation/pages/qr_scan_page.dart';

class FakePermissionHandler extends PermissionHandlerPlatform {
  final PermissionStatus cameraStatus;

  FakePermissionHandler(this.cameraStatus);

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    if (permission == Permission.camera) {
      return cameraStatus;
    }
    return PermissionStatus.denied;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return {Permission.camera: cameraStatus};
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

class FakeUserSessionService implements UserSessionService {
  @override
  bool isLoggedIn() => true;

  @override
  Future<void> clearUserSession() async {}

  @override
  String? getUserFullName() => 'Aryan Shah';

  @override
  String? getUserId() => 'user-1';

  @override
  String? getUserPhoneNumber() => '9815905635';

  @override
  Future<void> saveUserSession({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PermissionHandlerPlatform.instance = FakePermissionHandler(
      PermissionStatus.denied,
    );
  });

  tearDown(() {
    PermissionHandlerPlatform.instance = FakePermissionHandler(
      PermissionStatus.granted,
    );
  });

  testWidgets('shows loading indicator before permission check completes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionServiceProvider.overrideWithValue(FakeUserSessionService()),
        ],
        child: const MaterialApp(home: QrScanPage()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows permission denied UI when camera permission is denied', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionServiceProvider.overrideWithValue(FakeUserSessionService()),
        ],
        child: const MaterialApp(home: QrScanPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Camera permission is required to scan QR codes.'),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('can swipe to My QR page even when camera permission is denied', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionServiceProvider.overrideWithValue(FakeUserSessionService()),
        ],
        child: const MaterialApp(home: QrScanPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Scan to receive money'), findsOneWidget);
  });

  testWidgets('My QR page shows user name and PayHive ID', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionServiceProvider.overrideWithValue(FakeUserSessionService()),
        ],
        child: const MaterialApp(home: QrScanPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Aryan Shah'), findsOneWidget);
    expect(find.textContaining('PayHive ID:'), findsOneWidget);
  });
}
