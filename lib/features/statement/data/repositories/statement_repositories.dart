import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/data/datasources/remote/statement_remote_datasource.dart';
import 'package:payhive/features/statement/data/datasources/statement_datasource.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
import 'package:payhive/features/statement/domain/repositories/statement_repositories.dart';

final statementRepositoryProvider = Provider<IStatementRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(statementRemoteDatasourceProvider);
  return StatementRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class StatementRepository implements IStatementRepository {
  final NetworkInfo _networkInfo;
  final IStatementRemoteDatasource _remoteDatasource;

  StatementRepository({
    required NetworkInfo networkInfo,
    required IStatementRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, TransactionHistoryEntity>> getHistory({
    required int page,
    required int limit,
    String search = '',
    String direction = 'all',
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getHistory(
          page: page,
          limit: limit,
          search: search,
          direction: direction,
        );
        return Right(model.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  @override
  Future<Either<Failure, ReceiptEntity>> getDetail({
    required String txId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getDetail(txId: txId);
        return Right(model.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  @override
  Future<Either<Failure, UndoRequestEntity>> createUndoRequest({
    required String txId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.createUndoRequest(txId: txId);
        return Right(model.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  @override
  Future<Either<Failure, AcceptUndoResultEntity>> acceptUndoRequest({
    required String requestId,
    required String pin,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.acceptUndoRequest(
          requestId: requestId,
          pin: pin,
        );
        return Right(model.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  @override
  Future<Either<Failure, UndoRequestEntity>> rejectUndoRequest({
    required String requestId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.rejectUndoRequest(
          requestId: requestId,
        );
        return Right(model.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  Failure _mapDioFailure(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final message = responseData is Map && responseData['message'] != null
        ? responseData['message'].toString()
        : (e.message ?? 'Request failed');

    if (statusCode == 423) {
      return PinLockoutFailure(
        message: message,
        remainingMs: _extractRemainingMs(responseData),
        statusCode: statusCode,
      );
    }

    return ApiFalilure(message: message, statusCode: statusCode);
  }

  int _extractRemainingMs(dynamic data) {
    if (data is Map) {
      final nested = data['data'];
      if (nested is Map && nested['remainingMs'] is num) {
        return (nested['remainingMs'] as num).toInt();
      }
      if (data['remainingMs'] is num) {
        return (data['remainingMs'] as num).toInt();
      }
    }
    return 0;
  }
}
