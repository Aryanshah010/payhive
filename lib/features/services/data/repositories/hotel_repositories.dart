import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/services/data/datasources/hotel_datasource.dart';
import 'package:payhive/features/services/data/datasources/remote/hotel_remote_datasource.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/repositories/hotel_repositories.dart';

final hotelRepositoryProvider = Provider<IHotelRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(hotelRemoteDatasourceProvider);

  return HotelRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class HotelRepository implements IHotelRepository {
  final NetworkInfo _networkInfo;
  final IHotelRemoteDatasource _remoteDatasource;

  HotelRepository({
    required NetworkInfo networkInfo,
    required IHotelRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, PagedResultEntity<HotelEntity>>> getHotels({
    required int page,
    required int limit,
    String city = '',
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getHotels(
          page: page,
          limit: limit,
          city: city,
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
  Future<Either<Failure, CreateHotelBookingResultEntity>> createHotelBooking({
    required String hotelId,
    required int rooms,
    required int nights,
    required String checkin,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.createHotelBooking(
          hotelId: hotelId,
          rooms: rooms,
          nights: nights,
          checkin: checkin,
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
  Future<Either<Failure, PayHotelBookingResultEntity>> payHotelBooking({
    required String bookingId,
    String? idempotencyKey,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.payHotelBooking(
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
  Future<Either<Failure, PagedResultEntity<HotelBookingItemEntity>>>
  getHotelBookings({
    required int page,
    required int limit,
    String? status,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.getHotelBookings(
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
