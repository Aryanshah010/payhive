import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/services/data/datasources/recharge_datasource.dart';
import 'package:payhive/features/services/data/models/recharge_api_model.dart';

final rechargeRemoteDatasourceProvider = Provider<IRechargeRemoteDatasource>((
  ref,
) {
  return RechargeRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class RechargeRemoteDatasource implements IRechargeRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  RechargeRemoteDatasource({
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
  Future<PagedResultApiModel<RechargeServiceApiModel>> getRechargeServices({
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
      ApiEndpoints.topupServices,
      queryParameters: queryParameters,
      options: _authOptions(),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PagedResultApiModel.fromJson(data, RechargeServiceApiModel.fromJson);
  }

  @override
  Future<PayRechargeResultApiModel> payRechargeService({
    required String serviceId,
    required String phoneNumber,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.topupServicePay(serviceId),
      data: {'phoneNumber': phoneNumber},
      options: _authOptions(idempotencyKey: idempotencyKey),
    );

    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PayRechargeResultApiModel.fromJson(data);
  }
}
