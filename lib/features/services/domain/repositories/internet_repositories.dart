import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';

abstract interface class IInternetRepository {
  Future<Either<Failure, PagedResultEntity<InternetServiceEntity>>>
  getInternetServices({
    required int page,
    required int limit,
    String provider,
    String search,
  });

  Future<Either<Failure, PayInternetResultEntity>> payInternetService({
    required String serviceId,
    required String customerId,
    String? idempotencyKey,
  });
}
