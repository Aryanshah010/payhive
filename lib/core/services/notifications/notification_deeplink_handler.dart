import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/features/devices/presentation/pages/manage_devices_page.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:payhive/features/notifications/presentation/pages/notifications_page.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';

final notificationDeepLinkHandlerProvider =
    Provider<NotificationDeepLinkHandler>((_) => NotificationDeepLinkHandler());

class NotificationDeepLinkHandler {
  NotificationDeepLinkHandler();
  Map<String, dynamic>? _pendingPayload;

  void handlePayload(Map<String, dynamic> payload) {
    final normalized = _normalizePayload(payload);
    final didNavigate = _navigate(normalized);
    if (!didNavigate) {
      _pendingPayload = normalized;
    }
  }

  void handleNotificationEntity(NotificationEntity notification) {
    final payload = <String, dynamic>{
      'notificationId': notification.id,
      'type': notification.type,
      if (notification.txId != null) 'txId': notification.txId,
      if (notification.data != null) ...notification.data!,
      '__title': notification.title,
      '__body': notification.body,
      '__createdAt': notification.createdAt.toIso8601String(),
    };

    handlePayload(payload);
  }

  void handlePayloadJson(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) {
        handlePayload(decoded);
      } else if (decoded is Map) {
        handlePayload(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Ignore malformed local notification payloads.
    }
  }

  void processPendingIfAny() {
    final pending = _pendingPayload;
    if (pending == null) return;

    final didNavigate = _navigate(pending);
    if (didNavigate) {
      _pendingPayload = null;
    }
  }

  bool _navigate(Map<String, dynamic> payload) {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return false;

    final type = _resolveType(payload);
    final txId = _resolveTxId(payload);

    if ((type == 'PAYMENT_SUCCESS' || type == 'UNDO_REQUEST') && txId != null) {
      AppRoutes.push(context, StatementDetailPage(txId: txId));
      return true;
    }

    if (type == 'DEVICE_LOGIN') {
      AppRoutes.push(context, const ManageDevicesPage());
      return true;
    }

    if (type == 'REQUEST_MONEY') {
      if (txId != null) {
        AppRoutes.push(context, StatementDetailPage(txId: txId));
      } else {
        _openFallbackDetail(context, payload, type: type);
      }
      return true;
    }

    if (type.isNotEmpty) {
      _openFallbackDetail(context, payload, type: type);
      return true;
    }

    AppRoutes.push(context, const NotificationsPage());
    return true;
  }

  void _openFallbackDetail(
    BuildContext context,
    Map<String, dynamic> payload, {
    required String type,
  }) {
    final title =
        _readString(payload, '__title') ?? _readString(payload, 'title');
    final body = _readString(payload, '__body') ?? _readString(payload, 'body');
    final createdAtRaw = _readString(payload, '__createdAt');

    AppRoutes.push(
      context,
      NotificationDetailPage(
        title: title,
        body: body,
        type: type,
        createdAt: createdAtRaw == null
            ? null
            : DateTime.tryParse(createdAtRaw),
        data: _extractDetailMap(payload),
      ),
    );
  }

  String _resolveType(Map<String, dynamic> payload) {
    final rawType = payload['type'];
    final value = rawType?.toString().trim().toUpperCase();
    return value ?? '';
  }

  String? _resolveTxId(Map<String, dynamic> payload) {
    final raw = payload['txId'] ?? payload['transactionId'];
    if (raw == null) return null;
    final txId = raw.toString().trim();
    return txId.isEmpty ? null : txId;
  }

  Map<String, dynamic> _extractDetailMap(Map<String, dynamic> payload) {
    final data = <String, dynamic>{};

    for (final entry in payload.entries) {
      if (entry.key.startsWith('__')) continue;
      if (entry.key == 'type') continue;
      data[entry.key] = entry.value;
    }

    return data;
  }

  String? _readString(Map<String, dynamic> source, String key) {
    final raw = source[key];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> payload) {
    return Map<String, dynamic>.from(payload);
  }
}
