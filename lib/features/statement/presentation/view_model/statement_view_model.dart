import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/storage/undo_status_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

final statementViewModelProvider =
    NotifierProvider<StatementViewModel, StatementState>(
      StatementViewModel.new,
    );

class StatementViewModel extends Notifier<StatementState> {
  static const int pageSize = 10;
  static const int _undoNotificationHydrationLimit = 50;

  late final GetTransactionHistoryUsecase _historyUsecase;
  late final RequestUndoUsecase _requestUndoUsecase;
  late final GetNotificationsUsecase _getNotificationsUsecase;
  late final UserSessionService _userSessionService;
  late final UndoStatusStorageService _undoStatusStorageService;
  late final String? _currentUserId;

  @override
  StatementState build() {
    _historyUsecase = ref.read(getTransactionHistoryUsecaseProvider);
    _requestUndoUsecase = ref.read(requestUndoUsecaseProvider);
    _getNotificationsUsecase = ref.read(getNotificationsUsecaseProvider);
    _userSessionService = ref.read(userSessionServiceProvider);
    _undoStatusStorageService = ref.read(undoStatusStorageServiceProvider);
    _currentUserId = _userSessionService.getUserId();
    return StatementState.initial();
  }

  Future<void> loadInitial() async {
    final restoredStatuses = _readPersistedUndoStatuses();
    state = state.copyWith(
      status: StatementViewStatus.loading,
      isLoadingMore: false,
      errorMessage: null,
      page: 0,
      totalPages: 1,
      undoStatusByTxId: _mergeUndoStatuses(
        current: state.undoStatusByTxId,
        hydrated: restoredStatuses,
      ),
    );
    await _loadPage(page: 1, append: false);
  }

