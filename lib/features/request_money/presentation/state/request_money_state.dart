import 'package:equatable/equatable.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';

enum RequestMoneyStatus { initial, loading, loaded, success, error }

enum RequestMoneyAction { none, loadInitial, refresh, loadMore, submit, cancel }

class RequestMoneyState extends Equatable {
  static const Object _unset = Object();

  final RequestMoneyStatus status;
  final RequestMoneyAction action;

  final String phoneNumber;
  final String amountInput;
  final String? remark;

  final List<MoneyRequestEntity> pendingRequests;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  final String? phoneError;
  final String? amountError;
  final String? remarkError;
  final bool showValidationErrors;
  final String? pendingErrorMessage;
  final String? errorMessage;
  final String? activeCancelRequestId;

  const RequestMoneyState({
    required this.status,
    required this.action,
    required this.phoneNumber,
    required this.amountInput,
    this.remark,
    required this.pendingRequests,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
    this.phoneError,
    this.amountError,
    this.remarkError,
    required this.showValidationErrors,
    this.pendingErrorMessage,
    this.errorMessage,
    this.activeCancelRequestId,
  });

  factory RequestMoneyState.initial() {
    return const RequestMoneyState(
      status: RequestMoneyStatus.initial,
      action: RequestMoneyAction.none,
      phoneNumber: '',
      amountInput: '',
      remark: null,
      pendingRequests: [],
      page: 0,
      totalPages: 1,
      isLoadingMore: false,
      phoneError: null,
      amountError: null,
      remarkError: null,
      showValidationErrors: false,
      pendingErrorMessage: null,
      errorMessage: null,
      activeCancelRequestId: null,
    );
  }

  bool get hasMore => page < totalPages;

  bool get isSubmitting =>
      status == RequestMoneyStatus.loading &&
      action == RequestMoneyAction.submit;

  bool get isSubmitEnabled => !isSubmitting;

  RequestMoneyState copyWith({
    RequestMoneyStatus? status,
    RequestMoneyAction? action,
    String? phoneNumber,
    String? amountInput,
    Object? remark = _unset,
    List<MoneyRequestEntity>? pendingRequests,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    Object? phoneError = _unset,
    Object? amountError = _unset,
    Object? remarkError = _unset,
    bool? showValidationErrors,
    Object? pendingErrorMessage = _unset,
    Object? errorMessage = _unset,
    Object? activeCancelRequestId = _unset,
  }) {
    return RequestMoneyState(
      status: status ?? this.status,
      action: action ?? this.action,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amountInput: amountInput ?? this.amountInput,
      remark: remark == _unset ? this.remark : remark as String?,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      phoneError: phoneError == _unset
          ? this.phoneError
          : phoneError as String?,
      amountError: amountError == _unset
          ? this.amountError
          : amountError as String?,
      remarkError: remarkError == _unset
          ? this.remarkError
          : remarkError as String?,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      pendingErrorMessage: pendingErrorMessage == _unset
          ? this.pendingErrorMessage
          : pendingErrorMessage as String?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      activeCancelRequestId: activeCancelRequestId == _unset
          ? this.activeCancelRequestId
          : activeCancelRequestId as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    phoneNumber,
    amountInput,
    remark,
    pendingRequests,
    page,
    totalPages,
    isLoadingMore,
    phoneError,
    amountError,
    remarkError,
    showValidationErrors,
    pendingErrorMessage,
    errorMessage,
    activeCancelRequestId,
  ];
}
