import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
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

  const NotificationEntity({
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

  String? get txId {
    final meta = data;
    if (meta == null || meta.isEmpty) return null;

    final rawTx = meta['txId'] ?? meta['transactionId'];
    if (rawTx == null) return null;

    final value = rawTx.toString().trim();
    return value.isEmpty ? null : value;
  }

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    body,
    type,
    data,
    isRead,
    readAt,
    createdAt,
    updatedAt,
  ];
}

class NotificationListEntity extends Equatable {
  final List<NotificationEntity> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final int unreadCount;

  const NotificationListEntity({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [
    items,
    total,
    page,
    limit,
    totalPages,
    unreadCount,
  ];
}
