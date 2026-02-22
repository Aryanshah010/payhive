import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/send_money/domain/usecases/send_money_usecase.dart';
import 'package:payhive/features/send_money/presentation/state/bank_transfer_state.dart';
import 'package:uuid/uuid.dart';

final bankTransferViewModelProvider =
    NotifierProvider<BankTransferViewModel, BankTransferState>(
      BankTransferViewModel.new,
    );

class BankTransferViewModel extends Notifier<BankTransferState> {
  late final PreviewBankTransferUsecase _previewBankTransferUsecase;
  late final ConfirmBankTransferUsecase _confirmBankTransferUsecase;
  final Uuid _uuid = const Uuid();

  Timer? _lockoutTimer;
  static const String _confirmLockedMessage =
      'Transfer already submitted. Start a new transfer.';

  @override
  BankTransferState build() {
    _previewBankTransferUsecase = ref.read(previewBankTransferUsecaseProvider);
    _confirmBankTransferUsecase = ref.read(confirmBankTransferUsecaseProvider);

    ref.onDispose(() {
      _lockoutTimer?.cancel();
    });

    return BankTransferState.initial();
  }

  void resetFlow() {
    _lockoutTimer?.cancel();
    state = BankTransferState.initial();
  }

  void clearStatus() {
    if (state.status == BankTransferStatus.locked) return;
    state = state.copyWith(
      status: BankTransferStatus.idle,
      action: BankTransferAction.none,
      errorMessage: null,
    );
  }

  void _invalidateConfirmLifecycle() {
    if (state.confirmIdempotencyKey == null && !state.confirmLocked) {
      return;
    }
    state = state.copyWith(confirmIdempotencyKey: null, confirmLocked: false);
  }

  void _emitConfirmLockedError() {
    state = state.copyWith(
      status: BankTransferStatus.error,
      action: BankTransferAction.none,
      errorMessage: _confirmLockedMessage,
    );
  }

  void setBankName(String value) {
    final trimmed = value.trim();
    if (trimmed == state.bankName) return;
    _invalidateConfirmLifecycle();
    state = state.copyWith(bankName: trimmed);
  }

  void setAccountNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'\D'), '');
    if (normalized == state.accountNumber) return;
    _invalidateConfirmLifecycle();
    state = state.copyWith(accountNumber: normalized);
  }

  void setRemark(String? value) {
    final trimmed = value?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (normalized == state.remark) return;
    _invalidateConfirmLifecycle();
    state = state.copyWith(remark: normalized);
  }

  void appendAmountKey(String key) {
    final current = state.amountInput;
    var input = current;

    if (key == '.') {
      if (input.contains('.')) return;
      input = input.isEmpty ? '0.' : '$input.';
    } else {
      final parts = input.split('.');
      if (parts.length == 2 && parts[1].length >= 2) {
        return;
      }

      if (input == '0') {
        input = key;
      } else {
        input += key;
      }
    }

    if (input == current) return;
    _invalidateConfirmLifecycle();
    state = state.copyWith(amountInput: input);
  }

  void backspaceAmount() {
    if (state.amountInput.isEmpty) return;
    final current = state.amountInput;
    final updated = state.amountInput.substring(
      0,
      state.amountInput.length - 1,
    );
    if (updated == current) return;
    _invalidateConfirmLifecycle();
    state = state.copyWith(amountInput: updated);
  }

  Future<void> previewTransfer() async {
    if (state.status == BankTransferStatus.loading) return;
    if (state.confirmLocked) {
      _emitConfirmLockedError();
      return;
    }

    final amount = double.tryParse(state.amountInput) ?? 0;

    state = state.copyWith(
      status: BankTransferStatus.loading,
      action: BankTransferAction.preview,
      errorMessage: null,
    );

    final result = await _previewBankTransferUsecase(
      PreviewBankTransferParams(
        bankName: state.bankName,
        accountNumber: state.accountNumber,
        amount: amount,
        remark: state.remark,
      ),
    );

    result.fold(_handleFailure, (preview) {
      final existingKey = state.confirmIdempotencyKey;
      final idempotencyKey = (existingKey == null || existingKey.isEmpty)
          ? _uuid.v4()
          : existingKey;

      state = state.copyWith(
        status: BankTransferStatus.previewSuccess,
        action: BankTransferAction.none,
        warning: preview.warning,
        errorMessage: null,
        confirmIdempotencyKey: idempotencyKey,
        confirmLocked: false,
      );
    });
  }

  Future<void> confirmTransfer(String pin) async {
    if (state.status == BankTransferStatus.loading) return;
    if (state.confirmLocked) {
      _emitConfirmLockedError();
      return;
    }

    final amount = double.tryParse(state.amountInput) ?? 0;
    final existingKey = state.confirmIdempotencyKey;
    final idempotencyKey = (existingKey == null || existingKey.isEmpty)
        ? _uuid.v4()
        : existingKey;

    state = state.copyWith(
      status: BankTransferStatus.loading,
      action: BankTransferAction.confirm,
      errorMessage: null,
      confirmIdempotencyKey: idempotencyKey,
      confirmLocked: true,
    );

    final result = await _confirmBankTransferUsecase(
      ConfirmBankTransferParams(
        bankName: state.bankName,
        accountNumber: state.accountNumber,
        amount: amount,
        pin: pin,
        remark: state.remark,
        idempotencyKey: idempotencyKey,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(confirmLocked: false);
        _handleFailure(failure);
      },
      (receipt) {
        state = state.copyWith(
          status: BankTransferStatus.confirmSuccess,
          action: BankTransferAction.none,
          receipt: receipt,
          errorMessage: null,
          confirmIdempotencyKey: idempotencyKey,
          confirmLocked: true,
        );
      },
    );
  }

  void _handleFailure(Failure failure) {
    if (failure is PinLockoutFailure) {
      state = state.copyWith(
        status: BankTransferStatus.locked,
        action: BankTransferAction.none,
        errorMessage: failure.message,
        lockoutRemainingMs: failure.remainingMs,
      );
      _startLockoutCountdown(failure.remainingMs);
      return;
    }

    state = state.copyWith(
      status: BankTransferStatus.error,
      action: BankTransferAction.none,
      errorMessage: failure.message,
    );
  }

  void _startLockoutCountdown(int remainingMs) {
    _lockoutTimer?.cancel();

    if (remainingMs <= 0) {
      state = state.copyWith(lockoutRemainingMs: 0);
      return;
    }

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final updated = state.lockoutRemainingMs - 1000;
      if (updated <= 0) {
        timer.cancel();
        state = state.copyWith(
          lockoutRemainingMs: 0,
          status: BankTransferStatus.idle,
          action: BankTransferAction.none,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(lockoutRemainingMs: updated);
      }
    });
  }
}
