import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/services/data/datasources/recharge_datasource.dart';
import 'package:payhive/features/services/data/datasources/remote/recharge_remote_datasource.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/domain/repositories/recharge_repositories.dart';

final rechargeRepositoryProvider = Provider<IRechargeRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(rechargeRemoteDatasourceProvider);

  return RechargeRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class RechargeRepository implements IRechargeRepository {
  final NetworkInfo _networkInfo;
  final IRechargeRemoteDatasource _remoteDatasource;

  RechargeRepository({
    required NetworkInfo networkInfo,
    required IRechargeRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, PagedResultEntity<RechargeServiceEntity>>>
  getRechargeServices({
    required int page,
    required int limit,
    String provider = '',
    String search = '',
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getRechargeServices(
          page: page,
          limit: limit,
          provider: provider,
          search: search,
        );

        return Right(
          PagedResultEntity(
            items: model.items.map((item) => item.toEntity()).toList(),
            total: model.total,
            page: model.page,
            limit: model.limit,
            totalPages: model.totalPages,
          ),
        );
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }

    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  @override
  Future<Either<Failure, PayRechargeResultEntity>> payRechargeService({
    required String serviceId,
    required String phoneNumber,
    String? idempotencyKey,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.payRechargeService(
          serviceId: serviceId,
          phoneNumber: phoneNumber,
          idempotencyKey: idempotencyKey,
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
