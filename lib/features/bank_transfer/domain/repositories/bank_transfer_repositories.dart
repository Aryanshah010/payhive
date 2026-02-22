import 'package:dartz/dartz.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/bank_transfer/domain/entity/bank_entity.dart';

abstract interface class IBankTransferRepository {
  Future<Either<Failure, List<BankEntity>>> getBanks();

  Future<Either<Failure, PreviewEntity>> previewBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
  });

  Future<Either<Failure, ReceiptEntity>> confirmBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
    required String pin,
    String? idempotencyKey,
  });
}
