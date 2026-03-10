import 'package:payhive/features/services/data/models/flight_api_model.dart';

abstract interface class IFlightRemoteDatasource {
  Future<PagedResultApiModel<FlightApiModel>> getFlights({
    required int page,
    required int limit,
    String from,
    String to,
    String? date,
  });

  Future<CreateBookingResultApiModel> createFlightBooking({
    required String flightId,
    required int quantity,
  });

  Future<PayBookingResultApiModel> payBooking({
    required String bookingId,
    String? idempotencyKey,
  });

  Future<PagedResultApiModel<FlightBookingItemApiModel>> getFlightBookings({
    required int page,
    required int limit,
    String? status,
  });
}
