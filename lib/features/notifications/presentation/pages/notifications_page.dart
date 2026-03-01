import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/services/notifications/notification_deeplink_handler.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/presentation/state/notification_state.dart';
import 'package:payhive/features/notifications/presentation/view_model/notification_view_model.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static const double _loadMoreThreshold = 240;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(notificationViewModelProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current <= _loadMoreThreshold) {
      ref.read(notificationViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationViewModelProvider);
    final viewModel = ref.read(notificationViewModelProvider.notifier);
    final isTablet = ResponsiveLayout.isTablet(context);

    ref.listen<NotificationState>(notificationViewModelProvider, (prev, next) {
      if (prev?.errorMessage == next.errorMessage) return;
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      SnackbarUtil.showError(context, message);
      viewModel.clearError();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: state.isMarkingAllRead || state.unreadCount == 0
                ? null
                : () => viewModel.markAllRead(),
            style: TextButton.styleFrom(
              textStyle: TextStyle(
                fontSize: isTablet ? 16 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: state.isMarkingAllRead
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mark all read'),
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state.status == NotificationViewStatus.loading &&
        state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == NotificationViewStatus.error &&
        state.notifications.isEmpty) {
      return ResponsiveLayout.constrainedContent(
        context,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_off_outlined, size: 46),
                const SizedBox(height: 10),
                const Text('Unable to load notifications.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(notificationViewModelProvider.notifier)
                      .loadInitial(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationViewModelProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsiveLayout.pagePadding(context),
          children: [
            ResponsiveLayout.constrainedContent(
              context,
              child: const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 52),
                    SizedBox(height: 16),
                    Text('No notifications yet.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveLayout.pagePadding(context, top: 12, bottom: 24),
        itemBuilder: (context, index) {
          if (index >= state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = state.notifications[index];
          return ResponsiveLayout.constrainedContent(
            context,
            child: _notificationTile(context, item),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
      ),
    );
  }

  Widget _notificationTile(BuildContext context, NotificationEntity item) {
    final createdAtText = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(item.createdAt.toLocal());
    final isTablet = ResponsiveLayout.isTablet(context);
    final scale = isTablet ? 1.12 : 1.0;
    final radius = isTablet ? 16.0 : 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () => _handleTap(item),
        child: Ink(
          padding: EdgeInsets.all(isTablet ? 16 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            color: item.isRead
                ? Theme.of(context).colorScheme.surface
                : Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isTablet ? 12 : 10,
                height: isTablet ? 12 : 10,
                margin: EdgeInsets.only(top: isTablet ? 7 : 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isRead
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: item.isRead
                            ? FontWeight.w600
                            : FontWeight.w700,
                        fontSize: 14 * scale,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 13.5 * scale),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      createdAtText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(NotificationEntity item) async {
    final viewModel = ref.read(notificationViewModelProvider.notifier);
    await viewModel.markNotificationRead(item.id);
    if (!mounted) return;

    ref
        .read(notificationDeepLinkHandlerProvider)
        .handleNotificationEntity(item);
  }
}
