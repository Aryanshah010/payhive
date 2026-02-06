import 'package:payhive/features/send_money/data/models/send_money_api_model.dart';

abstract interface class ISendMoneyRemoteDatasource {
  Future<PreviewApiModel> previewTransfer({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  });

  Future<ReceiptApiModel> confirmTransfer({
    required String toPhoneNumber,
    required double amount,
    required String pin,
    String? remark,
    String? idempotencyKey,
  });

  Future<RecipientApiModel> lookupBeneficiary({
    required String phoneNumber,
  });
}
