import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/storage/token_service.dart';
import 'package:payhive/features/bank_transfer/data/datasources/bank_transfer_datasource.dart';
import 'package:payhive/features/bank_transfer/data/models/bank_api_model.dart';
import 'package:payhive/features/bank_transfer/data/models/bank_transfer_api_model.dart';

final bankTransferRemoteDatasourceProvider =
    Provider<IBankTransferRemoteDatasource>((ref) {
      return BankTransferRemoteDatasource(
        apiClient: ref.read(apiClientProvider),
        tokenService: ref.read(tokenServiceProvider),
      );
    });

class BankTransferRemoteDatasource implements IBankTransferRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  BankTransferRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService;

  Options _authOptions({String? idempotencyKey}) {
    final token = _tokenService.getToken();
    final headers = <String, dynamic>{'Authorization': 'Bearer $token'};
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return Options(headers: headers);
  }

  @override
  Future<List<BankApiModel>> getBanks() async {
    final response = await _apiClient.get(
      ApiEndpoints.banks,
      options: _authOptions(),
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => BankApiModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }
    return const [];
  }

  @override
  Future<BankTransferPreviewApiModel> previewBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.transactionsPreview,
      data: {
        'paymentType': 'BANK_TRANSFER',
        'bankName': bankName,
        'accountNumber': accountNumber,
        'amount': amount,
      },
      options: _authOptions(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return BankTransferPreviewApiModel.fromJson(data);
  }

  @override
  Future<BankTransferReceiptApiModel> confirmBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
    required String pin,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.transactionsConfirm,
      data: {
        'paymentType': 'BANK_TRANSFER',
        'bankName': bankName,
        'accountNumber': accountNumber,
        'amount': amount,
        'pin': pin,
      },
      options: _authOptions(idempotencyKey: idempotencyKey),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return BankTransferReceiptApiModel.fromJson(data);
  }
}
