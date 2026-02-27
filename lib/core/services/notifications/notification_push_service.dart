import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/notifications/notification_deeplink_handler.dart';
import 'package:payhive/core/services/storage/device_storage_service.dart';
import 'package:payhive/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:payhive/features/notifications/presentation/view_model/notification_view_model.dart';

const _androidChannelId = 'payhive_realtime_notifications';
const _androidChannelName = 'Realtime Notifications';
const _androidChannelDescription =
    'Payment, security and account notifications';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore: app can still function without background processing.
  }
}

final notificationPushServiceProvider = Provider<NotificationPushService>((
  ref,
) {
  return NotificationPushService(ref);
});

class NotificationPushService {
  NotificationPushService(
    this._ref, {
    DateTime Function()? nowProvider,
    Future<String?> Function()? fcmTokenReader,
  }) : _now = nowProvider ?? DateTime.now,
       _fcmTokenReader =
           fcmTokenReader ?? (() => FirebaseMessaging.instance.getToken());

  static const Duration _sessionSyncThrottle = Duration(seconds: 10);

  final Ref _ref;
  final DateTime Function() _now;
  final Future<String?> Function() _fcmTokenReader;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localNotificationsReady = false;
  bool _firebaseUnavailable = false;
  DateTime? _lastSessionSyncAt;
  Future<void>? _sessionSyncFuture;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openFromTapSub;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> init() async {
    if (_firebaseUnavailable) return;

    if (_initialized) {
      await syncSessionState(force: false);
      _ref.read(notificationDeepLinkHandlerProvider).processPendingIfAny();
      return;
    }

    _initialized = true;
    try {
      await _initLocalNotifications();
      await _requestPermission();
      _bindListeners();
      await _processInitialMessage();
      await syncSessionState(force: true);
      _ref.read(notificationDeepLinkHandlerProvider).processPendingIfAny();
    } catch (e) {
      if (_isFirebaseNotInitializedError(e)) {
        _firebaseUnavailable = true;
      }
      _initialized = false;
      debugPrint('Notification push init skipped: $e');
    }
  }

  Future<void> onAppResumed() async {
    await syncSessionState(force: false);
    _ref.read(notificationDeepLinkHandlerProvider).processPendingIfAny();
  }

  Future<void> clearServerFcmTokenOnLogout() async {
    final deviceId = _readDeviceId();
    if (deviceId == null) return;

    _lastSessionSyncAt = null;
    await syncTokenWithBackend(deviceId: deviceId, fcmToken: null);
  }

