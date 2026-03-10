import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/request_money/data/datasources/request_money_datasource.dart';
import 'package:payhive/features/request_money/data/models/request_money_api_model.dart';

final requestMoneyRemoteDatasourceProvider =
    Provider<IRequestMoneyRemoteDatasource>((ref) {
      return RequestMoneyRemoteDatasource(
        apiClient: ref.read(apiClientProvider),
        tokenService: ref.read(tokenServiceProvider),
      );
    });

class RequestMoneyRemoteDatasource implements IRequestMoneyRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  RequestMoneyRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  Options _authOptions() {
    final token = _tokenService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<MoneyRequestApiModel> createRequest({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.moneyRequests,
      data: {
        'toPhoneNumber': toPhoneNumber,
        'amount': amount,
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
      options: _authOptions(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return MoneyRequestApiModel.fromJson(data);
  }

  @override
  Future<MoneyRequestPageApiModel> getOutgoingRequests({
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.moneyRequestsOutgoing,
      queryParameters: {'status': 'pending', 'page': page, 'limit': limit},
      options: _authOptions(),
    );

    final data = response.data['data'];
    return MoneyRequestPageApiModel.fromJson(data);
  }

  @override
  Future<MoneyRequestApiModel> getRequestDetail({
    required String requestId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.moneyRequestDetail(requestId),
      options: _authOptions(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return MoneyRequestApiModel.fromJson(data);
  }

  @override
  Future<MoneyRequestApiModel> respondToRequest({
    required String requestId,
    required String action,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.moneyRequestRespond(requestId),
      data: {'action': action},
      options: _authOptions(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return MoneyRequestApiModel.fromJson(data);
  }

  @override
  Future<MoneyRequestApiModel> cancelRequest({
    required String requestId,
  }) async {
    return respondToRequest(
      requestId: requestId,
      action: IRequestMoneyRemoteDatasource.actionCancel,
    );
  }
}
