import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/send_money/data/datasources/send_money_datasource.dart';
import 'package:payhive/features/send_money/data/models/send_money_api_model.dart';

final sendMoneyRemoteDatasourceProvider = Provider<ISendMoneyRemoteDatasource>(
  (ref) {
    return SendMoneyRemoteDatasource(
      apiClient: ref.read(apiClientProvider),
      tokenService: ref.read(tokenServiceProvider),
    );
  },
);

class SendMoneyRemoteDatasource implements ISendMoneyRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  SendMoneyRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  Options _authOptions({String? idempotencyKey}) {
    final token = _tokenService.getToken();
    final headers = <String, dynamic>{
      'Authorization': 'Bearer $token',
    };
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return Options(headers: headers);
  }

  @override
  Future<PreviewApiModel> previewTransfer({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.transactionsPreview,
      data: {
        'toPhoneNumber': toPhoneNumber,
        'amount': amount,
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
      options: _authOptions(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return PreviewApiModel.fromJson(data);
  }

  @override
  Future<ReceiptApiModel> confirmTransfer({
    required String toPhoneNumber,
    required double amount,
    required String pin,
    String? remark,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.transactionsConfirm,
      data: {
        'toPhoneNumber': toPhoneNumber,
        'amount': amount,
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
        'pin': pin,
      },
      options: _authOptions(idempotencyKey: idempotencyKey),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ReceiptApiModel.fromJson(data);
  }

  @override
  Future<RecipientApiModel> lookupBeneficiary({
    required String phoneNumber,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.transactionsBeneficiary,
      queryParameters: {'phoneNumber': phoneNumber},
      options: _authOptions(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return RecipientApiModel.fromJson(data);
  }
}