  void _bindListeners() {
    _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundLocalNotification(message));
      unawaited(
        _ref
            .read(notificationViewModelProvider.notifier)
            .handleIncomingNotification(),
      );
    });

    _openFromTapSub ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRemoteMessageTap(message);
      unawaited(syncSessionState(force: true));
    });

    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      final deviceId = _readDeviceId();
      if (deviceId == null) return;
      final normalizedToken = token.trim();
      if (normalizedToken.isEmpty) {
        debugPrint(
          'FCM token refresh received an empty token; skipping backend sync.',
        );
        return;
      }

      unawaited(
        syncTokenWithBackend(deviceId: deviceId, fcmToken: normalizedToken),
      );
    });
  }

  Future<void> _processInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;

    _handleRemoteMessageTap(message);
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final payload = _buildPayloadFromRemoteMessage(message);
    markPayloadAsRead(payload);
    _ref.read(notificationDeepLinkHandlerProvider).handlePayload(payload);
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permission denied; push may not arrive.');
    }

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      final hasApnsToken = apnsToken != null && apnsToken.trim().isNotEmpty;
      if (!hasApnsToken) {
        debugPrint(
          'APNs token unavailable. Ensure iOS Push Notifications + APNs key are configured.',
        );
      }
    }

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
  }

  @visibleForTesting
  Future<void> syncCurrentToken() async {
    if (_firebaseUnavailable) return;

    final deviceId = _readDeviceId();
    if (deviceId == null) return;

    String? token;
    try {
      token = await _fcmTokenReader();
    } catch (e) {
      if (_isFirebaseNotInitializedError(e)) {
        _firebaseUnavailable = true;
        debugPrint('FCM token sync skipped: Firebase is not initialized.');
        return;
      }
      rethrow;
    }

    final normalizedToken = token?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      debugPrint('FCM token unavailable; skipping backend sync.');
      return;
    }

    await syncTokenWithBackend(deviceId: deviceId, fcmToken: normalizedToken);
  }

  @visibleForTesting
  Future<void> syncTokenWithBackend({
    required String deviceId,
    String? fcmToken,
  }) async {
    await _ref.read(syncDeviceFcmTokenUsecaseProvider)(
      SyncDeviceFcmTokenParams(deviceId: deviceId, fcmToken: fcmToken),
    );
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotificationsReady) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(channel);
    _localNotificationsReady = true;
  }

  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    if (!_localNotificationsReady) return;

    final title =
        message.notification?.title ??
        _readAsString(message.data, 'title') ??
        'Payhive';
    final body =
        message.notification?.body ??
        _readAsString(message.data, 'body') ??
        'You have a new notification';

    final payload = _buildPayloadFromRemoteMessage(message)
      ..['__title'] = title
      ..['__body'] = body
      ..['__createdAt'] = DateTime.now().toIso8601String();

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        markPayloadAsRead(decoded);
        _ref.read(notificationDeepLinkHandlerProvider).handlePayload(decoded);
      } else if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        markPayloadAsRead(map);
        _ref.read(notificationDeepLinkHandlerProvider).handlePayload(map);
      } else {
        _ref
            .read(notificationDeepLinkHandlerProvider)
            .handlePayloadJson(payload);
      }
    } catch (_) {
      _ref.read(notificationDeepLinkHandlerProvider).handlePayloadJson(payload);
    }

    unawaited(syncSessionState(force: true));
  }

  Map<String, dynamic> _buildPayloadFromRemoteMessage(RemoteMessage message) {
    final payload = Map<String, dynamic>.from(message.data);
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title != null && title.trim().isNotEmpty) {
      payload.putIfAbsent('__title', () => title.trim());
    }
    if (body != null && body.trim().isNotEmpty) {
      payload.putIfAbsent('__body', () => body.trim());
    }
    payload.putIfAbsent('__createdAt', () => DateTime.now().toIso8601String());
    return payload;
  }

  String? _readAsString(Map<String, dynamic> source, String key) {
    final raw = source[key];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  @visibleForTesting
  void markPayloadAsRead(Map<String, dynamic> payload) {
    final notificationId =
        _readAsString(payload, 'notificationId') ??
        _readAsString(payload, 'id');
    if (notificationId == null) return;

    unawaited(
      _ref.read(markNotificationReadUsecaseProvider)(
        MarkNotificationReadParams(notificationId: notificationId),
      ),
    );
  }

  @visibleForTesting
  Future<void> syncSessionState({required bool force}) async {
    final now = _now();
    final lastSyncAt = _lastSessionSyncAt;
    if (!force &&
        lastSyncAt != null &&
        now.difference(lastSyncAt) < _sessionSyncThrottle) {
      return;
    }

    final inFlight = _sessionSyncFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final nextSync = performSessionSync();
    _sessionSyncFuture = nextSync;
    try {
      await nextSync;
      _lastSessionSyncAt = _now();
    } finally {
      if (identical(_sessionSyncFuture, nextSync)) {
        _sessionSyncFuture = null;
      }
    }
  }

  @visibleForTesting
  Future<void> performSessionSync() async {
    await syncCurrentToken();
    await _ref
        .read(notificationViewModelProvider.notifier)
        .refreshUnreadCount();
  }

  String? _readDeviceId() {
    final deviceId = _ref.read(deviceStorageServiceProvider).getDeviceId();
    if (deviceId == null) return null;
    final normalized = deviceId.trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool _isFirebaseNotInitializedError(Object error) {
    final message = error.toString();
    return message.contains('[core/no-app]') ||
        message.contains('[core/not-initialized]');
  }
}
