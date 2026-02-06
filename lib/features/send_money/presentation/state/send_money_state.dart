import 'package:equatable/equatable.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';

enum SendMoneyStatus {
  idle,
  loading,
  lookupSuccess,
  previewSuccess,
  confirmSuccess,
  error,
  locked,
}

enum SendMoneyAction { none, lookup, preview, confirm }

class SendMoneyState extends Equatable {
  static const Object _unset = Object();

  final SendMoneyStatus status;
  final SendMoneyAction action;
  final String phoneNumber;
  final RecipientEntity? recipient;
  final String amountInput;
  final String? remark;
  final String? warning;
  final ReceiptEntity? receipt;
  final String? errorMessage;
  final int lockoutRemainingMs;

  const SendMoneyState({
    required this.status,
    required this.action,
    required this.phoneNumber,
    required this.amountInput,
    this.recipient,
    this.remark,
    this.warning,
    this.receipt,
    this.errorMessage,
    required this.lockoutRemainingMs,
  });

  factory SendMoneyState.initial() {
    return const SendMoneyState(
      status: SendMoneyStatus.idle,
      action: SendMoneyAction.none,
      phoneNumber: '',
      amountInput: '',
      lockoutRemainingMs: 0,
    );
  }

  SendMoneyState copyWith({
    SendMoneyStatus? status,
    SendMoneyAction? action,
    String? phoneNumber,
    Object? recipient = _unset,
    String? amountInput,
    Object? remark = _unset,
    Object? warning = _unset,
    Object? receipt = _unset,
    Object? errorMessage = _unset,
    int? lockoutRemainingMs,
  }) {
    return SendMoneyState(
      status: status ?? this.status,
      action: action ?? this.action,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      recipient:
          recipient == _unset ? this.recipient : recipient as RecipientEntity?,
      amountInput: amountInput ?? this.amountInput,
      remark: remark == _unset ? this.remark : remark as String?,
      warning: warning == _unset ? this.warning : warning as String?,
      receipt: receipt == _unset ? this.receipt : receipt as ReceiptEntity?,
      errorMessage:
          errorMessage == _unset
              ? this.errorMessage
              : errorMessage as String?,
      lockoutRemainingMs: lockoutRemainingMs ?? this.lockoutRemainingMs,
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    phoneNumber,
    recipient,
    amountInput,
    remark,
    warning,
    receipt,
    errorMessage,
    lockoutRemainingMs,
  ];
}
