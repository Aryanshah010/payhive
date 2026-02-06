import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';

abstract interface class ISendMoneyRepository {
  Future<Either<Failure, PreviewEntity>> previewTransfer({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  });

  Future<Either<Failure, ReceiptEntity>> confirmTransfer({
    required String toPhoneNumber,
    required double amount,
    required String pin,
    String? remark,
    String? idempotencyKey,
  });

  Future<Either<Failure, RecipientEntity>> lookupBeneficiary({
    required String phoneNumber,
  });

}