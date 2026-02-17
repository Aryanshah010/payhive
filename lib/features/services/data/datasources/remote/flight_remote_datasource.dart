import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/services/data/datasources/flight_datasource.dart';
import 'package:payhive/features/services/data/models/flight_api_model.dart';

final flightRemoteDatasourceProvider = Provider<IFlightRemoteDatasource>((ref) {
  return FlightRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class FlightRemoteDatasource implements IFlightRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  FlightRemoteDatasource({
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
  Future<PagedResultApiModel<FlightApiModel>> getFlights({
    required int page,
    required int limit,
    String from = '',
    String to = '',
    String? date,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

    final fromTrimmed = from.trim();
    final toTrimmed = to.trim();
    final dateTrimmed = date?.trim();

    if (fromTrimmed.isNotEmpty) {
      queryParameters['from'] = fromTrimmed;
    }
    if (toTrimmed.isNotEmpty) {
      queryParameters['to'] = toTrimmed;
    }
    if (dateTrimmed != null && dateTrimmed.isNotEmpty) {
      queryParameters['date'] = dateTrimmed;
    }

    final response = await _apiClient.get(
      ApiEndpoints.flights,
      queryParameters: queryParameters,
      options: _authOptions(),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PagedResultApiModel.fromJson(data, FlightApiModel.fromJson);
  }

  @override
  Future<CreateBookingResultApiModel> createFlightBooking({
    required String flightId,
    required int quantity,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bookings,
      data: {'type': 'flight', 'itemId': flightId, 'quantity': quantity},
      options: _authOptions(),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return CreateBookingResultApiModel.fromJson(data);
  }

  @override
  Future<PayBookingResultApiModel> payBooking({
    required String bookingId,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bookingPay(bookingId),
      data: <String, dynamic>{},
      options: _authOptions(idempotencyKey: idempotencyKey),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PayBookingResultApiModel.fromJson(data);
  }

  @override
  Future<PagedResultApiModel<FlightBookingItemApiModel>> getFlightBookings({
    required int page,
    required int limit,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      'type': 'flight',
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
      FlightBookingItemApiModel.fromJson,
    );
  }
}
