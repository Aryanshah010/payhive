import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

class DeviceInfoService {
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        final manufacturer = info.manufacturer.trim();
        final model = info.model.trim();
        final version = info.version.release;
        final baseName = '$manufacturer $model'.trim();
        if (version.isNotEmpty) {
          return '$baseName (Android $version)';
        }
        return baseName;
      }

      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        final name = info.name.trim();
        final system = info.systemName.trim();
        final version = info.systemVersion.trim();
        return '$name ($system $version)';
      }
    } catch (_) {}

    return 'Unknown device';
  }
}
