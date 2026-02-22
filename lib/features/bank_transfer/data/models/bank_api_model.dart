import 'package:payhive/features/bank_transfer/domain/entity/bank_entity.dart';

class BankApiModel {
  final String id;
  final String name;
  final String code;
  final double minTransfer;
  final double maxTransfer;
  final double fee;

  BankApiModel({
    required this.id,
    required this.name,
    required this.code,
    required this.minTransfer,
    required this.maxTransfer,
    required this.fee,
  });

  factory BankApiModel.fromJson(Map<String, dynamic> json) {
    return BankApiModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? json['bankCode'] ?? '').toString(),
      minTransfer: _parseDouble(json['minTransfer']),
      maxTransfer: _parseDouble(json['maxTransfer']),
      fee: _parseDouble(json['fee']),
    );
  }

  BankEntity toEntity() {
    return BankEntity(
      id: id,
      name: name,
      code: code,
      minTransfer: minTransfer,
      maxTransfer: maxTransfer,
      fee: fee,
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
