import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/api/api_client.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/features/send_money/data/models/bank_api_model.dart';
import 'package:payhive/features/send_money/domain/entity/bank_entity.dart';

final bankListProvider = FutureProvider<List<BankEntity>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.banks);

  final payload = response.data;
  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => BankApiModel.fromJson(Map<String, dynamic>.from(item)))
          .map((model) => model.toEntity())
          .toList();
    }
  }

  return const [];
});
