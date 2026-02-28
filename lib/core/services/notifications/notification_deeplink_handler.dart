import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/features/devices/presentation/pages/manage_devices_page.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:payhive/features/notifications/presentation/pages/notifications_page.dart';
import 'package:payhive/features/request_money/presentation/pages/request_money_info_page.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_info_state.dart';
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
      AppRoutes.push(
        context,
        RequestMoneyInfoPage(
          requestId: _resolveMoneyRequestId(payload),
          fallbackData: RequestMoneyInfoFallbackData(
            phoneNumber: _resolveRequesterPhoneNumber(payload),
            amountInput: _resolveAmountInput(payload),
            remark: _resolveRemark(payload),
            title:
                _readString(payload, '__title') ??
                _readString(payload, 'title'),
            body:
                _readString(payload, '__body') ?? _readString(payload, 'body'),
            createdAt: _resolveCreatedAt(payload),
          ),
        ),
      );
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

  String? _resolveRequesterPhoneNumber(Map<String, dynamic> payload) {
    final rawPhone = _readFirstString(payload, const [
      'requesterPhoneNumber',
      'requesterPhone',
      'fromPhoneNumber',
      'phoneNumber',
    ]);
    if (rawPhone == null) return null;

    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) {
      return digitsOnly;
    }
    if (digitsOnly.length > 10) {
      final lastTenDigits = digitsOnly.substring(digitsOnly.length - 10);
      if (RegExp(r'^\d{10}$').hasMatch(lastTenDigits)) {
        return lastTenDigits;
      }
    }
    return null;
  }

  String? _resolveAmountInput(Map<String, dynamic> payload) {
    final rawAmount = _readFirstString(payload, const [
      'amount',
      'requestedAmount',
    ]);
    if (rawAmount == null) return null;
    return _normalizeAmountInput(rawAmount);
  }

  String? _resolveRemark(Map<String, dynamic> payload) {
    return _readFirstString(payload, const ['remark', 'message', 'note']);
  }

  String? _resolveMoneyRequestId(Map<String, dynamic> payload) {
    return _readFirstString(payload, const [
      'moneyRequestId',
      'requestId',
      'money_request_id',
    ]);
  }

  DateTime? _resolveCreatedAt(Map<String, dynamic> payload) {
    final createdAtRaw =
        _readString(payload, '__createdAt') ??
        _readString(payload, 'createdAt');
    if (createdAtRaw == null) return null;
    return DateTime.tryParse(createdAtRaw);
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

  String? _readFirstString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _readString(source, key);
      if (value != null) return value;
    }
    return null;
  }

  String? _normalizeAmountInput(String value) {
    var sanitized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (sanitized.isEmpty) return null;

    final firstDot = sanitized.indexOf('.');
    if (firstDot >= 0) {
      final integerPart = sanitized.substring(0, firstDot);
      var decimalPart = sanitized.substring(firstDot + 1).replaceAll('.', '');
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      sanitized = decimalPart.isEmpty
          ? '$integerPart.'
          : '$integerPart.$decimalPart';
    }

    if (sanitized.startsWith('.')) {
      sanitized = '0$sanitized';
    }

    return sanitized.isEmpty ? null : sanitized;
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> payload) {
    final normalized = <String, dynamic>{};

    for (final entry in payload.entries) {
      if (entry.key == 'data') continue;
      normalized[entry.key] = entry.value;
    }

    _mergeNestedData(normalized, payload['data']);

    return normalized;
  }

  void _mergeNestedData(Map<String, dynamic> target, dynamic dataValue) {
    final nestedMap = _decodeMapValue(dataValue);
    if (nestedMap == null) return;

    for (final entry in nestedMap.entries) {
      if (entry.key == 'data') {
        _mergeNestedData(target, entry.value);
        continue;
      }
      target[entry.key] = entry.value;
    }
  }

  Map<String, dynamic>? _decodeMapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded);
        }
        if (decoded is Map) {
          return decoded.map(
            (key, mapValue) => MapEntry(key.toString(), mapValue),
          );
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
