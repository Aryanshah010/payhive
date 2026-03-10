import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/core/utils/validator_util.dart';
import 'package:payhive/features/request_money/data/repositories/request_money_repositories.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/repositories/request_money_repositories.dart';

class MoneyRequestAction {
  static const String reject = 'REJECT';
  static const String cancel = 'CANCEL';

  static const Set<String> allowed = {reject, cancel};
}

class CreateMoneyRequestParams extends Equatable {
  final String toPhoneNumber;
  final double amount;
  final String? remark;

  const CreateMoneyRequestParams({
    required this.toPhoneNumber,
    required this.amount,
    this.remark,
  });

  @override
  List<Object?> get props => [toPhoneNumber, amount, remark];
}

class GetOutgoingMoneyRequestsParams extends Equatable {
  final int page;
  final int limit;

  const GetOutgoingMoneyRequestsParams({
    required this.page,
    required this.limit,
  });

  @override
  List<Object?> get props => [page, limit];
}

class CancelMoneyRequestParams extends Equatable {
  final String requestId;

  const CancelMoneyRequestParams({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class GetMoneyRequestDetailParams extends Equatable {
  final String requestId;

  const GetMoneyRequestDetailParams({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class RespondMoneyRequestParams extends Equatable {
  final String requestId;
  final String action;

  const RespondMoneyRequestParams({
    required this.requestId,
    required this.action,
  });

  @override
  List<Object?> get props => [requestId, action];
}

final createMoneyRequestUsecaseProvider = Provider<CreateMoneyRequestUsecase>((
  ref,
) {
  return CreateMoneyRequestUsecase(
    repository: ref.read(requestMoneyRepositoryProvider),
  );
});

final getOutgoingMoneyRequestsUsecaseProvider =
    Provider<GetOutgoingMoneyRequestsUsecase>((ref) {
      return GetOutgoingMoneyRequestsUsecase(
        repository: ref.read(requestMoneyRepositoryProvider),
      );
    });

final cancelMoneyRequestUsecaseProvider = Provider<CancelMoneyRequestUsecase>((
  ref,
) {
  return CancelMoneyRequestUsecase(
    repository: ref.read(requestMoneyRepositoryProvider),
  );
});

final getMoneyRequestDetailUsecaseProvider =
    Provider<GetMoneyRequestDetailUsecase>((ref) {
      return GetMoneyRequestDetailUsecase(
        repository: ref.read(requestMoneyRepositoryProvider),
      );
    });

final respondMoneyRequestUsecaseProvider = Provider<RespondMoneyRequestUsecase>(
  (ref) {
    return RespondMoneyRequestUsecase(
      repository: ref.read(requestMoneyRepositoryProvider),
    );
  },
);

class CreateMoneyRequestUsecase
    implements UsecaseWithParams<MoneyRequestEntity, CreateMoneyRequestParams> {
  final IRequestMoneyRepository _repository;

  CreateMoneyRequestUsecase({required IRequestMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, MoneyRequestEntity>> call(
    CreateMoneyRequestParams params,
  ) {
    final phoneError = ValidatorUtil.phoneNumberValidator(params.toPhoneNumber);
    if (phoneError != null) {
      return Future.value(Left(ValidationFailure(message: phoneError)));
    }

    final amountError = ValidatorUtil.validateAmount(params.amount);
    if (amountError != null) {
      return Future.value(Left(ValidationFailure(message: amountError)));
    }

    final remarkError = ValidatorUtil.validateRemark(params.remark);
    if (remarkError != null) {
      return Future.value(Left(ValidationFailure(message: remarkError)));
    }

    final normalizedAmount = _normalizeAmount(params.amount);
    final normalizedRemark = ValidatorUtil.normalizeRemark(params.remark);

    return _repository.createRequest(
      toPhoneNumber: params.toPhoneNumber.trim(),
      amount: normalizedAmount,
      remark: normalizedRemark,
    );
  }
}

class GetOutgoingMoneyRequestsUsecase
    implements
        UsecaseWithParams<
          MoneyRequestPageEntity,
          GetOutgoingMoneyRequestsParams
        > {
  final IRequestMoneyRepository _repository;

  GetOutgoingMoneyRequestsUsecase({required IRequestMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, MoneyRequestPageEntity>> call(
    GetOutgoingMoneyRequestsParams params,
  ) {
    if (params.page < 1) {
      return Future.value(
        const Left(ValidationFailure(message: 'Page must be at least 1.')),
      );
    }

    if (params.limit < 1 || params.limit > 50) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Limit must be between 1 and 50.'),
        ),
      );
    }

    return _repository.getOutgoingRequests(
      page: params.page,
      limit: params.limit,
    );
  }
}

class CancelMoneyRequestUsecase
    implements UsecaseWithParams<MoneyRequestEntity, CancelMoneyRequestParams> {
  final IRequestMoneyRepository _repository;

  CancelMoneyRequestUsecase({required IRequestMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, MoneyRequestEntity>> call(
    CancelMoneyRequestParams params,
  ) {
    final requestId = params.requestId.trim();
    if (requestId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Request ID is required.')),
      );
    }

    return _repository.respondToRequest(
      requestId: requestId,
      action: MoneyRequestAction.cancel,
    );
  }
}

class GetMoneyRequestDetailUsecase
    implements
        UsecaseWithParams<MoneyRequestEntity, GetMoneyRequestDetailParams> {
  final IRequestMoneyRepository _repository;

  GetMoneyRequestDetailUsecase({required IRequestMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, MoneyRequestEntity>> call(
    GetMoneyRequestDetailParams params,
  ) {
    final requestId = params.requestId.trim();
    if (requestId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Request ID is required.')),
      );
    }

    return _repository.getRequestDetail(requestId: requestId);
  }
}

class RespondMoneyRequestUsecase
    implements
        UsecaseWithParams<MoneyRequestEntity, RespondMoneyRequestParams> {
  final IRequestMoneyRepository _repository;

  RespondMoneyRequestUsecase({required IRequestMoneyRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, MoneyRequestEntity>> call(
    RespondMoneyRequestParams params,
  ) {
    final requestId = params.requestId.trim();
    if (requestId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Request ID is required.')),
      );
    }

    final action = params.action.trim().toUpperCase();
    if (!MoneyRequestAction.allowed.contains(action)) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Action must be REJECT or CANCEL.'),
        ),
      );
    }

    return _repository.respondToRequest(requestId: requestId, action: action);
  }
}


double _normalizeAmount(double amount) {
  return double.parse(amount.toStringAsFixed(2));
}
