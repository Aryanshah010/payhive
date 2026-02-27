import 'package:payhive/features/request_money/data/models/request_money_api_model.dart';

abstract interface class IRequestMoneyRemoteDatasource {
  Future<MoneyRequestApiModel> createRequest({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  });

  Future<MoneyRequestPageApiModel> getOutgoingRequests({
    required int page,
    required int limit,
  });

  Future<MoneyRequestApiModel> cancelRequest({required String requestId});
}
