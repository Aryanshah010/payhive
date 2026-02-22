import 'package:equatable/equatable.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';

enum BankTransferStatus {
  idle,
  loading,
  previewSuccess,
  confirmSuccess,
  error,
  locked,
}

enum BankTransferAction { none, preview, confirm }

class BankTransferState extends Equatable {
  static const Object _unset = Object();

  final BankTransferStatus status;
  final BankTransferAction action;
  final String bankName;
  final String accountNumber;
  final String amountInput;
  final String? remark;
  final String? warning;
  final ReceiptEntity? receipt;
  final String? errorMessage;
  final int lockoutRemainingMs;
  final String? confirmIdempotencyKey;
  final bool confirmLocked;

  const BankTransferState({
    required this.status,
    required this.action,
    required this.bankName,
    required this.accountNumber,
    required this.amountInput,
    this.remark,
    this.warning,
    this.receipt,
    this.errorMessage,
    required this.lockoutRemainingMs,
    this.confirmIdempotencyKey,
    required this.confirmLocked,
  });

  factory BankTransferState.initial() {
    return const BankTransferState(
      status: BankTransferStatus.idle,
      action: BankTransferAction.none,
      bankName: '',
      accountNumber: '',
      amountInput: '',
      lockoutRemainingMs: 0,
      confirmLocked: false,
    );
  }

  BankTransferState copyWith({
    BankTransferStatus? status,
    BankTransferAction? action,
    String? bankName,
    String? accountNumber,
    String? amountInput,
    Object? remark = _unset,
    Object? warning = _unset,
    Object? receipt = _unset,
    Object? errorMessage = _unset,
    int? lockoutRemainingMs,
    Object? confirmIdempotencyKey = _unset,
    bool? confirmLocked,
  }) {
    return BankTransferState(
      status: status ?? this.status,
      action: action ?? this.action,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      amountInput: amountInput ?? this.amountInput,
      remark: remark == _unset ? this.remark : remark as String?,
      warning: warning == _unset ? this.warning : warning as String?,
      receipt: receipt == _unset ? this.receipt : receipt as ReceiptEntity?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      lockoutRemainingMs: lockoutRemainingMs ?? this.lockoutRemainingMs,
      confirmIdempotencyKey: confirmIdempotencyKey == _unset
          ? this.confirmIdempotencyKey
          : confirmIdempotencyKey as String?,
      confirmLocked: confirmLocked ?? this.confirmLocked,
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    bankName,
    accountNumber,
    amountInput,
    remark,
    warning,
    receipt,
    errorMessage,
    lockoutRemainingMs,
    confirmIdempotencyKey,
    confirmLocked,
  ];
}
