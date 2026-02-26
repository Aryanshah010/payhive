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
  NotificationPushService(this._ref);

  final Ref _ref;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localNotificationsReady = false;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openFromTapSub;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> init() async {
    if (_initialized) {
      _ref.read(notificationDeepLinkHandlerProvider).processPendingIfAny();
      return;
    }

    _initialized = true;
    try {
      await _initLocalNotifications();
      await _requestPermission();
      await _syncCurrentToken();
      _bindListeners();
      await _processInitialMessage();
      await _ref
          .read(notificationViewModelProvider.notifier)
          .refreshUnreadCount();
    } catch (e) {
      _initialized = false;
      debugPrint('Notification push init skipped: $e');
    }
  }

  Future<void> clearServerFcmTokenOnLogout() async {
    final deviceId = _ref.read(deviceStorageServiceProvider).getDeviceId();
    if (deviceId == null || deviceId.trim().isEmpty) return;

    await _syncTokenWithBackend(deviceId: deviceId.trim(), fcmToken: null);
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
      unawaited(
        _ref.read(notificationViewModelProvider.notifier).refreshUnreadCount(),
      );
    });

    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      final deviceId = _ref.read(deviceStorageServiceProvider).getDeviceId();
      if (deviceId == null || deviceId.trim().isEmpty) return;

      unawaited(
        _syncTokenWithBackend(deviceId: deviceId.trim(), fcmToken: token),
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
    _markPayloadAsRead(payload);
    _ref.read(notificationDeepLinkHandlerProvider).handlePayload(payload);
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _syncCurrentToken() async {
    final deviceId = _ref.read(deviceStorageServiceProvider).getDeviceId();
    if (deviceId == null || deviceId.trim().isEmpty) return;

    final token = await FirebaseMessaging.instance.getToken();
    await _syncTokenWithBackend(deviceId: deviceId.trim(), fcmToken: token);
  }

  Future<void> _syncTokenWithBackend({
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
        _markPayloadAsRead(decoded);
        _ref.read(notificationDeepLinkHandlerProvider).handlePayload(decoded);
      } else if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        _markPayloadAsRead(map);
        _ref.read(notificationDeepLinkHandlerProvider).handlePayload(map);
      } else {
        _ref
            .read(notificationDeepLinkHandlerProvider)
            .handlePayloadJson(payload);
      }
    } catch (_) {
      _ref.read(notificationDeepLinkHandlerProvider).handlePayloadJson(payload);
    }

    unawaited(
      _ref.read(notificationViewModelProvider.notifier).refreshUnreadCount(),
    );
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

  void _markPayloadAsRead(Map<String, dynamic> payload) {
    final notificationId = _readAsString(payload, 'notificationId');
    if (notificationId == null) return;

    unawaited(
      _ref.read(markNotificationReadUsecaseProvider)(
        MarkNotificationReadParams(notificationId: notificationId),
      ),
    );
  }
}
