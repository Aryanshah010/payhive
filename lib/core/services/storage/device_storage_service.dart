import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final deviceStorageServiceProvider = Provider<DeviceStorageService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return DeviceStorageService(prefs: prefs);
});

class DeviceStorageService {
  static const String _keyDeviceId = 'device_id';

  final SharedPreferences _prefs;

  DeviceStorageService({required SharedPreferences prefs}) : _prefs = prefs;

  String? getDeviceId() {
    return _prefs.getString(_keyDeviceId);
  }

  Future<void> saveDeviceId(String deviceId) async {
    if (deviceId.trim().isEmpty) return;
    await _prefs.setString(_keyDeviceId, deviceId.trim());
  }
}
