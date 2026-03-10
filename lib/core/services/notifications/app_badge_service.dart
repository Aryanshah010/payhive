import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appBadgeServiceProvider = Provider<AppBadgeService>(
  (_) => AppBadgeService(),
);

class AppBadgeService {
  AppBadgeService({
    bool Function()? isIos,
    FutureOr<void> Function(int count)? setBadgeCountInvoker,
  }) : _isIos = isIos ?? _defaultIsIos,
       _setBadgeCountInvoker =
           setBadgeCountInvoker ?? _defaultSetBadgeCountInvoker;

  final bool Function() _isIos;
  final FutureOr<void> Function(int count) _setBadgeCountInvoker;
  static const MethodChannel _badgeChannel = MethodChannel('payhive/app_badge');

  static bool _defaultIsIos() {
    return !kIsWeb && Platform.isIOS;
  }

  static Future<void> _defaultSetBadgeCountInvoker(int count) async {
    await _badgeChannel.invokeMethod<void>('setBadgeCount', {'count': count});
  }

  Future<void> setBadgeCount(int count) async {
    if (!_isIos()) return;

    try {
      final normalizedCount = count < 0 ? 0 : count;
      await Future<void>.sync(() => _setBadgeCountInvoker(normalizedCount));
    } catch (_) {
      // No-op when badge APIs are unavailable.
    }
  }
}
