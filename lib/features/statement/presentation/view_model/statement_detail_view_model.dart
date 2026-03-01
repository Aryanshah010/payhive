import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/undo_status_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/statement_detail_state.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

final statementDetailViewModelProvider =
    NotifierProvider<StatementDetailViewModel, StatementDetailState>(
      StatementDetailViewModel.new,
    );

class StatementDetailViewModel extends Notifier<StatementDetailState> {
  late final GetTransactionDetailUsecase _getTransactionDetailUsecase;
  late final UndoStatusStorageService _undoStatusStorageService;
  late final UserSessionService _userSessionService;

  @override
  StatementDetailState build() {
    _getTransactionDetailUsecase = ref.read(
      getTransactionDetailUsecaseProvider,
    );
    _undoStatusStorageService = ref.read(undoStatusStorageServiceProvider);
    _userSessionService = ref.read(userSessionServiceProvider);
    return StatementDetailState.initial();
  }

  Future<void> load({
    required String txId,
    ReceiptEntity? fallback,
    UndoStatusUi? initialUndoStatus,
  }) async {
    final trimmedTxId = txId.trim();
    if (trimmedTxId.isEmpty) {
      state = state.copyWith(
        status: StatementDetailViewStatus.error,
        receipt: fallback,
        undoStatus: initialUndoStatus,
        errorMessage: 'Transaction ID is required',
      );
      return;
    }

    final persistedUndoStatus = _readPersistedUndoStatus(trimmedTxId);
    final resolvedInitialUndo = _resolveUndoStatus(
      preferred: initialUndoStatus,
      secondary: persistedUndoStatus,
    );

    state = state.copyWith(
      status: StatementDetailViewStatus.loading,
      receipt: fallback,
      undoStatus: resolvedInitialUndo,
      errorMessage: null,
    );

    final result = await _getTransactionDetailUsecase(
      DetailParams(txId: trimmedTxId),
    );

    result.fold(
      (failure) {
        if (fallback != null) {
          state = state.copyWith(
            status: StatementDetailViewStatus.loaded,
            receipt: fallback,
            undoStatus: _resolveUndoStatusForReceipt(
              txId: trimmedTxId,
              receipt: fallback,
              initial: resolvedInitialUndo,
            ),
            errorMessage: failure.message,
          );
          return;
        }

        state = state.copyWith(
          status: StatementDetailViewStatus.error,
          receipt: null,
          undoStatus: resolvedInitialUndo,
          errorMessage: failure.message,
        );
      },
      (receipt) {
        state = state.copyWith(
          status: StatementDetailViewStatus.loaded,
          receipt: receipt,
          undoStatus: _resolveUndoStatusForReceipt(
            txId: trimmedTxId,
            receipt: receipt,
            initial: resolvedInitialUndo,
          ),
          errorMessage: null,
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  UndoStatusUi? _resolveUndoStatusForReceipt({
    required String txId,
    required ReceiptEntity receipt,
    UndoStatusUi? initial,
  }) {
    final receiptTxId = receipt.txId.trim();
    final metaOriginalTxId = receipt.meta?['originalTxId']?.toString().trim();
    final metaTxId = receipt.meta?['txId']?.toString().trim();
    final metaTransactionId = receipt.meta?['transactionId']?.toString().trim();

    final byReceiptTxId = receiptTxId.isEmpty
        ? null
        : _readPersistedUndoStatus(receiptTxId);
    final byInputTxId = _readPersistedUndoStatus(txId);
    final byMetaOriginal = metaOriginalTxId == null || metaOriginalTxId.isEmpty
        ? null
        : _readPersistedUndoStatus(metaOriginalTxId);
    final byMetaTxId = metaTxId == null || metaTxId.isEmpty
        ? null
        : _readPersistedUndoStatus(metaTxId);
    final byMetaTransactionId =
        metaTransactionId == null || metaTransactionId.isEmpty
        ? null
        : _readPersistedUndoStatus(metaTransactionId);

    return _resolveUndoStatus(
      preferred: initial,
      secondary:
          byReceiptTxId ??
          byInputTxId ??
          byMetaOriginal ??
          byMetaTxId ??
          byMetaTransactionId,
    );
  }

  UndoStatusUi? _resolveUndoStatus({
    UndoStatusUi? preferred,
    UndoStatusUi? secondary,
  }) {
    if (preferred == null) return secondary;
    if (secondary == null) return preferred;
    if (preferred.isTerminal) return preferred;
    if (secondary.isTerminal) return secondary;
    return preferred;
  }

  UndoStatusUi? _readPersistedUndoStatus(String txId) {
    final userId = _userSessionService.getUserId()?.trim();
    final normalizedTxId = txId.trim();
    if (userId == null || userId.isEmpty || normalizedTxId.isEmpty) {
      return null;
    }

    final raw = _undoStatusStorageService.readStatus(
      userId: userId,
      txId: normalizedTxId,
    );
    return deserializeUndoStatus(raw);
  }
}
