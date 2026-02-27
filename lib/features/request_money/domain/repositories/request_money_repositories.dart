import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';

abstract interface class IRequestMoneyRepository {
  Future<Either<Failure, MoneyRequestEntity>> createRequest({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  });

  Future<Either<Failure, MoneyRequestPageEntity>> getOutgoingRequests({
    required int page,
    required int limit,
  });

  Future<Either<Failure, MoneyRequestEntity>> cancelRequest({
    required String requestId,
  });
}
