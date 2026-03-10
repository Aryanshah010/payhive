import 'package:payhive/features/services/data/models/recharge_api_model.dart';

abstract interface class IRechargeRemoteDatasource {
  Future<PagedResultApiModel<RechargeServiceApiModel>> getRechargeServices({
    required int page,
    required int limit,
    String provider,
    String search,
  });

  Future<PayRechargeResultApiModel> payRechargeService({
    required String serviceId,
    required String phoneNumber,
    String? idempotencyKey,
  });
}