  Future<void> refresh() async {
    await _loadPage(page: 1, append: false, showPrimaryLoader: false);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status == StatementViewStatus.loading) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    await _loadPage(page: nextPage, append: true);
  }

  Future<void> applySearch(String search) async {
    final normalized = search.trim();
    if (normalized == state.search) return;
    state = state.copyWith(search: normalized);
    await loadInitial();
  }

  Future<void> applyDirection(StatementDirectionFilter direction) async {
    if (direction == state.direction) return;
    state = state.copyWith(direction: direction);
    await loadInitial();
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  void clearActionMessage() {
    if (state.actionMessage == null) return;
    state = state.copyWith(actionMessage: null);
  }

  Future<void> requestUndo(String txId) async {
    final normalizedTxId = txId.trim();
    if (normalizedTxId.isEmpty) return;
    if (state.requestingUndoTxIds.contains(normalizedTxId)) return;

    final nextRequesting = {...state.requestingUndoTxIds, normalizedTxId};
    state = state.copyWith(
      requestingUndoTxIds: nextRequesting,
      errorMessage: null,
      actionMessage: null,
    );

    final result = await _requestUndoUsecase(
      RequestUndoParams(txId: normalizedTxId),
    );
    var shouldPersistStatuses = false;

    result.fold(
      (failure) {
        final clearedRequesting = {...state.requestingUndoTxIds}
          ..remove(normalizedTxId);
        if (_isDuplicateUndoRequestFailure(failure)) {
          final nextStatuses = Map<String, UndoStatusUi>.from(
            state.undoStatusByTxId,
          );
          nextStatuses[normalizedTxId] = pendingUndoStatus;
          state = state.copyWith(
            requestingUndoTxIds: clearedRequesting,
            undoStatusByTxId: nextStatuses,
            errorMessage: null,
            actionMessage: failure.message,
          );
          shouldPersistStatuses = true;
          return;
        }

        state = state.copyWith(
          requestingUndoTxIds: clearedRequesting,
          errorMessage: failure.message,
        );
      },
      (undoRequest) {
        final status =
            mapUndoRequestStatus(undoRequest.status) ?? pendingUndoStatus;
        final resolvedTxId = _resolveTxIdForUndoRequest(
          undoRequest.originalTxId,
          fallbackTxId: normalizedTxId,
        );
        final nextStatuses = Map<String, UndoStatusUi>.from(
          state.undoStatusByTxId,
        );
        nextStatuses[resolvedTxId] = status;
        final clearedRequesting = {...state.requestingUndoTxIds}
          ..remove(normalizedTxId);

        state = state.copyWith(
          requestingUndoTxIds: clearedRequesting,
          undoStatusByTxId: nextStatuses,
          errorMessage: null,
          actionMessage: 'Undo request submitted.',
        );
        shouldPersistStatuses = true;
      },
    );

    if (shouldPersistStatuses) {
      await _persistUndoStatuses(state.undoStatusByTxId);
    }
  }

  Future<void> _loadPage({
    required int page,
    required bool append,
    bool showPrimaryLoader = true,
  }) async {
    if (!append && showPrimaryLoader) {
      state = state.copyWith(
        status: StatementViewStatus.loading,
        isLoadingMore: false,
        errorMessage: null,
      );
    }

    final result = await _historyUsecase(
      HistoryParams(
        page: page,
        limit: pageSize,
        search: state.search,
        direction: state.direction.apiValue,
      ),
    );

    var shouldHydrateUndoStatuses = false;

    result.fold(
      (failure) {
        if (append) {
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: failure.message,
          );
          return;
        }

        final nextStatus = state.transactions.isEmpty
            ? StatementViewStatus.error
            : StatementViewStatus.loaded;
        state = state.copyWith(
          status: nextStatus,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (history) {
        final normalizedItems = _normalizeDirections(history.transactions);
        final mergedItems = append
            ? [...state.transactions, ...normalizedItems]
            : normalizedItems;
        final resolvedPage = history.pagination?.page ?? page;
        final resolvedTotalPages =
            history.pagination?.totalPages ?? resolvedPage;

        state = state.copyWith(
          status: StatementViewStatus.loaded,
          transactions: mergedItems,
          page: resolvedPage,
          totalPages: resolvedTotalPages < 1 ? 1 : resolvedTotalPages,
          isLoadingMore: false,
          errorMessage: null,
        );
        shouldHydrateUndoStatuses = !append;
      },
    );

    if (shouldHydrateUndoStatuses) {
      await _hydrateUndoStatusesFromNotifications();
    }
  }

  List<ReceiptEntity> _normalizeDirections(List<ReceiptEntity> items) {
    final currentUserId = _userSessionService.getUserId();
    return items.map((item) {
      final normalized = _resolveDirection(item, currentUserId);
      if (normalized == item.direction) {
        return item;
      }
      return _copyWithDirection(item, normalized);
    }).toList();
  }

  String? _resolveDirection(ReceiptEntity item, String? currentUserId) {
    final apiDirection = item.direction?.toUpperCase();
    if (apiDirection == 'DEBIT' || apiDirection == 'CREDIT') {
      return apiDirection;
    }

    if (currentUserId == null || currentUserId.isEmpty) {
      return null;
    }

    if (item.from.id == currentUserId) {
      return 'DEBIT';
    }
    if (item.to.id == currentUserId) {
      return 'CREDIT';
    }
    return null;
  }

  ReceiptEntity _copyWithDirection(ReceiptEntity item, String? direction) {
    return ReceiptEntity(
      txId: item.txId,
      status: item.status,
      amount: item.amount,
      remark: item.remark,
      paymentType: item.paymentType,
      meta: item.meta,
      from: item.from,
      to: item.to,
      createdAt: item.createdAt,
      direction: direction,
    );
  }

  bool _isDuplicateUndoRequestFailure(Failure failure) {
    if (failure is! ApiFalilure) return false;
    if (failure.statusCode != 409) return false;
    final normalized = failure.message.trim().toLowerCase();
    return normalized.contains('undo already requested');
  }

  String _resolveTxIdForUndoRequest(
    String? originalTxId, {
    required String fallbackTxId,
  }) {
    final normalizedOriginal = originalTxId?.trim();
    if (normalizedOriginal != null && normalizedOriginal.isNotEmpty) {
      return normalizedOriginal;
    }
    return fallbackTxId;
  }

  Future<void> _hydrateUndoStatusesFromNotifications() async {
    final result = await _getNotificationsUsecase(
      const GetNotificationsParams(
        page: 1,
        limit: _undoNotificationHydrationLimit,
        type: 'UNDO_REQUEST',
      ),
    );
    var shouldPersistStatuses = false;

    result.fold((_) {}, (response) {
      final hydrated = _buildHydratedUndoStatuses(response.items);
      if (hydrated.isEmpty) return;

      final merged = _mergeUndoStatuses(
        current: state.undoStatusByTxId,
        hydrated: hydrated,
      );
      if (_isSameUndoStatusMap(state.undoStatusByTxId, merged)) {
        return;
      }

      state = state.copyWith(undoStatusByTxId: merged);
      shouldPersistStatuses = true;
    });

    if (shouldPersistStatuses) {
      await _persistUndoStatuses(state.undoStatusByTxId);
    }
  }

  Map<String, UndoStatusUi> _buildHydratedUndoStatuses(
    List<NotificationEntity> notifications,
  ) {
    final sorted = [...notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final hydrated = <String, UndoStatusUi>{};

    for (final item in sorted) {
      final data = item.data;
      if (data == null || data.isEmpty) continue;
      final originalTxId = _readFirstAsString(data, const [
        'originalTxId',
        'originalTransactionId',
        'txId',
        'transactionId',
      ]);
      if (originalTxId == null) continue;

      final action = _readFirstAsString(data, const ['action', 'status']);
      final mappedStatus = mapUndoLifecycleAction(action);
      if (mappedStatus == null) continue;

      hydrated.putIfAbsent(originalTxId, () => mappedStatus);
    }

    return hydrated;
  }

  Map<String, UndoStatusUi> _mergeUndoStatuses({
    required Map<String, UndoStatusUi> current,
    required Map<String, UndoStatusUi> hydrated,
  }) {
    final merged = <String, UndoStatusUi>{...current};

    hydrated.forEach((txId, status) {
      final existing = merged[txId];
      if (existing == null) {
        merged[txId] = status;
        return;
      }

      if (existing.isTerminal) {
        return;
      }

      if (status.isTerminal) {
        merged[txId] = status;
      }
    });

    return merged;
  }

  bool _isSameUndoStatusMap(
    Map<String, UndoStatusUi> a,
    Map<String, UndoStatusUi> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  Map<String, UndoStatusUi> _readPersistedUndoStatuses() {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) return const <String, UndoStatusUi>{};

    final stored = _undoStatusStorageService.readStatuses(userId: userId);
    if (stored.isEmpty) return const <String, UndoStatusUi>{};

    final resolved = <String, UndoStatusUi>{};
    stored.forEach((txId, rawStatus) {
      final status = deserializeUndoStatus(rawStatus);
      if (status == null) return;
      resolved[txId] = status;
    });
    return resolved;
  }

  Future<void> _persistUndoStatuses(Map<String, UndoStatusUi> statuses) async {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) return;

    final serialized = <String, String>{};
    statuses.forEach((txId, status) {
      serialized[txId] = serializeUndoStatus(status);
    });

    await _undoStatusStorageService.saveStatuses(
      userId: userId,
      statuses: serialized,
    );
  }

  String? _readFirstAsString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _readAsString(source, key);
      if (value != null) return value;
    }
    return null;
  }

  String? _readAsString(Map<String, dynamic> source, String key) {
    final raw = source[key];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }
}
