import 'package:payhive/features/send_money/domain/entity/bank_entity.dart';

class BankApiModel {
  final String id;
  final String name;
  final String code;
  final double minTransfer;
  final double maxTransfer;
  final double fee;

  const BankApiModel({
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
      code: (json['code'] ?? '').toString(),
      minTransfer: _asDouble(json['minTransfer']),
      maxTransfer: _asDouble(json['maxTransfer']),
      fee: _asDouble(json['fee']),
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

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
