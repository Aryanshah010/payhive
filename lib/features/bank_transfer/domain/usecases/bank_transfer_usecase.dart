import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/core/utils/validator_util.dart';
import 'package:payhive/features/bank_transfer/data/repositories/bank_transfer_repositories.dart';
import 'package:payhive/features/bank_transfer/domain/entity/bank_entity.dart';
import 'package:payhive/features/bank_transfer/domain/repositories/bank_transfer_repositories.dart';
import 'package:uuid/uuid.dart';

class PreviewBankTransferParams extends Equatable {
  final String bankName;
  final String accountNumber;
  final double amount;

  const PreviewBankTransferParams({
    required this.bankName,
    required this.accountNumber,
    required this.amount,
  });

  @override
  List<Object?> get props => [bankName, accountNumber, amount];
}

class ConfirmBankTransferParams extends Equatable {
  final String bankName;
  final String accountNumber;
  final double amount;
  final String pin;
  final String? idempotencyKey;

  const ConfirmBankTransferParams({
    required this.bankName,
    required this.accountNumber,
    required this.amount,
    required this.pin,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [
    bankName,
    accountNumber,
    amount,
    pin,
    idempotencyKey,
  ];
}

final getBanksUsecaseProvider = Provider<GetBanksUsecase>((ref) {
  return GetBanksUsecase(repository: ref.read(bankTransferRepositoryProvider));
});

final previewBankTransferUsecaseProvider = Provider<PreviewBankTransferUsecase>(
  (ref) {
    return PreviewBankTransferUsecase(
      repository: ref.read(bankTransferRepositoryProvider),
    );
  },
);

final confirmBankTransferUsecaseProvider = Provider<ConfirmBankTransferUsecase>(
  (ref) {
    return ConfirmBankTransferUsecase(
      repository: ref.read(bankTransferRepositoryProvider),
    );
  },
);

class GetBanksUsecase implements UsecaseWithoutParams<List<BankEntity>> {
  final IBankTransferRepository _repository;

  GetBanksUsecase({required IBankTransferRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, List<BankEntity>>> call() {
    return _repository.getBanks();
  }
}

class PreviewBankTransferUsecase
    implements UsecaseWithParams<PreviewEntity, PreviewBankTransferParams> {
  final IBankTransferRepository _repository;

  PreviewBankTransferUsecase({required IBankTransferRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PreviewEntity>> call(
    PreviewBankTransferParams params,
  ) {
    final bankNameError = ValidatorUtil.validateBankName(params.bankName);
    if (bankNameError != null) {
      return Future.value(Left(ValidationFailure(message: bankNameError)));
    }

    final accountNumberError = ValidatorUtil.validateAccountNumber(params.accountNumber);
    if (accountNumberError != null) {
      return Future.value(Left(ValidationFailure(message: accountNumberError)));
    }

    final amountError = ValidatorUtil.validateAmount(params.amount);
    if (amountError != null) {
      return Future.value(Left(ValidationFailure(message: amountError)));
    }

    final normalizedAmount = ValidatorUtil.normalizeAmount(params.amount);

    return _repository.previewBankTransfer(
      bankName: params.bankName.trim(),
      accountNumber: params.accountNumber.trim(),
      amount: normalizedAmount,
    );
  }
}

class ConfirmBankTransferUsecase
    implements UsecaseWithParams<ReceiptEntity, ConfirmBankTransferParams> {
  final IBankTransferRepository _repository;
  final Uuid _uuid = const Uuid();

  ConfirmBankTransferUsecase({required IBankTransferRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, ReceiptEntity>> call(
    ConfirmBankTransferParams params,
  ) {
    final bankNameError = ValidatorUtil.validateBankName(params.bankName);
    if (bankNameError != null) {
      return Future.value(Left(ValidationFailure(message: bankNameError)));
    }

    final accountNumberError = ValidatorUtil.validateAccountNumber(params.accountNumber);
    if (accountNumberError != null) {
      return Future.value(Left(ValidationFailure(message: accountNumberError)));
    }

    final pinError = ValidatorUtil.validatePin(params.pin);
    if (pinError != null) {
      return Future.value(Left(ValidationFailure(message: pinError)));
    }

    final amountError = ValidatorUtil.validateAmount(params.amount);
    if (amountError != null) {
      return Future.value(Left(ValidationFailure(message: amountError)));
    }

    final normalizedAmount = ValidatorUtil.normalizeAmount(params.amount);
    final idempotencyKey =
        (params.idempotencyKey == null || params.idempotencyKey!.isEmpty)
        ? _uuid.v4()
        : params.idempotencyKey;

    return _repository.confirmBankTransfer(
      bankName: params.bankName.trim(),
      accountNumber: params.accountNumber.trim(),
      amount: normalizedAmount,
      pin: params.pin,
      idempotencyKey: idempotencyKey,
    );
  }
}







