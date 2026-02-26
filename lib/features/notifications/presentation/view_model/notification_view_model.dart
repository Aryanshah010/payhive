import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:payhive/features/notifications/presentation/state/notification_state.dart';

final notificationViewModelProvider =
    NotifierProvider<NotificationViewModel, NotificationState>(
      NotificationViewModel.new,
    );

class NotificationViewModel extends Notifier<NotificationState> {
  static const int pageSize = 10;

  GetNotificationsUsecase get _getNotificationsUsecase =>
      ref.read(getNotificationsUsecaseProvider);
  MarkNotificationReadUsecase get _markNotificationReadUsecase =>
      ref.read(markNotificationReadUsecaseProvider);
  MarkAllNotificationsReadUsecase get _markAllReadUsecase =>
      ref.read(markAllNotificationsReadUsecaseProvider);

  @override
  NotificationState build() {
    return NotificationState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: NotificationViewStatus.loading,
      isLoadingMore: false,
      errorMessage: null,
      page: 0,
      totalPages: 1,
    );

    await _loadPage(page: 1, append: false);
  }

  Future<void> refresh() async {
    await _loadPage(page: 1, append: false, showPrimaryLoader: false);
  }

  Future<void> refreshUnreadCount() async {
    final result = await _getNotificationsUsecase(
      const GetNotificationsParams(page: 1, limit: 1),
    );

    result.fold((_) {}, (response) {
      state = state.copyWith(unreadCount: response.unreadCount);
    });
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status == NotificationViewStatus.loading) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    await _loadPage(page: nextPage, append: true);
  }

  Future<bool> markNotificationRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return false;

    final existing = state.notifications.where((item) => item.id == id);
    if (existing.isNotEmpty && existing.first.isRead) {
      return true;
    }

    final result = await _markNotificationReadUsecase(
      MarkNotificationReadParams(notificationId: id),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (updated) {
        final nextItems = state.notifications
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
        final nextUnread = nextItems.where((item) => !item.isRead).length;
        final resolvedUnread = state.unreadCount > nextUnread
            ? state.unreadCount - 1
            : nextUnread;
        state = state.copyWith(
          notifications: nextItems,
          unreadCount: resolvedUnread < 0 ? 0 : resolvedUnread,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  Future<void> markAllRead() async {
    if (state.isMarkingAllRead) return;

    state = state.copyWith(isMarkingAllRead: true, errorMessage: null);

    final result = await _markAllReadUsecase();
    result.fold(
      (failure) {
        state = state.copyWith(
          isMarkingAllRead: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        final nextItems = state.notifications
            .map((item) => item.copyWith(isRead: true, readAt: DateTime.now()))
            .toList();
        state = state.copyWith(
          notifications: nextItems,
          unreadCount: 0,
          isMarkingAllRead: false,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> handleIncomingNotification() async {
    await refreshUnreadCount();
    if (state.notifications.isEmpty) return;
    await refresh();
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _loadPage({
    required int page,
    required bool append,
    bool showPrimaryLoader = true,
  }) async {
    if (!append && showPrimaryLoader) {
      state = state.copyWith(
        status: NotificationViewStatus.loading,
        isLoadingMore: false,
        errorMessage: null,
      );
    }

    final result = await _getNotificationsUsecase(
      GetNotificationsParams(page: page, limit: pageSize),
    );

    result.fold(
      (failure) {
        if (append) {
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: failure.message,
          );
          return;
        }

        final nextStatus = state.notifications.isEmpty
            ? NotificationViewStatus.error
            : NotificationViewStatus.loaded;
        state = state.copyWith(
          status: nextStatus,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (response) {
        final merged = append
            ? [...state.notifications, ...response.items]
            : response.items;

        state = state.copyWith(
          status: NotificationViewStatus.loaded,
          notifications: merged,
          unreadCount: response.unreadCount,
          page: response.page,
          totalPages: response.totalPages,
          isLoadingMore: false,
          errorMessage: null,
        );
      },
    );
  }
}
