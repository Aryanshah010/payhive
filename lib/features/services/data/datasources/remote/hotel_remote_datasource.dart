import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/services/data/datasources/hotel_datasource.dart';
import 'package:payhive/features/services/data/models/hotel_api_model.dart';

final hotelRemoteDatasourceProvider = Provider<IHotelRemoteDatasource>((ref) {
  return HotelRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class HotelRemoteDatasource implements IHotelRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  HotelRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  Options _authOptions({String? idempotencyKey}) {
    final token = _tokenService.getToken();
    final headers = <String, dynamic>{'Authorization': 'Bearer $token'};

    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey.trim();
    }

    return Options(headers: headers);
  }

  @override
  Future<PagedResultApiModel<HotelApiModel>> getHotels({
    required int page,
    required int limit,
    String city = '',
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
    final cityTrimmed = city.trim();

    if (cityTrimmed.isNotEmpty) {
      queryParameters['city'] = cityTrimmed;
    }

    final response = await _apiClient.get(
      ApiEndpoints.hotels,
      queryParameters: queryParameters,
      options: _authOptions(),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PagedResultApiModel.fromJson(data, HotelApiModel.fromJson);
  }

  @override
  Future<CreateHotelBookingResultApiModel> createHotelBooking({
    required String hotelId,
    required int rooms,
    required int nights,
    required String checkin,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bookings,
      data: {
        'type': 'hotel',
        'itemId': hotelId,
        'rooms': rooms,
        'nights': nights,
        'checkin': checkin,
      },
      options: _authOptions(),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return CreateHotelBookingResultApiModel.fromJson(data);
  }

  @override
  Future<PayHotelBookingResultApiModel> payHotelBooking({
    required String bookingId,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bookingPay(bookingId),
      data: <String, dynamic>{},
      options: _authOptions(idempotencyKey: idempotencyKey),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PayHotelBookingResultApiModel.fromJson(data);
  }

  @override
  Future<PagedResultApiModel<HotelBookingItemApiModel>> getHotelBookings({
    required int page,
    required int limit,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      'type': 'hotel',
    };

    final normalizedStatus = status?.trim().toLowerCase();
    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      queryParameters['status'] = normalizedStatus;
    }

    final response = await _apiClient.get(
      ApiEndpoints.bookings,
      queryParameters: queryParameters,
      options: _authOptions(),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PagedResultApiModel.fromJson(
      data,
      HotelBookingItemApiModel.fromJson,
    );
  }
}
