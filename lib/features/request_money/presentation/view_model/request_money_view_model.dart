import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_state.dart';

final requestMoneyViewModelProvider =
    NotifierProvider<RequestMoneyViewModel, RequestMoneyState>(
      RequestMoneyViewModel.new,
    );

class RequestMoneyViewModel extends Notifier<RequestMoneyState> {
  static const int pageSize = 10;
  static final RegExp _phonePattern = RegExp(r'^\d{10}$');
  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{0,2})?$');

  late final CreateMoneyRequestUsecase _createMoneyRequestUsecase;
  late final GetOutgoingMoneyRequestsUsecase _getOutgoingMoneyRequestsUsecase;
  late final RespondMoneyRequestUsecase _respondMoneyRequestUsecase;
  Future<void>? _topLevelLoadFuture;

  @override
  RequestMoneyState build() {
    _createMoneyRequestUsecase = ref.read(createMoneyRequestUsecaseProvider);
    _getOutgoingMoneyRequestsUsecase = ref.read(
      getOutgoingMoneyRequestsUsecaseProvider,
    );
    _respondMoneyRequestUsecase = ref.read(respondMoneyRequestUsecaseProvider);

    return RequestMoneyState.initial();
  }

  void setPhoneNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'\D'), '').trim();
    if (normalized == state.phoneNumber) return;
    state = state.copyWith(
      phoneNumber: normalized,
      phoneError: state.showValidationErrors
          ? _validatePhone(normalized)
          : null,
    );
  }

  void setAmountInput(String value) {
    final normalized = _normalizeAmountInput(value);
    if (normalized == state.amountInput) return;
    state = state.copyWith(
      amountInput: normalized,
      amountError: state.showValidationErrors
          ? _validateAmountInput(normalized)
          : null,
    );
  }

  void setRemark(String value) {
    final trimmed = value.trim();
    final normalized = trimmed.isEmpty ? null : trimmed;
    if (normalized == state.remark) return;
    state = state.copyWith(
      remark: normalized,
      remarkError: state.showValidationErrors
          ? _validateRemark(normalized)
          : null,
    );
  }

  Future<void> loadInitialPending() async {
    if (state.isLoadingMore) return;
    await _runTopLevelLoad(() {
      return _loadPage(
        page: 1,
        append: false,
        showPrimaryLoader: true,
        action: RequestMoneyAction.loadInitial,
      );
    });
  }

  Future<void> refreshPending() async {
    if (state.isLoadingMore) return;
    await _runTopLevelLoad(() {
      return _loadPage(
        page: 1,
        append: false,
        showPrimaryLoader: false,
        action: RequestMoneyAction.refresh,
      );
    });
  }

  Future<void> _runTopLevelLoad(Future<void> Function() action) async {
    final inFlight = _topLevelLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final nextLoad = action();
    _topLevelLoadFuture = nextLoad;
    try {
      await nextLoad;
    } finally {
      if (identical(_topLevelLoadFuture, nextLoad)) {
        _topLevelLoadFuture = null;
      }
    }
  }

  Future<void> loadMorePending() async {
    if (state.isLoadingMore || !state.hasMore) return;
    if (state.status == RequestMoneyStatus.loading &&
        state.action != RequestMoneyAction.loadMore) {
      return;
    }

    final nextPage = state.page + 1;
    await _loadPage(
      page: nextPage,
      append: true,
      showPrimaryLoader: false,
      action: RequestMoneyAction.loadMore,
    );
  }

  Future<void> submitRequest() async {
    if (state.status == RequestMoneyStatus.loading) {
      return;
    }

    if (!_validateForm()) {
      return;
    }

    final amount = double.tryParse(state.amountInput) ?? 0;

    state = state.copyWith(
      status: RequestMoneyStatus.loading,
      action: RequestMoneyAction.submit,
      phoneError: null,
      amountError: null,
      remarkError: null,
      showValidationErrors: false,
      errorMessage: null,
    );

    final result = await _createMoneyRequestUsecase(
      CreateMoneyRequestParams(
        toPhoneNumber: state.phoneNumber,
        amount: amount,
        remark: state.remark,
      ),
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          status: _resolveNonLoadingStatus(),
          action: RequestMoneyAction.none,
          errorMessage: failure.message,
        );
      },
      (_) async {
        state = state.copyWith(
          status: RequestMoneyStatus.success,
          action: RequestMoneyAction.submit,
          amountInput: '',
          remark: null,
          phoneError: null,
          amountError: null,
          remarkError: null,
          showValidationErrors: false,
          errorMessage: null,
        );

        await refreshPending();
      },
    );
  }

  Future<void> cancelRequest(String requestId) async {
    final normalized = requestId.trim();
    if (normalized.isEmpty) return;
    if (state.activeCancelRequestId != null) return;

    state = state.copyWith(
      status: RequestMoneyStatus.loading,
      action: RequestMoneyAction.cancel,
      activeCancelRequestId: normalized,
      errorMessage: null,
    );

    final result = await _respondMoneyRequestUsecase(
      RespondMoneyRequestParams(
        requestId: normalized,
        action: MoneyRequestAction.cancel,
      ),
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          status: _resolveNonLoadingStatus(),
          action: RequestMoneyAction.none,
          activeCancelRequestId: null,
          errorMessage: failure.message,
        );
      },
      (_) async {
        state = state.copyWith(
          status: RequestMoneyStatus.success,
          action: RequestMoneyAction.cancel,
          activeCancelRequestId: null,
          errorMessage: null,
        );

        await refreshPending();
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  void clearStatus() {
    if (state.status == RequestMoneyStatus.loading) return;

    final nextStatus = state.pendingRequests.isEmpty
        ? RequestMoneyStatus.initial
        : RequestMoneyStatus.loaded;

    state = state.copyWith(
      status: nextStatus,
      action: RequestMoneyAction.none,
      errorMessage: null,
    );
  }

  Future<void> _loadPage({
    required int page,
    required bool append,
    required bool showPrimaryLoader,
    required RequestMoneyAction action,
  }) async {
    if (append) {
      state = state.copyWith(
        action: action,
        isLoadingMore: true,
        pendingErrorMessage: null,
      );
    } else if (showPrimaryLoader) {
      state = state.copyWith(
        status: RequestMoneyStatus.loading,
        action: action,
        isLoadingMore: false,
        pendingErrorMessage: null,
      );
    } else {
      state = state.copyWith(action: action, pendingErrorMessage: null);
    }

    final result = await _getOutgoingMoneyRequestsUsecase(
      GetOutgoingMoneyRequestsParams(page: page, limit: pageSize),
    );

    result.fold(
      (failure) {
        final hasPending = state.pendingRequests.isNotEmpty;
        state = state.copyWith(
          status: hasPending
              ? RequestMoneyStatus.loaded
              : RequestMoneyStatus.error,
          action: RequestMoneyAction.none,
          isLoadingMore: false,
          pendingErrorMessage: failure.message,
          activeCancelRequestId: null,
        );
      },
      (response) {
        final merged = append
            ? [...state.pendingRequests, ...response.items]
            : response.items;

        state = state.copyWith(
          status: RequestMoneyStatus.loaded,
          action: RequestMoneyAction.none,
          pendingRequests: merged,
          page: response.page,
          totalPages: response.totalPages,
          isLoadingMore: false,
          pendingErrorMessage: null,
          activeCancelRequestId: null,
        );
      },
    );
  }

  bool _validateForm() {
    final phoneError = _validatePhone(state.phoneNumber);
    final amountError = _validateAmountInput(state.amountInput);
    final remarkError = _validateRemark(state.remark);

    state = state.copyWith(
      phoneError: phoneError,
      amountError: amountError,
      remarkError: remarkError,
      showValidationErrors: true,
    );

    return phoneError == null && amountError == null && remarkError == null;
  }

  String? _validatePhone(String input) {
    final cleaned = input.trim();
    if (!_phonePattern.hasMatch(cleaned)) {
      return 'Enter a valid 10-digit mobile number.';
    }
    return null;
  }

  String? _validateAmountInput(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return 'Amount is required.';
    }
    if (!_amountPattern.hasMatch(cleaned)) {
      return 'Use up to 2 decimal places.';
    }

    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0) {
      return 'Amount must be greater than 0.';
    }

    return null;
  }

  String? _validateRemark(String? remark) {
    final value = remark?.trim();
    if (value != null && value.length > 140) {
      return 'Remark must be 140 characters or less.';
    }
    return null;
  }

  RequestMoneyStatus _resolveNonLoadingStatus() {
    return state.pendingRequests.isEmpty
        ? RequestMoneyStatus.initial
        : RequestMoneyStatus.loaded;
  }

  String _normalizeAmountInput(String value) {
    var sanitized = value.replaceAll(RegExp(r'[^0-9.]'), '');

    if (sanitized.isEmpty) {
      return '';
    }

    final firstDot = sanitized.indexOf('.');
    if (firstDot >= 0) {
      final integerPart = sanitized.substring(0, firstDot);
      var decimalPart = sanitized.substring(firstDot + 1).replaceAll('.', '');
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      sanitized = decimalPart.isEmpty
          ? '$integerPart.'
          : '$integerPart.$decimalPart';
    }

    if (sanitized.startsWith('.')) {
      sanitized = '0$sanitized';
    }

    return sanitized;
  }
}
