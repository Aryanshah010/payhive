import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/data/repositories/statement_repositories.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
import 'package:payhive/features/statement/domain/repositories/statement_repositories.dart';

class HistoryParams extends Equatable {
  final int page;
  final int limit;
  final String search;
  final String direction;

  const HistoryParams({
    required this.page,
    required this.limit,
    this.search = '',
    this.direction = 'all',
  });

  @override
  List<Object?> get props => [page, limit, search, direction];
}

class DetailParams extends Equatable {
  final String txId;

  const DetailParams({required this.txId});

  @override
  List<Object?> get props => [txId];
}

class RequestUndoParams extends Equatable {
  final String txId;

  const RequestUndoParams({required this.txId});

  @override
  List<Object?> get props => [txId];
}

class AcceptUndoParams extends Equatable {
  final String requestId;
  final String pin;

  const AcceptUndoParams({required this.requestId, required this.pin});

  @override
  List<Object?> get props => [requestId, pin];
}

class RejectUndoParams extends Equatable {
  final String requestId;

  const RejectUndoParams({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

final getTransactionHistoryUsecaseProvider =
    Provider<GetTransactionHistoryUsecase>((ref) {
      return GetTransactionHistoryUsecase(
        repository: ref.read(statementRepositoryProvider),
      );
    });

final getTransactionDetailUsecaseProvider =
    Provider<GetTransactionDetailUsecase>((ref) {
      return GetTransactionDetailUsecase(
        repository: ref.read(statementRepositoryProvider),
      );
    });

final requestUndoUsecaseProvider = Provider<RequestUndoUsecase>((ref) {
  return RequestUndoUsecase(repository: ref.read(statementRepositoryProvider));
});

final acceptUndoUsecaseProvider = Provider<AcceptUndoUsecase>((ref) {
  return AcceptUndoUsecase(repository: ref.read(statementRepositoryProvider));
});

final rejectUndoUsecaseProvider = Provider<RejectUndoUsecase>((ref) {
  return RejectUndoUsecase(repository: ref.read(statementRepositoryProvider));
});

class GetTransactionHistoryUsecase
    implements UsecaseWithParams<TransactionHistoryEntity, HistoryParams> {
  final IStatementRepository _repository;

  GetTransactionHistoryUsecase({required IStatementRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, TransactionHistoryEntity>> call(HistoryParams params) {
    if (params.page <= 0 || params.limit <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Invalid page/limit values')),
      );
    }
    const allowedDirections = {'all', 'debit', 'credit'};
    if (!allowedDirections.contains(params.direction)) {
      return Future.value(
        const Left(ValidationFailure(message: 'Invalid direction filter')),
      );
    }

    return _repository.getHistory(
      page: params.page,
      limit: params.limit,
      search: params.search,
      direction: params.direction,
    );
  }
}

class GetTransactionDetailUsecase
    implements UsecaseWithParams<ReceiptEntity, DetailParams> {
  final IStatementRepository _repository;

  GetTransactionDetailUsecase({required IStatementRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, ReceiptEntity>> call(DetailParams params) {
    if (params.txId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Transaction ID is required')),
      );
    }
    return _repository.getDetail(txId: params.txId.trim());
  }
}

class RequestUndoUsecase
    implements UsecaseWithParams<UndoRequestEntity, RequestUndoParams> {
  final IStatementRepository _repository;

  RequestUndoUsecase({required IStatementRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, UndoRequestEntity>> call(RequestUndoParams params) {
    final txId = params.txId.trim();
    if (txId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Transaction ID is required')),
      );
    }
    return _repository.createUndoRequest(txId: txId);
  }
}

class AcceptUndoUsecase
    implements UsecaseWithParams<AcceptUndoResultEntity, AcceptUndoParams> {
  final IStatementRepository _repository;

  AcceptUndoUsecase({required IStatementRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, AcceptUndoResultEntity>> call(
    AcceptUndoParams params,
  ) {
    final requestId = params.requestId.trim();
    if (requestId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Request ID is required')),
      );
    }

    final pin = params.pin.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return Future.value(
        const Left(ValidationFailure(message: 'PIN must be exactly 4 digits.')),
      );
    }

    return _repository.acceptUndoRequest(requestId: requestId, pin: pin);
  }
}

class RejectUndoUsecase
    implements UsecaseWithParams<UndoRequestEntity, RejectUndoParams> {
  final IStatementRepository _repository;

  RejectUndoUsecase({required IStatementRepository repository})
    : _repository = repository;

  @override
  Future<Either<Failure, UndoRequestEntity>> call(RejectUndoParams params) {
    final requestId = params.requestId.trim();
    if (requestId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Request ID is required')),
      );
    }
    return _repository.rejectUndoRequest(requestId: requestId);
  }
}
