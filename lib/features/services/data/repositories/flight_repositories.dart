import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/services/data/datasources/remote/flight_remote_datasource.dart';
import 'package:payhive/features/services/data/datasources/flight_datasource.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/repositories/flight_repositories.dart';

final flightRepositoryProvider = Provider<IFlightRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(flightRemoteDatasourceProvider);

  return FlightRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class FlightRepository implements IFlightRepository {
  final NetworkInfo _networkInfo;
  final IFlightRemoteDatasource _remoteDatasource;

  FlightRepository({
    required NetworkInfo networkInfo,
    required IFlightRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, PagedResultEntity<FlightEntity>>> getFlights({
    required int page,
    required int limit,
    String from = '',
    String to = '',
    String? date,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getFlights(
          page: page,
          limit: limit,
          from: from,
          to: to,
          date: date,
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
  Future<Either<Failure, CreateBookingResultEntity>> createFlightBooking({
    required String flightId,
    required int quantity,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.createFlightBooking(
          flightId: flightId,
          quantity: quantity,
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
  Future<Either<Failure, PayBookingResultEntity>> payBooking({
    required String bookingId,
    String? idempotencyKey,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.payBooking(
          bookingId: bookingId,
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

  @override
  Future<Either<Failure, PagedResultEntity<FlightBookingItemEntity>>>
  getFlightBookings({
    required int page,
    required int limit,
    String? status,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getFlightBookings(
          page: page,
          limit: limit,
          status: status,
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

  Failure _mapDioFailure(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    final message = responseData is Map && responseData['message'] != null
        ? responseData['message'].toString()
        : (e.message ?? 'Request failed');

    return ApiFalilure(message: message, statusCode: statusCode);
  }
}
