import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';

abstract interface class IRechargeRepository {
  Future<Either<Failure, PagedResultEntity<RechargeServiceEntity>>>
  getRechargeServices({
    required int page,
    required int limit,
    String provider,
    String search,
  });

  Future<Either<Failure, PayRechargeResultEntity>> payRechargeService({
    required String serviceId,
    required String phoneNumber,
    String? idempotencyKey,
  });
}
