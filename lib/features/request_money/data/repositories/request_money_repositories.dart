import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/request_money/data/datasources/remote/request_money_remote_datasource.dart';
import 'package:payhive/features/request_money/data/datasources/request_money_datasource.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/repositories/request_money_repositories.dart';

final requestMoneyRepositoryProvider = Provider<IRequestMoneyRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(requestMoneyRemoteDatasourceProvider);

  return RequestMoneyRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class RequestMoneyRepository implements IRequestMoneyRepository {
  final NetworkInfo _networkInfo;
  final IRequestMoneyRemoteDatasource _remoteDatasource;

  RequestMoneyRepository({
    required NetworkInfo networkInfo,
    required IRequestMoneyRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, MoneyRequestEntity>> createRequest({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.createRequest(
          toPhoneNumber: toPhoneNumber,
          amount: amount,
          remark: remark,
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
  Future<Either<Failure, MoneyRequestPageEntity>> getOutgoingRequests({
    required int page,
    required int limit,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getOutgoingRequests(
          page: page,
          limit: limit,
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
  Future<Either<Failure, MoneyRequestEntity>> cancelRequest({
    required String requestId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.cancelRequest(
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

    return ApiFalilure(message: message, statusCode: statusCode);
  }
}
