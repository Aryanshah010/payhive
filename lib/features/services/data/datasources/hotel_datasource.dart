import 'package:payhive/features/services/data/models/hotel_api_model.dart';

abstract interface class IHotelRemoteDatasource {
  Future<PagedResultApiModel<HotelApiModel>> getHotels({
    required int page,
    required int limit,
    String city,
  });

  Future<CreateHotelBookingResultApiModel> createHotelBooking({
    required String hotelId,
    required int rooms,
    required int nights,
    required String checkin,
  });

  Future<PayHotelBookingResultApiModel> payHotelBooking({
    required String bookingId,
    String? idempotencyKey,
  });

  Future<PagedResultApiModel<HotelBookingItemApiModel>> getHotelBookings({
    required int page,
    required int limit,
    String? status,
  });
}
