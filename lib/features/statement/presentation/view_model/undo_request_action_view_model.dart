import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/undo_status_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
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
  late final UndoStatusStorageService _undoStatusStorageService;
  late final UserSessionService _userSessionService;

  @override
  UndoRequestActionState build() {
    _acceptUndoUsecase = ref.read(acceptUndoUsecaseProvider);
    _rejectUndoUsecase = ref.read(rejectUndoUsecaseProvider);
    _undoStatusStorageService = ref.read(undoStatusStorageServiceProvider);
    _userSessionService = ref.read(userSessionServiceProvider);
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
    final persistedStatus = _readPersistedStatus(fallbackData);
    final resolvedStatus = _resolveStatus(
      preferred: mappedStatus,
      secondary: persistedStatus,
    );

    state = UndoRequestActionState.initial().copyWith(
      fallbackData: fallbackData,
      requestId: requestId,
      lifecycleAction: lifecycleAction,
      status: resolvedStatus,
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

    await result.fold<Future<void>>(
      (failure) async {
        state = state.copyWith(
          isAccepting: false,
          errorMessage: failure.message,
        );
      },
      (success) async {
        state = state.copyWith(
          isAccepting: false,
          lifecycleAction: 'ACCEPTED',
          status: acceptedUndoStatus,
          request: success.request,
          receipt: success.receipt,
          errorMessage: null,
          actionMessage: 'Undo request accepted.',
        );
        await _persistStatus(
          status: acceptedUndoStatus,
          request: success.request,
          fallbackData: state.fallbackData,
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

    await result.fold<Future<void>>(
      (failure) async {
        state = state.copyWith(
          isRejecting: false,
          errorMessage: failure.message,
        );
      },
      (success) async {
        final resolvedStatus =
            mapUndoRequestStatus(success.status) ?? rejectedUndoStatus;
        state = state.copyWith(
          isRejecting: false,
          lifecycleAction: 'DENIED',
          status: resolvedStatus,
          request: success,
          errorMessage: null,
          actionMessage: 'Undo request rejected.',
        );
        await _persistStatus(
          status: resolvedStatus,
          request: success,
          fallbackData: state.fallbackData,
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

  UndoStatusUi? _readPersistedStatus(
    UndoRequestActionFallbackData fallbackData,
  ) {
    final userId = _userSessionService.getUserId()?.trim();
    if (userId == null || userId.isEmpty) return null;

    final txId =
        _normalizeNullable(fallbackData.originalTxId) ??
        _normalizeNullable(fallbackData.transactionId);
    if (txId == null) return null;

    final raw = _undoStatusStorageService.readStatus(
      userId: userId,
      txId: txId,
    );
    return deserializeUndoStatus(raw);
  }

  UndoStatusUi? _resolveStatus({
    UndoStatusUi? preferred,
    UndoStatusUi? secondary,
  }) {
    if (preferred == null) return secondary;
    if (secondary == null) return preferred;
    if (preferred.isTerminal) return preferred;
    if (secondary.isTerminal) return secondary;
    return preferred;
  }

  Future<void> _persistStatus({
    required UndoStatusUi status,
    required UndoRequestActionFallbackData fallbackData,
    UndoRequestEntity? request,
  }) async {
    final userId = _userSessionService.getUserId()?.trim();
    if (userId == null || userId.isEmpty) return;

    final txId =
        _normalizeNullable(request?.originalTxId) ??
        _normalizeNullable(fallbackData.originalTxId) ??
        _normalizeNullable(fallbackData.transactionId);
    if (txId == null) return;

    await _undoStatusStorageService.saveStatus(
      userId: userId,
      txId: txId,
      status: serializeUndoStatus(status),
    );
  }

  String? _normalizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
