import 'package:equatable/equatable.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';

enum RequestMoneyStatus { initial, loading, loaded, success, error }

enum RequestMoneyAction { none, loadInitial, refresh, loadMore, submit, cancel }

class RequestMoneyState extends Equatable {
  static const Object _unset = Object();
  static final RegExp _phonePattern = RegExp(r'^\d{10}$');

  final RequestMoneyStatus status;
  final RequestMoneyAction action;

  final String phoneNumber;
  final String amountInput;
  final String? remark;

  final List<MoneyRequestEntity> pendingRequests;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

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
      errorMessage: null,
      activeCancelRequestId: null,
    );
  }

  bool get hasMore => page < totalPages;

  bool get isSubmitting =>
      status == RequestMoneyStatus.loading &&
      action == RequestMoneyAction.submit;

  bool get isSubmitEnabled {
    if (isSubmitting) return false;
    if (!_phonePattern.hasMatch(phoneNumber.trim())) return false;

    final amount = double.tryParse(amountInput);
    if (amount == null || amount <= 0) return false;
    return true;
  }

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
    errorMessage,
    activeCancelRequestId,
  ];
}
