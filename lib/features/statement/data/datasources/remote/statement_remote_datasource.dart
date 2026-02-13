import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/statement/data/datasources/statement_datasource.dart';
import 'package:payhive/features/statement/data/models/statement_api_model.dart';

final statementRemoteDatasourceProvider = Provider<IStatementRemoteDatasource>((
  ref,
) {
  return StatementRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class StatementRemoteDatasource implements IStatementRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  StatementRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  Options _authOptions() {
    final token = _tokenService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<TransactionHistoryApiModel> getHistory({
    required int page,
    required int limit,
    String search = '',
    String direction = 'all',
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
    final normalizedSearch = search.trim();
    if (normalizedSearch.isNotEmpty) {
      queryParameters['search'] = normalizedSearch;
    }
    if (direction != 'all') {
      queryParameters['direction'] = direction;
    }

    final response = await _apiClient.get(
      ApiEndpoints.transactionsHistory,
      queryParameters: queryParameters,
      options: _authOptions(),
    );

    final data = response.data['data'];
    return TransactionHistoryApiModel.fromJson(data);
  }

  @override
  Future<StatementReceiptApiModel> getDetail({required String txId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.transactionDetail(txId),
      options: _authOptions(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return StatementReceiptApiModel.fromJson(data);
  }
}
