import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/undo_request_action_state.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

final undoRequestActionViewModelProvider =
    NotifierProvider<UndoRequestActionViewModel, UndoRequestActionState>(
      UndoRequestActionViewModel.new,
    );

class UndoRequestActionViewModel extends Notifier<UndoRequestActionState> {
  late final AcceptUndoUsecase _acceptUndoUsecase;
  late final RejectUndoUsecase _rejectUndoUsecase;

  @override
  UndoRequestActionState build() {
    _acceptUndoUsecase = ref.read(acceptUndoUsecaseProvider);
    _rejectUndoUsecase = ref.read(rejectUndoUsecaseProvider);
    return UndoRequestActionState.initial();
  }

  void initialize({
    UndoRequestActionFallbackData fallbackData =
        const UndoRequestActionFallbackData(),
  }) {
    final requestId = _normalizeNullable(
      fallbackData.undoRequestId ?? fallbackData.transactionId,
    );
    final lifecycleAction = _normalizeNullable(
      fallbackData.action,
    )?.toUpperCase();
    final mappedStatus = mapUndoLifecycleAction(lifecycleAction);

    state = UndoRequestActionState.initial().copyWith(
      fallbackData: fallbackData,
      requestId: requestId,
      lifecycleAction: lifecycleAction,
      status: mappedStatus,
    );
  }

  Future<void> acceptRequest(String pin) async {
    if (!state.canTakeAction || state.isAccepting) return;

    final requestId = state.requestId;
    if (requestId == null || requestId.isEmpty) return;

    state = state.copyWith(
      isAccepting: true,
      isRejecting: false,
      errorMessage: null,
      actionMessage: null,
    );

    final result = await _acceptUndoUsecase(
      AcceptUndoParams(requestId: requestId, pin: pin),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isAccepting: false,
          errorMessage: failure.message,
        );
      },
      (success) {
        state = state.copyWith(
          isAccepting: false,
          lifecycleAction: 'ACCEPTED',
          status: acceptedUndoStatus,
          request: success.request,
          receipt: success.receipt,
          errorMessage: null,
          actionMessage: 'Undo request accepted.',
        );
      },
    );
  }

  Future<void> rejectRequest() async {
    if (!state.canTakeAction || state.isRejecting) return;

    final requestId = state.requestId;
    if (requestId == null || requestId.isEmpty) return;

    state = state.copyWith(
      isRejecting: true,
      isAccepting: false,
      errorMessage: null,
      actionMessage: null,
    );

    final result = await _rejectUndoUsecase(
      RejectUndoParams(requestId: requestId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isRejecting: false,
          errorMessage: failure.message,
        );
      },
      (success) {
        state = state.copyWith(
          isRejecting: false,
          lifecycleAction: 'DENIED',
          status: mapUndoRequestStatus(success.status) ?? rejectedUndoStatus,
          request: success,
          errorMessage: null,
          actionMessage: 'Undo request rejected.',
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  void clearActionMessage() {
    if (state.actionMessage == null) return;
    state = state.copyWith(actionMessage: null);
  }

  String? _normalizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
