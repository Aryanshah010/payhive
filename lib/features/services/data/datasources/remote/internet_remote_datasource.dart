import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/services/data/datasources/internet_datasource.dart';
import 'package:payhive/features/services/data/models/internet_api_model.dart';

final internetRemoteDatasourceProvider = Provider<IInternetRemoteDatasource>((
  ref,
) {
  return InternetRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class InternetRemoteDatasource implements IInternetRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  InternetRemoteDatasource({
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
  Future<PagedResultApiModel<InternetServiceApiModel>> getInternetServices({
    required int page,
    required int limit,
    String provider = '',
    String search = '',
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
    final normalizedProvider = provider.trim();
    final normalizedSearch = search.trim();

    if (normalizedProvider.isNotEmpty) {
      queryParameters['provider'] = normalizedProvider;
    }
    if (normalizedSearch.isNotEmpty) {
      queryParameters['search'] = normalizedSearch;
    }

    final response = await _apiClient.get(
      ApiEndpoints.internetServices,
      queryParameters: queryParameters,
      options: _authOptions(),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PagedResultApiModel.fromJson(data, InternetServiceApiModel.fromJson);
  }

  @override
  Future<PayInternetResultApiModel> payInternetService({
    required String serviceId,
    required String customerId,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.internetServicePay(serviceId),
      data: {'customerId': customerId},
      options: _authOptions(idempotencyKey: idempotencyKey),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PayInternetResultApiModel.fromJson(data);
  }
}
