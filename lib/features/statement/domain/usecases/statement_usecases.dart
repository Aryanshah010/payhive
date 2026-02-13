import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/usecases/app_usecase.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/data/repositories/statement_repositories.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';
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
