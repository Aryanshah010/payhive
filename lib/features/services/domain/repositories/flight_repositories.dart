import 'package:dartz/dartz.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';

abstract interface class IFlightRepository {
  Future<Either<Failure, PagedResultEntity<FlightEntity>>> getFlights({
    required int page,
    required int limit,
    String from,
    String to,
    String? date,
  });

  Future<Either<Failure, CreateBookingResultEntity>> createFlightBooking({
    required String flightId,
    required int quantity,
  });

  Future<Either<Failure, PayBookingResultEntity>> payBooking({
    required String bookingId,
    String? idempotencyKey,
  });

  Future<Either<Failure, PagedResultEntity<FlightBookingItemEntity>>>
  getFlightBookings({required int page, required int limit, String? status});
}
