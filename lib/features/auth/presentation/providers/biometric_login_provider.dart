import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/biometric/biometric_service.dart';
import 'package:payhive/core/services/storage/biometric_storage_service.dart';
import 'package:payhive/core/services/storage/token_service.dart';

final biometricLoginAvailableProvider = FutureProvider<bool>((ref) async {
  final biometricStorage = ref.read(biometricStorageServiceProvider);
  if (!biometricStorage.isEnabled()) return false;

  final tokenService = ref.read(tokenServiceProvider);
  final token = tokenService.getToken();
  if (token == null || token.isEmpty) return false;

  final biometricService = ref.read(biometricServiceProvider);
  final available = await biometricService.isBiometricAvailable();
  if (!available) return false;
  final enrolled = await biometricService.hasEnrolledBiometrics();
  return enrolled;
});
