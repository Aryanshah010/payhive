import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/services/data/repositories/recharge_repositories.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/domain/repositories/recharge_repositories.dart';

class GetRechargeServicesParams extends Equatable {
  final int page;
  final int limit;
  final String provider;
  final String search;

  const GetRechargeServicesParams({
    required this.page,
    required this.limit,
    this.provider = '',
    this.search = '',
  });

  @override
  List<Object?> get props => [page, limit, provider, search];
}

class PayRechargeServiceParams extends Equatable {
  final String serviceId;
  final String phoneNumber;
  final String? idempotencyKey;

  const PayRechargeServiceParams({
    required this.serviceId,
    required this.phoneNumber,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [serviceId, phoneNumber, idempotencyKey];
}

final getRechargeServicesUsecaseProvider = Provider<GetRechargeServicesUsecase>(
  (ref) {
    return GetRechargeServicesUsecase(
      repository: ref.read(rechargeRepositoryProvider),
    );
  },
);

final payRechargeServiceUsecaseProvider = Provider<PayRechargeServiceUsecase>((
  ref,
) {
  return PayRechargeServiceUsecase(
    repository: ref.read(rechargeRepositoryProvider),
  );
});

class GetRechargeServicesUsecase
    implements
        UsecaseWithParams<
          PagedResultEntity<RechargeServiceEntity>,
          GetRechargeServicesParams
        > {
  final IRechargeRepository _repository;

  GetRechargeServicesUsecase({required IRechargeRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PagedResultEntity<RechargeServiceEntity>>> call(
    GetRechargeServicesParams params,
  ) {
    if (params.page <= 0 || params.limit <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Invalid page/limit values')),
      );
    }

    return _repository.getRechargeServices(
      page: params.page,
      limit: params.limit,
      provider: params.provider.trim(),
      search: params.search.trim(),
    );
  }
}

class PayRechargeServiceUsecase
    implements
        UsecaseWithParams<PayRechargeResultEntity, PayRechargeServiceParams> {
  final IRechargeRepository _repository;

  PayRechargeServiceUsecase({required IRechargeRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PayRechargeResultEntity>> call(
    PayRechargeServiceParams params,
  ) {
    final serviceId = params.serviceId.trim();
    if (serviceId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Service id is required')),
      );
    }

    final phoneNumber = params.phoneNumber.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(phoneNumber)) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Phone number must be exactly 10 digits'),
        ),
      );
    }

    final idempotencyKey = params.idempotencyKey?.trim();

    return _repository.payRechargeService(
      serviceId: serviceId,
      phoneNumber: phoneNumber,
      idempotencyKey: idempotencyKey == null || idempotencyKey.isEmpty
          ? null
          : idempotencyKey,
    );
  }
}
