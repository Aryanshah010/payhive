import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/send_money/data/repositories/send_money_repositories.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/send_money/domain/repositories/send_money_repositories.dart';
import 'package:uuid/uuid.dart';

class PreviewTransferParams extends Equatable {
  final String toPhoneNumber;
  final double amount;
  final String? remark;

  const PreviewTransferParams({
    required this.toPhoneNumber,
    required this.amount,
    this.remark,
  });

  @override
  List<Object?> get props => [toPhoneNumber, amount, remark];
}

class ConfirmTransferParams extends Equatable {
  final String toPhoneNumber;
  final double amount;
  final String pin;
  final String? remark;
  final String? idempotencyKey;

  const ConfirmTransferParams({
    required this.toPhoneNumber,
    required this.amount,
    required this.pin,
    this.remark,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [
    toPhoneNumber,
    amount,
    pin,
    remark,
    idempotencyKey,
  ];
}

class LookupBeneficiaryParams extends Equatable {
  final String phoneNumber;

  const LookupBeneficiaryParams({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

final previewTransferUsecaseProvider = Provider<PreviewTransferUsecase>((ref) {
  return PreviewTransferUsecase(
    repository: ref.read(sendMoneyRepositoryProvider),
  );
});

final confirmTransferUsecaseProvider = Provider<ConfirmTransferUsecase>((ref) {
  return ConfirmTransferUsecase(
    repository: ref.read(sendMoneyRepositoryProvider),
  );
});

final lookupBeneficiaryUsecaseProvider = Provider<LookupBeneficiaryUsecase>((
  ref,
) {
  return LookupBeneficiaryUsecase(
    repository: ref.read(sendMoneyRepositoryProvider),
  );
});

class PreviewTransferUsecase
    implements UsecaseWithParams<PreviewEntity, PreviewTransferParams> {
  final ISendMoneyRepository _repository;

  PreviewTransferUsecase({required ISendMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PreviewEntity>> call(PreviewTransferParams params) {
    final phoneError = _validatePhone(params.toPhoneNumber);
    if (phoneError != null) {
      return Future.value(Left(ValidationFailure(message: phoneError)));
    }

    final amountError = _validateAmount(params.amount);
    if (amountError != null) {
      return Future.value(Left(ValidationFailure(message: amountError)));
    }

    final normalizedAmount = _normalizeAmount(params.amount);

    return _repository.previewTransfer(
      toPhoneNumber: params.toPhoneNumber,
      amount: normalizedAmount,
      remark: params.remark,
    );
  }
}

class ConfirmTransferUsecase
    implements UsecaseWithParams<ReceiptEntity, ConfirmTransferParams> {
  final ISendMoneyRepository _repository;
  final Uuid _uuid = const Uuid();

  ConfirmTransferUsecase({required ISendMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, ReceiptEntity>> call(ConfirmTransferParams params) {
    final phoneError = _validatePhone(params.toPhoneNumber);
    if (phoneError != null) {
      return Future.value(Left(ValidationFailure(message: phoneError)));
    }

    final pinError = _validatePin(params.pin);
    if (pinError != null) {
      return Future.value(Left(ValidationFailure(message: pinError)));
    }

    final amountError = _validateAmount(params.amount);
    if (amountError != null) {
      return Future.value(Left(ValidationFailure(message: amountError)));
    }

    final normalizedAmount = _normalizeAmount(params.amount);
    final idempotencyKey =
        (params.idempotencyKey == null || params.idempotencyKey!.isEmpty)
        ? _uuid.v4()
        : params.idempotencyKey;

    return _repository.confirmTransfer(
      toPhoneNumber: params.toPhoneNumber,
      amount: normalizedAmount,
      pin: params.pin,
      remark: params.remark,
      idempotencyKey: idempotencyKey,
    );
  }
}

class LookupBeneficiaryUsecase
    implements UsecaseWithParams<RecipientEntity, LookupBeneficiaryParams> {
  final ISendMoneyRepository _repository;

  LookupBeneficiaryUsecase({required ISendMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, RecipientEntity>> call(
    LookupBeneficiaryParams params,
  ) {
    final phoneError = _validatePhone(params.phoneNumber);
    if (phoneError != null) {
      return Future.value(Left(ValidationFailure(message: phoneError)));
    }

    return _repository.lookupBeneficiary(phoneNumber: params.phoneNumber);
  }
}

String? _validatePhone(String value) {
  final cleaned = value.trim();
  if (!RegExp(r'^\d{10}$').hasMatch(cleaned)) {
    return 'Phone number must be exactly 10 digits.';
  }
  return null;
}

String? _validatePin(String value) {
  final cleaned = value.trim();
  if (!RegExp(r'^\d{4}$').hasMatch(cleaned)) {
    return 'PIN must be exactly 4 digits.';
  }
  return null;
}

String? _validateAmount(double amount) {
  if (amount <= 0) {
    return 'Amount must be greater than 0.';
  }
  final scaled = amount * 100;
  if ((scaled - scaled.round()).abs() > 0.000001) {
    return 'Amount can have at most 2 decimal places.';
  }
  return null;
}

double _normalizeAmount(double amount) {
  return double.parse(amount.toStringAsFixed(2));
}
