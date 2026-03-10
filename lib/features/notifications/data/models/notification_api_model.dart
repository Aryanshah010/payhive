import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';

class NotificationApiModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationApiModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationApiModel.fromJson(Map<String, dynamic> json) {
    return NotificationApiModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      data: _asNullableMap(json['data']),
      isRead: _toBool(json['isRead']),
      readAt: _toNullableDateTime(json['readAt']),
      createdAt:
          _toNullableDateTime(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _toNullableDateTime(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class NotificationListApiModel {
  final List<NotificationApiModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final int unreadCount;

  NotificationListApiModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.unreadCount,
  });

  factory NotificationListApiModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return NotificationListApiModel(
        items: const [],
        total: 0,
        page: 1,
        limit: 10,
        totalPages: 1,
        unreadCount: 0,
      );
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(NotificationApiModel.fromJson)
              .toList()
        : <NotificationApiModel>[];

    final page = _toInt(json['page']) ?? 1;
    final limit = _toInt(json['limit']) ?? 10;
    final total = _toInt(json['total']) ?? items.length;
    final totalPages =
        _toInt(json['totalPages']) ??
        ((total == 0) ? 1 : (total / limit).ceil());

    return NotificationListApiModel(
      items: items,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages < 1 ? 1 : totalPages,
      unreadCount: _toInt(json['unreadCount']) ?? 0,
    );
  }

  NotificationListEntity toEntity() {
    return NotificationListEntity(
      items: items.map((e) => e.toEntity()).toList(),
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      unreadCount: unreadCount,
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return false;
}

DateTime? _toNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return null;
}

Map<String, dynamic>? _asNullableMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
