import 'package:payhive/features/services/data/models/internet_api_model.dart';

abstract interface class IInternetRemoteDatasource {
  Future<PagedResultApiModel<InternetServiceApiModel>> getInternetServices({
    required int page,
    required int limit,
    String provider,
    String search,
  });

  Future<PayInternetResultApiModel> payInternetService({
    required String serviceId,
    required String customerId,
    String? idempotencyKey,
  });
}
