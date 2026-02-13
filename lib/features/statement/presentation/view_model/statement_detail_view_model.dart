import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/statement_detail_state.dart';

final statementDetailViewModelProvider =
    NotifierProvider<StatementDetailViewModel, StatementDetailState>(
      StatementDetailViewModel.new,
    );

class StatementDetailViewModel extends Notifier<StatementDetailState> {
  late final GetTransactionDetailUsecase _getTransactionDetailUsecase;

  @override
  StatementDetailState build() {
    _getTransactionDetailUsecase = ref.read(
      getTransactionDetailUsecaseProvider,
    );
    return StatementDetailState.initial();
  }

  Future<void> load({required String txId, ReceiptEntity? fallback}) async {
    final trimmedTxId = txId.trim();
    if (trimmedTxId.isEmpty) {
      state = state.copyWith(
        status: StatementDetailViewStatus.error,
        receipt: fallback,
        errorMessage: 'Transaction ID is required',
      );
      return;
    }

    state = state.copyWith(
      status: StatementDetailViewStatus.loading,
      receipt: fallback,
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
            errorMessage: failure.message,
          );
          return;
        }

        state = state.copyWith(
          status: StatementDetailViewStatus.error,
          receipt: null,
          errorMessage: failure.message,
        );
      },
      (receipt) {
        state = state.copyWith(
          status: StatementDetailViewStatus.loaded,
          receipt: receipt,
          errorMessage: null,
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }
}
