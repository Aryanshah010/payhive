import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';

abstract interface class IHotelRepository {
  Future<Either<Failure, PagedResultEntity<HotelEntity>>> getHotels({
    required int page,
    required int limit,
    String city,
  });

  Future<Either<Failure, CreateHotelBookingResultEntity>> createHotelBooking({
    required String hotelId,
    required int rooms,
    required int nights,
    required String checkin,
  });

  Future<Either<Failure, PayHotelBookingResultEntity>> payHotelBooking({
    required String bookingId,
    String? idempotencyKey,
  });

  Future<Either<Failure, PagedResultEntity<HotelBookingItemEntity>>>
  getHotelBookings({required int page, required int limit, String? status});
}
