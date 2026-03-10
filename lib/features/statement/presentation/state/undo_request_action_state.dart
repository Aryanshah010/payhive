import 'package:equatable/equatable.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

class UndoRequestActionFallbackData extends Equatable {
  final String? undoRequestId;
  final String? action;
  final String? originalTxId;
  final String? refundTxId;
  final String? transactionId;
  final double? amount;
  final String? requesterName;
  final String? requesterPhoneNumber;
  final String? receiverName;
  final String? receiverPhoneNumber;
  final String? title;
  final String? body;
  final DateTime? createdAt;

  const UndoRequestActionFallbackData({
    this.undoRequestId,
    this.action,
    this.originalTxId,
    this.refundTxId,
    this.transactionId,
    this.amount,
    this.requesterName,
    this.requesterPhoneNumber,
    this.receiverName,
    this.receiverPhoneNumber,
    this.title,
    this.body,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    undoRequestId,
    action,
    originalTxId,
    refundTxId,
    transactionId,
    amount,
    requesterName,
    requesterPhoneNumber,
    receiverName,
    receiverPhoneNumber,
    title,
    body,
    createdAt,
  ];
}

class UndoRequestActionState extends Equatable {
  static const Object _unset = Object();

  final UndoRequestActionFallbackData fallbackData;
  final String? requestId;
  final String? lifecycleAction;
  final UndoStatusUi? status;
  final UndoRequestEntity? request;
  final ReceiptEntity? receipt;
  final bool isAccepting;
  final bool isRejecting;
  final String? errorMessage;
  final String? actionMessage;

  const UndoRequestActionState({
    required this.fallbackData,
    required this.requestId,
    required this.lifecycleAction,
    required this.status,
    required this.request,
    required this.receipt,
    required this.isAccepting,
    required this.isRejecting,
    required this.errorMessage,
    required this.actionMessage,
  });

  factory UndoRequestActionState.initial() {
    return const UndoRequestActionState(
      fallbackData: UndoRequestActionFallbackData(),
      requestId: null,
      lifecycleAction: null,
      status: null,
      request: null,
      receipt: null,
      isAccepting: false,
      isRejecting: false,
      errorMessage: null,
      actionMessage: null,
    );
  }

  bool get hasRequestId => requestId != null && requestId!.trim().isNotEmpty;

  bool get isPending => status?.type == UndoStatusType.pending;

  bool get canTakeAction {
    if (!hasRequestId) return false;
    if (!isPending) return false;
    return !isAccepting && !isRejecting;
  }

  bool get isReadOnly => !canTakeAction;

  String? get resolvedOriginalTxId {
    final fromRequest = request?.originalTxId?.trim();
    if (fromRequest != null && fromRequest.isNotEmpty) {
      return fromRequest;
    }
    final fromReceiptMeta = receipt?.meta?['originalTxId']?.toString().trim();
    if (fromReceiptMeta != null && fromReceiptMeta.isNotEmpty) {
      return fromReceiptMeta;
    }
    final fromFallback = fallbackData.originalTxId?.trim();
    if (fromFallback != null && fromFallback.isNotEmpty) {
      return fromFallback;
    }
    return null;
  }

  String? get resolvedRefundTxId {
    final fromReceipt = receipt?.txId.trim();
    if (fromReceipt != null && fromReceipt.isNotEmpty) {
      return fromReceipt;
    }
    final fromFallback = fallbackData.refundTxId?.trim();
    if (fromFallback != null && fromFallback.isNotEmpty) {
      return fromFallback;
    }
    return null;
  }

  UndoRequestActionState copyWith({
    UndoRequestActionFallbackData? fallbackData,
    Object? requestId = _unset,
    Object? lifecycleAction = _unset,
    Object? status = _unset,
    Object? request = _unset,
    Object? receipt = _unset,
    bool? isAccepting,
    bool? isRejecting,
    Object? errorMessage = _unset,
    Object? actionMessage = _unset,
  }) {
    return UndoRequestActionState(
      fallbackData: fallbackData ?? this.fallbackData,
      requestId: requestId == _unset ? this.requestId : requestId as String?,
      lifecycleAction: lifecycleAction == _unset
          ? this.lifecycleAction
          : lifecycleAction as String?,
      status: status == _unset ? this.status : status as UndoStatusUi?,
      request: request == _unset ? this.request : request as UndoRequestEntity?,
      receipt: receipt == _unset ? this.receipt : receipt as ReceiptEntity?,
      isAccepting: isAccepting ?? this.isAccepting,
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
    fallbackData,
    requestId,
    lifecycleAction,
    status,
    request,
    receipt,
    isAccepting,
    isRejecting,
    errorMessage,
    actionMessage,
  ];
}
