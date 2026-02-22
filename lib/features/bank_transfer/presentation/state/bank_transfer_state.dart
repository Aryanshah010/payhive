import 'package:equatable/equatable.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/features/bank_transfer/domain/entity/bank_entity.dart';

enum BankTransferStatus {
  idle,
  loading,
  previewSuccess,
  confirmSuccess,
  error,
  locked,
}

enum BankTransferAction { none, preview, confirm }

enum BankListStatus { idle, loading, loaded, error }

class BankTransferState extends Equatable {
  static const Object _unset = Object();

  final BankTransferStatus status;
  final BankTransferAction action;
  final String bankName;
  final String accountNumber;
  final String amountInput;
  final String? warning;
  final ReceiptEntity? receipt;
  final String? errorMessage;
  final int lockoutRemainingMs;
  final String? confirmIdempotencyKey;
  final bool confirmLocked;
  final List<BankEntity> banks;
  final BankListStatus bankListStatus;
  final String? bankListError;

  const BankTransferState({
    required this.status,
    required this.action,
    required this.bankName,
    required this.accountNumber,
    required this.amountInput,
    this.warning,
    this.receipt,
    this.errorMessage,
    required this.lockoutRemainingMs,
    this.confirmIdempotencyKey,
    required this.confirmLocked,
    required this.banks,
    required this.bankListStatus,
    this.bankListError,
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
      banks: [],
      bankListStatus: BankListStatus.idle,
    );
  }

  BankTransferState copyWith({
    BankTransferStatus? status,
    BankTransferAction? action,
    String? bankName,
    String? accountNumber,
    String? amountInput,
    Object? warning = _unset,
    Object? receipt = _unset,
    Object? errorMessage = _unset,
    int? lockoutRemainingMs,
    Object? confirmIdempotencyKey = _unset,
    bool? confirmLocked,
    List<BankEntity>? banks,
    BankListStatus? bankListStatus,
    Object? bankListError = _unset,
  }) {
    return BankTransferState(
      status: status ?? this.status,
      action: action ?? this.action,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      amountInput: amountInput ?? this.amountInput,
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
      banks: banks ?? this.banks,
      bankListStatus: bankListStatus ?? this.bankListStatus,
      bankListError: bankListError == _unset
          ? this.bankListError
          : bankListError as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    bankName,
    accountNumber,
    amountInput,
    warning,
    receipt,
    errorMessage,
    lockoutRemainingMs,
    confirmIdempotencyKey,
    confirmLocked,
    banks,
    bankListStatus,
    bankListError,
  ];
}
