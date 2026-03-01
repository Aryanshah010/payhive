import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/theme/theme_notifier.dart';
import 'package:sensors_plus/sensors_plus.dart';

final shakeServiceProvider = Provider<ShakeService>((ref) {
  final service = ShakeService(() async {
    await ref.read(themeNotifierProvider.notifier).toggle();
  });

  ref.onDispose(service.stop);

  return service;
});

class ShakeService {
  ShakeService(this._onShake);

  static const Duration _shakeCooldown = Duration(seconds: 3);
  static const Duration _shakeWindow = Duration(milliseconds: 500);
  static const double _shakeThresholdG = 2.3;
  static const double _gravity = 9.80665;
  static const int _requiredShakeCount = 3;
  static const double _alpha = 0.8;

  final Future<void> Function() _onShake;

  StreamSubscription<AccelerometerEvent>? _subscription;

  DateTime? _lastShakeAt;
  DateTime? _firstShakeTime;
  int _shakeCount = 0;

  double _filteredX = 0;
  double _filteredY = 0;
  double _filteredZ = 0;

  void start() {
    _subscription ??= accelerometerEventStream().listen(
      _onAccelerometerEvent,
      onError: (_) {},
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) async {

    _filteredX = _alpha * _filteredX + (1 - _alpha) * event.x;
    _filteredY = _alpha * _filteredY + (1 - _alpha) * event.y;
    _filteredZ = _alpha * _filteredZ + (1 - _alpha) * event.z;

    final gForce =
        math.sqrt(
          _filteredX * _filteredX +
              _filteredY * _filteredY +
              _filteredZ * _filteredZ,
        ) /
        _gravity;

    if (gForce < _shakeThresholdG) return;

    final now = DateTime.now();

    if (_lastShakeAt != null &&
        now.difference(_lastShakeAt!) < _shakeCooldown) {
      return;
    }
    if (_firstShakeTime == null ||
        now.difference(_firstShakeTime!) > _shakeWindow) {
      _firstShakeTime = now;
      _shakeCount = 1;
    } else {
      _shakeCount++;
    }

    if (_shakeCount >= _requiredShakeCount) {
      _lastShakeAt = now;
      _shakeCount = 0;
      _firstShakeTime = null;

      await _onShake();
    }
  }
}
