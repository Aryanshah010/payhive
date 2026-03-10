import 'package:equatable/equatable.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';

enum NotificationViewStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  static const _unset = Object();

  final NotificationViewStatus status;
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final bool isMarkingAllRead;
  final String? errorMessage;

  const NotificationState({
    required this.status,
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
    required this.isMarkingAllRead,
    this.errorMessage,
  });

  factory NotificationState.initial() {
    return const NotificationState(
      status: NotificationViewStatus.initial,
      notifications: [],
      unreadCount: 0,
      page: 0,
      totalPages: 1,
      isLoadingMore: false,
      isMarkingAllRead: false,
      errorMessage: null,
    );
  }

  bool get hasMore => page < totalPages;

  NotificationState copyWith({
    NotificationViewStatus? status,
    List<NotificationEntity>? notifications,
    int? unreadCount,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    bool? isMarkingAllRead,
    Object? errorMessage = _unset,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    notifications,
    unreadCount,
    page,
    totalPages,
    isLoadingMore,
    isMarkingAllRead,
    errorMessage,
  ];
}
