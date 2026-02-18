import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/services/data/repositories/internet_repositories.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/repositories/internet_repositories.dart';

class GetInternetServicesParams extends Equatable {
  final int page;
  final int limit;
  final String provider;
  final String search;

  const GetInternetServicesParams({
    required this.page,
    required this.limit,
    this.provider = '',
    this.search = '',
  });

  @override
  List<Object?> get props => [page, limit, provider, search];
}

class PayInternetServiceParams extends Equatable {
  final String serviceId;
  final String customerId;
  final String? validationRegex;
  final String? idempotencyKey;

  const PayInternetServiceParams({
    required this.serviceId,
    required this.customerId,
    this.validationRegex,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [
    serviceId,
    customerId,
    validationRegex,
    idempotencyKey,
  ];
}

final getInternetServicesUsecaseProvider = Provider<GetInternetServicesUsecase>(
  (ref) {
    return GetInternetServicesUsecase(
      repository: ref.read(internetRepositoryProvider),
    );
  },
);

final payInternetServiceUsecaseProvider = Provider<PayInternetServiceUsecase>((
  ref,
) {
  return PayInternetServiceUsecase(
    repository: ref.read(internetRepositoryProvider),
  );
});

class GetInternetServicesUsecase
    implements
        UsecaseWithParams<
          PagedResultEntity<InternetServiceEntity>,
          GetInternetServicesParams
        > {
  final IInternetRepository _repository;

  GetInternetServicesUsecase({required IInternetRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PagedResultEntity<InternetServiceEntity>>> call(
    GetInternetServicesParams params,
  ) {
    if (params.page <= 0 || params.limit <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Invalid page/limit values')),
      );
    }

    return _repository.getInternetServices(
      page: params.page,
      limit: params.limit,
      provider: params.provider.trim(),
      search: params.search.trim(),
    );
  }
}

class PayInternetServiceUsecase
    implements
        UsecaseWithParams<PayInternetResultEntity, PayInternetServiceParams> {
  final IInternetRepository _repository;

  PayInternetServiceUsecase({required IInternetRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, PayInternetResultEntity>> call(
    PayInternetServiceParams params,
  ) {
    final serviceId = params.serviceId.trim();
    if (serviceId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Service id is required')),
      );
    }

    final customerId = params.customerId.trim();
    if (customerId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Customer ID is required')),
      );
    }

    final regexPattern = params.validationRegex?.trim();
    if (regexPattern != null && regexPattern.isNotEmpty) {
      try {
        final regex = RegExp(regexPattern);
        if (!regex.hasMatch(customerId)) {
          return Future.value(
            const Left(
              ValidationFailure(
                message: 'Customer ID format is invalid for selected service',
              ),
            ),
          );
        }
      } catch (_) {
        // Ignore invalid regex and defer validation to backend.
      }
    }

    final idempotencyKey = params.idempotencyKey?.trim();
    return _repository.payInternetService(
      serviceId: serviceId,
      customerId: customerId,
      idempotencyKey: idempotencyKey == null || idempotencyKey.isEmpty
          ? null
          : idempotencyKey,
    );
  }
}
