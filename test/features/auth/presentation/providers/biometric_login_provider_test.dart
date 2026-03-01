import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/core/services/biometric/biometric_service.dart';
import 'package:payhive/core/services/storage/biometric_storage_service.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/auth/presentation/providers/biometric_login_provider.dart';

class FakeBiometricStorageService implements BiometricStorageService {
  FakeBiometricStorageService({required this.enabled});

  final bool enabled;

  @override
  Future<void> disable() async {}

  @override
  Future<void> enable({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {}

  @override
  BiometricUser? getStoredUser() => null;

  @override
  bool isEnabled() => enabled;
}

class FakeTokenService implements TokenService {
  FakeTokenService(this.token);

  final String? token;

  @override
  String? getToken() => token;

  @override
  Future<void> removeToken() async {}

  @override
  Future<void> saveToken(String token) async {}
}

class FakeBiometricService extends BiometricService {
  FakeBiometricService({required this.available, required this.enrolled});

  final bool available;
  final bool enrolled;

  @override
  Future<bool> authenticate({required String reason}) async {
    return true;
  }

  @override
  Future<bool> hasEnrolledBiometrics() async {
    return enrolled;
  }

  @override
  Future<bool> isBiometricAvailable() async {
    return available;
  }
}

void main() {
  test('returns false when biometric is disabled in storage', () async {
    final container = ProviderContainer(
      overrides: [
        biometricStorageServiceProvider.overrideWithValue(
          FakeBiometricStorageService(enabled: false),
        ),
        tokenServiceProvider.overrideWithValue(FakeTokenService('token')),
        biometricServiceProvider.overrideWithValue(
          FakeBiometricService(available: true, enrolled: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(biometricLoginAvailableProvider.future);
    expect(result, isFalse);
  });

  test('returns false when token is missing', () async {
    final container = ProviderContainer(
      overrides: [
        biometricStorageServiceProvider.overrideWithValue(
          FakeBiometricStorageService(enabled: true),
        ),
        tokenServiceProvider.overrideWithValue(FakeTokenService(null)),
        biometricServiceProvider.overrideWithValue(
          FakeBiometricService(available: true, enrolled: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(biometricLoginAvailableProvider.future);
    expect(result, isFalse);
  });

  test(
    'returns false when biometrics are unavailable or not enrolled',
    () async {
      final unavailableContainer = ProviderContainer(
        overrides: [
          biometricStorageServiceProvider.overrideWithValue(
            FakeBiometricStorageService(enabled: true),
          ),
          tokenServiceProvider.overrideWithValue(FakeTokenService('token')),
          biometricServiceProvider.overrideWithValue(
            FakeBiometricService(available: false, enrolled: true),
          ),
        ],
      );
      addTearDown(unavailableContainer.dispose);

      final unavailableResult = await unavailableContainer.read(
        biometricLoginAvailableProvider.future,
      );
      expect(unavailableResult, isFalse);

      final notEnrolledContainer = ProviderContainer(
        overrides: [
          biometricStorageServiceProvider.overrideWithValue(
            FakeBiometricStorageService(enabled: true),
          ),
          tokenServiceProvider.overrideWithValue(FakeTokenService('token')),
          biometricServiceProvider.overrideWithValue(
            FakeBiometricService(available: true, enrolled: false),
          ),
        ],
      );
      addTearDown(notEnrolledContainer.dispose);

      final notEnrolledResult = await notEnrolledContainer.read(
        biometricLoginAvailableProvider.future,
      );
      expect(notEnrolledResult, isFalse);
    },
  );

  test(
    'returns true when all biometric-login conditions are satisfied',
    () async {
      final container = ProviderContainer(
        overrides: [
          biometricStorageServiceProvider.overrideWithValue(
            FakeBiometricStorageService(enabled: true),
          ),
          tokenServiceProvider.overrideWithValue(FakeTokenService('token')),
          biometricServiceProvider.overrideWithValue(
            FakeBiometricService(available: true, enrolled: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        biometricLoginAvailableProvider.future,
      );
      expect(result, isTrue);
    },
  );
}
