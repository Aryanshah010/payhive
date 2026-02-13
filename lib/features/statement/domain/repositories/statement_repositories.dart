import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';

abstract interface class IStatementRepository {
  Future<Either<Failure, TransactionHistoryEntity>> getHistory({
    required int page,
    required int limit,
    String search,
    String direction,
  });

  Future<Either<Failure, ReceiptEntity>> getDetail({required String txId});
}
