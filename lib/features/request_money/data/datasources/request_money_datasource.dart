import 'package:payhive/features/request_money/data/models/request_money_api_model.dart';

abstract interface class IRequestMoneyRemoteDatasource {
  static const String actionReject = 'REJECT';
  static const String actionCancel = 'CANCEL';

  Future<MoneyRequestApiModel> createRequest({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  });

  Future<MoneyRequestPageApiModel> getOutgoingRequests({
    required int page,
    required int limit,
  });

  Future<MoneyRequestApiModel> getRequestDetail({required String requestId});

  Future<MoneyRequestApiModel> respondToRequest({
    required String requestId,
    required String action,
  });

  Future<MoneyRequestApiModel> cancelRequest({required String requestId});
}
