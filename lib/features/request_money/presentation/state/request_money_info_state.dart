import 'package:equatable/equatable.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';

class RequestMoneyInfoFallbackData extends Equatable {
  final String? phoneNumber;
  final String? amountInput;
  final String? remark;
  final String? title;
  final String? body;
  final DateTime? createdAt;

  const RequestMoneyInfoFallbackData({
    this.phoneNumber,
    this.amountInput,
    this.remark,
    this.title,
    this.body,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    phoneNumber,
    amountInput,
    remark,
    title,
    body,
    createdAt,
  ];
}

class RequestMoneyInfoState extends Equatable {
  static const Object _unset = Object();

  final String? requestId;
  final RequestMoneyInfoFallbackData fallbackData;
  final MoneyRequestEntity? request;
  final String? currentUserPhoneNumber;
  final bool isLoading;
  final bool isRejecting;
  final String? errorMessage;
  final String? actionMessage;

  const RequestMoneyInfoState({
    required this.requestId,
    required this.fallbackData,
    this.request,
    this.currentUserPhoneNumber,
    required this.isLoading,
    required this.isRejecting,
    this.errorMessage,
    this.actionMessage,
  });

  factory RequestMoneyInfoState.initial() {
    return const RequestMoneyInfoState(
      requestId: null,
      fallbackData: RequestMoneyInfoFallbackData(),
      request: null,
      currentUserPhoneNumber: null,
      isLoading: false,
      isRejecting: false,
      errorMessage: null,
      actionMessage: null,
    );
  }

  bool get hasRequestId => (requestId?.trim().isNotEmpty ?? false);

  String get resolvedStatus {
    final normalized = request?.status.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return 'UNKNOWN';
    return normalized;
  }

  bool get isPending => resolvedStatus == 'PENDING';

  bool get isReceiver {
    final receiverPhone = _normalizePhone(request?.receiver.phoneNumber);
    final currentPhone = _normalizePhone(currentUserPhoneNumber);
    if (receiverPhone == null || currentPhone == null) return false;
    return receiverPhone == currentPhone;
  }

  bool get canTakeAction {
    if (!hasRequestId) return false;
    if (request == null) return false;
    if (!isPending) return false;
    if (!isReceiver) return false;
    return !isLoading && !isRejecting;
  }

  bool get isReadOnly => !canTakeAction;

  RequestMoneyInfoState copyWith({
    Object? requestId = _unset,
    RequestMoneyInfoFallbackData? fallbackData,
    Object? request = _unset,
    Object? currentUserPhoneNumber = _unset,
    bool? isLoading,
    bool? isRejecting,
    Object? errorMessage = _unset,
    Object? actionMessage = _unset,
  }) {
    return RequestMoneyInfoState(
      requestId: requestId == _unset ? this.requestId : requestId as String?,
      fallbackData: fallbackData ?? this.fallbackData,
      request: request == _unset
          ? this.request
          : request as MoneyRequestEntity?,
      currentUserPhoneNumber: currentUserPhoneNumber == _unset
          ? this.currentUserPhoneNumber
          : currentUserPhoneNumber as String?,
      isLoading: isLoading ?? this.isLoading,
      isRejecting: isRejecting ?? this.isRejecting,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      actionMessage: actionMessage == _unset
          ? this.actionMessage
          : actionMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    requestId,
    fallbackData,
    request,
    currentUserPhoneNumber,
    isLoading,
    isRejecting,
    errorMessage,
    actionMessage,
  ];
}

String? _normalizePhone(String? value) {
  if (value == null) return null;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return digits;
  if (digits.length > 10) {
    return digits.substring(digits.length - 10);
  }
  return null;
}
