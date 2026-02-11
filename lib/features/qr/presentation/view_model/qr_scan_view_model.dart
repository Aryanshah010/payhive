import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/qr/presentation/state/qr_scan_state.dart';

final qrScanViewModelProvider =
    NotifierProvider<QrScanViewModel, QrScanState>(() => QrScanViewModel());

class QrScanViewModel extends Notifier<QrScanState> {
  static const Duration _invalidCooldown = Duration(seconds: 2);
  static const Duration _duplicateCooldown = Duration(seconds: 2);

  int _lastInvalidAtMs = 0;
  int _lastProcessedAtMs = 0;
  String? _lastRaw;

  @override
  QrScanState build() {
    return QrScanState.initial();
  }

  bool get canShowInvalidMessage {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - _lastInvalidAtMs >= _invalidCooldown.inMilliseconds;
  }

  Duration get invalidPauseDuration => _invalidCooldown;

  String? parsePhoneNumber(String raw) {
    final trimmed = raw.trim();

    if (RegExp(r'^\d{10}$').hasMatch(trimmed)) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme.toLowerCase() == 'payhive') {
      final param = uri.queryParameters['id'];
      if (param != null && RegExp(r'^\d{10}$').hasMatch(param)) {
        return param;
      }
    }

    return null;
  }

  bool shouldIgnoreDuplicate(String raw) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastRaw == raw &&
        now - _lastProcessedAtMs < _duplicateCooldown.inMilliseconds) {
      return true;
    }
    return false;
  }

  QrScanHandleResult handleScan(String raw) {
    if (state.isProcessing) {
      return const QrScanHandleResult.ignored();
    }

    if (shouldIgnoreDuplicate(raw)) {
      return const QrScanHandleResult.ignored();
    }

    final phone = parsePhoneNumber(raw);
    if (phone == null) {
      if (canShowInvalidMessage) {
        _lastInvalidAtMs = DateTime.now().millisecondsSinceEpoch;
        _lastRaw = raw;
        _lastProcessedAtMs = _lastInvalidAtMs;
        return const QrScanHandleResult.invalid();
      }
      return const QrScanHandleResult.ignored();
    }

    _lastRaw = raw;
    _lastProcessedAtMs = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      isProcessing: true,
      lastPhone: phone,
      scannedData: raw,
    );
    return QrScanHandleResult.valid(phone);
  }

  void markProcessingComplete() {
    if (!state.isProcessing) return;
    state = state.copyWith(isProcessing: false);
  }

  void resetFlow() {
    state = QrScanState.initial();
    _lastRaw = null;
    _lastInvalidAtMs = 0;
    _lastProcessedAtMs = 0;
  }
}

class QrScanHandleResult {
  final bool ignored;
  final bool invalid;
  final String? phone;

  const QrScanHandleResult._({
    required this.ignored,
    required this.invalid,
    required this.phone,
  });

  const QrScanHandleResult.ignored()
    : this._(ignored: true, invalid: false, phone: null);

  const QrScanHandleResult.invalid()
    : this._(ignored: false, invalid: true, phone: null);

  const QrScanHandleResult.valid(String phone)
      : this._(ignored: false, invalid: false, phone: phone);
}
