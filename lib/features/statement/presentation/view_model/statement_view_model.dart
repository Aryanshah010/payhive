import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';

final statementViewModelProvider =
    NotifierProvider<StatementViewModel, StatementState>(
      StatementViewModel.new,
    );

class StatementViewModel extends Notifier<StatementState> {
  static const int pageSize = 10;

  late final GetTransactionHistoryUsecase _historyUsecase;
  late final UserSessionService _userSessionService;

  @override
  StatementState build() {
    _historyUsecase = ref.read(getTransactionHistoryUsecaseProvider);
    _userSessionService = ref.read(userSessionServiceProvider);
    return StatementState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: StatementViewStatus.loading,
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
      },
    );
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
      from: item.from,
      to: item.to,
      createdAt: item.createdAt,
      direction: direction,
    );
  }
}
