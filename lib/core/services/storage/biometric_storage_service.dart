import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final biometricStorageServiceProvider = Provider<BiometricStorageService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return BiometricStorageService(prefs: prefs);
});

class BiometricUser {
  final String userId;
  final String fullName;
  final String phoneNumber;

  const BiometricUser({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
  });
}

class BiometricStorageService {
  final SharedPreferences _prefs;

  BiometricStorageService({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _keyEnabled = 'biometric_enabled';
  static const String _keyUserId = 'biometric_user_id';
  static const String _keyFullName = 'biometric_full_name';
  static const String _keyPhone = 'biometric_phone';

  bool isEnabled() {
    return _prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> enable({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {
    await _prefs.setBool(_keyEnabled, true);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyFullName, fullName);
    await _prefs.setString(_keyPhone, phoneNumber);
  }

  Future<void> disable() async {
    await _prefs.remove(_keyEnabled);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyFullName);
    await _prefs.remove(_keyPhone);
  }

  BiometricUser? getStoredUser() {
    final enabled = isEnabled();
    if (!enabled) return null;

    final userId = _prefs.getString(_keyUserId);
    final fullName = _prefs.getString(_keyFullName);
    final phoneNumber = _prefs.getString(_keyPhone);

    if (userId == null || fullName == null || phoneNumber == null) {
      return null;
    }

    return BiometricUser(
      userId: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}
