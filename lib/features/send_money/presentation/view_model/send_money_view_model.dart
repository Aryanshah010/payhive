import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/send_money/domain/usecases/send_money_usecase.dart';
import 'package:payhive/features/send_money/presentation/state/send_money_state.dart';
import 'package:uuid/uuid.dart';

final sendMoneyViewModelProvider =
    NotifierProvider<SendMoneyViewModel, SendMoneyState>(
      () => SendMoneyViewModel(),
    );

class SendMoneyViewModel extends Notifier<SendMoneyState> {
  late final PreviewTransferUsecase _previewTransferUsecase;
  late final ConfirmTransferUsecase _confirmTransferUsecase;
  late final LookupBeneficiaryUsecase _lookupBeneficiaryUsecase;
  final Uuid _uuid = const Uuid();

  Timer? _lockoutTimer;
  static const String _confirmLockedMessage =
      'Transfer already submitted. Start a new transfer.';

  @override
  SendMoneyState build() {
    _previewTransferUsecase = ref.read(previewTransferUsecaseProvider);
    _confirmTransferUsecase = ref.read(confirmTransferUsecaseProvider);
    _lookupBeneficiaryUsecase = ref.read(lookupBeneficiaryUsecaseProvider);

    ref.onDispose(() {
      _lockoutTimer?.cancel();
    });

    return SendMoneyState.initial();
  }

  void resetFlow() {
    _lockoutTimer?.cancel();
    state = SendMoneyState.initial();
  }

  void clearStatus() {
    if (state.status == SendMoneyStatus.locked) return;
    state = state.copyWith(
      status: SendMoneyStatus.idle,
      action: SendMoneyAction.none,
      errorMessage: null,
    );
  }

  void _invalidateConfirmLifecycle() {
    if (state.confirmIdempotencyKey == null && !state.confirmLocked) {
      return;
    }
    state = state.copyWith(
      confirmIdempotencyKey: null,
      confirmLocked: false,
    );
  }

  void _emitConfirmLockedError() {
    state = state.copyWith(
      status: SendMoneyStatus.error,
      action: SendMoneyAction.none,
      errorMessage: _confirmLockedMessage,
    );
  }

  void setPhoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed == state.phoneNumber) return;
    _invalidateConfirmLifecycle();
    state = state.copyWith(phoneNumber: trimmed);
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

  Future<void> lookupBeneficiary() async {
    if (state.status == SendMoneyStatus.loading) return;

    state = state.copyWith(
      status: SendMoneyStatus.loading,
      action: SendMoneyAction.lookup,
      errorMessage: null,
    );

    final result = await _lookupBeneficiaryUsecase(
      LookupBeneficiaryParams(phoneNumber: state.phoneNumber),
    );

    result.fold(
      (failure) => _handleFailure(failure),
      (recipient) {
        state = state.copyWith(
          status: SendMoneyStatus.lookupSuccess,
          action: SendMoneyAction.none,
          recipient: recipient,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> previewTransfer() async {
    if (state.status == SendMoneyStatus.loading) return;
    if (state.confirmLocked) {
      _emitConfirmLockedError();
      return;
    }

    final amount = double.tryParse(state.amountInput) ?? 0;

    state = state.copyWith(
      status: SendMoneyStatus.loading,
      action: SendMoneyAction.preview,
      errorMessage: null,
    );

    final result = await _previewTransferUsecase(
      PreviewTransferParams(
        toPhoneNumber: state.phoneNumber,
        amount: amount,
        remark: state.remark,
      ),
    );

    result.fold(
      (failure) => _handleFailure(failure),
      (preview) {
        final existingKey = state.confirmIdempotencyKey;
        final idempotencyKey =
            (existingKey == null || existingKey.isEmpty)
                ? _uuid.v4()
                : existingKey;

        state = state.copyWith(
          status: SendMoneyStatus.previewSuccess,
          action: SendMoneyAction.none,
          recipient: preview.recipient,
          warning: preview.warning,
          errorMessage: null,
          confirmIdempotencyKey: idempotencyKey,
          confirmLocked: false,
        );
      },
    );
  }

  Future<void> confirmTransfer(String pin) async {
    if (state.status == SendMoneyStatus.loading) return;
    if (state.confirmLocked) {
      _emitConfirmLockedError();
      return;
    }

    final amount = double.tryParse(state.amountInput) ?? 0;
    final existingKey = state.confirmIdempotencyKey;
    final idempotencyKey =
        (existingKey == null || existingKey.isEmpty) ? _uuid.v4() : existingKey;

    state = state.copyWith(
      status: SendMoneyStatus.loading,
      action: SendMoneyAction.confirm,
      errorMessage: null,
      confirmIdempotencyKey: idempotencyKey,
      confirmLocked: true,
    );

    final result = await _confirmTransferUsecase(
      ConfirmTransferParams(
        toPhoneNumber: state.phoneNumber,
        amount: amount,
        pin: pin,
        remark: state.remark,
        idempotencyKey: idempotencyKey,
      ),
    );

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          state = state.copyWith(confirmLocked: false);
        }
        _handleFailure(failure);
      },
      (receipt) {
        state = state.copyWith(
          status: SendMoneyStatus.confirmSuccess,
          action: SendMoneyAction.none,
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
        status: SendMoneyStatus.locked,
        action: SendMoneyAction.none,
        errorMessage: failure.message,
        lockoutRemainingMs: failure.remainingMs,
      );
      _startLockoutCountdown(failure.remainingMs);
      return;
    }

    state = state.copyWith(
      status: SendMoneyStatus.error,
      action: SendMoneyAction.none,
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
          status: SendMoneyStatus.idle,
          action: SendMoneyAction.none,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(lockoutRemainingMs: updated);
      }
    });
  }
}
