import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/services/hive/hive_service.dart';
import 'package:payhive/core/services/storage/biometric_storage_service.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/auth/data/datasources/local/auth_local_datasource.dart';

class MockHiveService extends Mock implements HiveService {}

class MockUserSessionService extends Mock implements UserSessionService {}

class MockTokenService extends Mock implements TokenService {}

class MockBiometricStorageService extends Mock
    implements BiometricStorageService {}

void main() {
  late MockHiveService mockHiveService;
  late MockUserSessionService mockUserSessionService;
  late MockTokenService mockTokenService;
  late MockBiometricStorageService mockBiometricStorageService;

  late AuthLocalDatasource datasource;

  setUp(() {
    mockHiveService = MockHiveService();
    mockUserSessionService = MockUserSessionService();
    mockTokenService = MockTokenService();
    mockBiometricStorageService = MockBiometricStorageService();

    datasource = AuthLocalDatasource(
      hiveService: mockHiveService,
      userSessionService: mockUserSessionService,
      tokenService: mockTokenService,
      biometricStorageService: mockBiometricStorageService,
    );
  });

  group('logout', () {
    test('preserves token when biometric is enabled', () async {
      when(() => mockBiometricStorageService.isEnabled()).thenReturn(true);
      when(
        () => mockUserSessionService.clearUserSession(),
      ).thenAnswer((_) async {});

      final result = await datasource.logout();

      expect(result, isTrue);
      verifyNever(() => mockTokenService.removeToken());
      verify(() => mockUserSessionService.clearUserSession()).called(1);
    });

    test('removes token when biometric is disabled', () async {
      when(() => mockBiometricStorageService.isEnabled()).thenReturn(false);
      when(() => mockTokenService.removeToken()).thenAnswer((_) async {});
      when(
        () => mockUserSessionService.clearUserSession(),
      ).thenAnswer((_) async {});

      final result = await datasource.logout();

      expect(result, isTrue);
      verify(() => mockTokenService.removeToken()).called(1);
      verify(() => mockUserSessionService.clearUserSession()).called(1);
    });
  });
}
