import 'package:payhive/features/bank_transfer/data/models/bank_api_model.dart';
import 'package:payhive/features/bank_transfer/data/models/bank_transfer_api_model.dart';

abstract interface class IBankTransferRemoteDatasource {
  Future<List<BankApiModel>> getBanks();

  Future<BankTransferPreviewApiModel> previewBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
  });

  Future<BankTransferReceiptApiModel> confirmBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
    required String pin,
    String? idempotencyKey,
  });
}
