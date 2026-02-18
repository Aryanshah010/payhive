import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/services/data/datasources/internet_datasource.dart';
import 'package:payhive/features/services/data/datasources/remote/internet_remote_datasource.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/repositories/internet_repositories.dart';

final internetRepositoryProvider = Provider<IInternetRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(internetRemoteDatasourceProvider);

  return InternetRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class InternetRepository implements IInternetRepository {
  final NetworkInfo _networkInfo;
  final IInternetRemoteDatasource _remoteDatasource;

  InternetRepository({
    required NetworkInfo networkInfo,
    required IInternetRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, PagedResultEntity<InternetServiceEntity>>>
  getInternetServices({
    required int page,
    required int limit,
    String provider = '',
    String search = '',
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getInternetServices(
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
  Future<Either<Failure, PayInternetResultEntity>> payInternetService({
    required String serviceId,
    required String customerId,
    String? idempotencyKey,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.payInternetService(
          serviceId: serviceId,
          customerId: customerId,
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
