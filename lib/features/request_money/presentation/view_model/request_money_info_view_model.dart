import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_info_state.dart';

final requestMoneyInfoViewModelProvider =
    NotifierProvider<RequestMoneyInfoViewModel, RequestMoneyInfoState>(
      RequestMoneyInfoViewModel.new,
    );

class RequestMoneyInfoViewModel extends Notifier<RequestMoneyInfoState> {
  late final GetMoneyRequestDetailUsecase _getMoneyRequestDetailUsecase;
  late final RespondMoneyRequestUsecase _respondMoneyRequestUsecase;
  late final UserSessionService _userSessionService;

  @override
  RequestMoneyInfoState build() {
    _getMoneyRequestDetailUsecase = ref.read(
      getMoneyRequestDetailUsecaseProvider,
    );
    _respondMoneyRequestUsecase = ref.read(respondMoneyRequestUsecaseProvider);
    _userSessionService = ref.read(userSessionServiceProvider);
    return RequestMoneyInfoState.initial();
  }

  Future<void> initialize({
    String? requestId,
    RequestMoneyInfoFallbackData fallbackData =
        const RequestMoneyInfoFallbackData(),
  }) async {
    final currentUserPhoneNumber = _userSessionService.getUserPhoneNumber();
    final normalizedRequestId = _normalizeNullable(requestId);

    state = RequestMoneyInfoState.initial().copyWith(
      requestId: normalizedRequestId,
      fallbackData: fallbackData,
      currentUserPhoneNumber: currentUserPhoneNumber,
    );

    if (normalizedRequestId == null) {
      return;
    }

    await loadRequestDetail(showLoader: true);
  }

  Future<void> loadRequestDetail({bool showLoader = false}) async {
    final requestId = state.requestId;
    if (requestId == null || requestId.isEmpty) return;

    if (showLoader) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        actionMessage: null,
      );
    } else {
      state = state.copyWith(errorMessage: null);
    }

    final result = await _getMoneyRequestDetailUsecase(
      GetMoneyRequestDetailParams(requestId: requestId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (request) {
        state = state.copyWith(
          request: request,
          isLoading: false,
          isRejecting: false,
          errorMessage: null,
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
      errorMessage: null,
      actionMessage: null,
    );

    final result = await _respondMoneyRequestUsecase(
      RespondMoneyRequestParams(
        requestId: requestId,
        action: MoneyRequestAction.reject,
      ),
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isRejecting: false,
          errorMessage: failure.message,
        );
        await loadRequestDetail(showLoader: false);
      },
      (request) async {
        state = state.copyWith(
          request: request,
          isRejecting: false,
          errorMessage: null,
          actionMessage: 'Money request rejected.',
        );
        await loadRequestDetail(showLoader: false);
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

  SendMoneyPrefillSnapshot? buildAcceptPrefill() {
    final request = state.request;
    if (request == null) return null;

    final requesterPhone = _normalizePhoneForTransfer(
      request.requester.phoneNumber,
    );
    if (requesterPhone == null) return null;

    final normalizedRemark = _normalizeNullable(request.remark);

    return SendMoneyPrefillSnapshot(
      phoneNumber: requesterPhone,
      amountInput: request.amount.toStringAsFixed(2),
      remark: normalizedRemark,
      sourceMoneyRequestId: request.id,
    );
  }

  String? _normalizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _normalizePhoneForTransfer(String? value) {
    if (value == null) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return digits;
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return null;
  }
}

class SendMoneyPrefillSnapshot {
  final String phoneNumber;
  final String amountInput;
  final String? remark;
  final String sourceMoneyRequestId;

  const SendMoneyPrefillSnapshot({
    required this.phoneNumber,
    required this.amountInput,
    this.remark,
    required this.sourceMoneyRequestId,
  });
}
