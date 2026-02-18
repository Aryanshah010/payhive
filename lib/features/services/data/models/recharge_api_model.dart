import 'package:payhive/features/services/domain/entity/recharge_entity.dart';

class PagedResultApiModel<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PagedResultApiModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PagedResultApiModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawItems = json['items'];
    final items = (rawItems is List ? rawItems : const <dynamic>[])
        .whereType<Map>()
        .map((item) => itemParser(Map<String, dynamic>.from(item)))
        .toList();

    final page = _asInt(json['page'], fallback: 1);
    final limit = _asInt(json['limit'], fallback: 10);
    final total = _asInt(json['total'], fallback: items.length);
    final totalPages = _asInt(
      json['totalPages'],
      fallback: total == 0 ? 1 : ((total / limit).ceil()),
    );

    return PagedResultApiModel(
      items: items,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }
}

class RechargeServiceApiModel {
  final String id;
  final String type;
  final String provider;
  final String name;
  final String packageLabel;
  final double amount;
  final String validationRegex;
  final bool isActive;
  final Map<String, dynamic> meta;

  const RechargeServiceApiModel({
    required this.id,
    required this.type,
    required this.provider,
    required this.name,
    required this.packageLabel,
    required this.amount,
    required this.validationRegex,
    required this.isActive,
    required this.meta,
  });

  factory RechargeServiceApiModel.fromJson(Map<String, dynamic> json) {
    return RechargeServiceApiModel(
      id: _extractId(json),
      type: _asString(json['type']),
      provider: _asString(json['provider']),
      name: _asString(json['name']),
      packageLabel: _asString(json['packageLabel']),
      amount: _asDouble(json['amount']),
      validationRegex: _asString(json['validationRegex']),
      isActive: _asBool(json['isActive'], fallback: true),
      meta: _asMap(json['meta']),
    );
  }

  RechargeServiceEntity toEntity() {
    return RechargeServiceEntity(
      id: id,
      type: type,
      provider: provider,
      name: name,
      packageLabel: packageLabel,
      amount: amount,
      validationRegex: validationRegex,
      isActive: isActive,
      meta: meta,
    );
  }
}

class RechargePaymentReceiptApiModel {
  final String receiptNo;
  final String serviceType;
  final String serviceId;
  final String carrier;
  final String packageLabel;
  final String phoneMasked;
  final double amount;
  final DateTime? createdAt;

  const RechargePaymentReceiptApiModel({
    required this.receiptNo,
    required this.serviceType,
    required this.serviceId,
    required this.carrier,
    required this.packageLabel,
    required this.phoneMasked,
    required this.amount,
    this.createdAt,
  });

  factory RechargePaymentReceiptApiModel.fromJson(Map<String, dynamic> json) {
    return RechargePaymentReceiptApiModel(
      receiptNo: _asString(json['receiptNo']),
      serviceType: _asString(json['serviceType']),
      serviceId: _asString(json['serviceId']),
      carrier: _asString(json['carrier']),
      packageLabel: _asString(json['packageLabel']),
      phoneMasked: _asString(json['phoneMasked']),
      amount: _asDouble(json['amount']),
      createdAt: _asDateTime(json['createdAt']),
    );
  }

  RechargePaymentReceiptEntity toEntity() {
    return RechargePaymentReceiptEntity(
      receiptNo: receiptNo,
      serviceType: serviceType,
      serviceId: serviceId,
      carrier: carrier,
      packageLabel: packageLabel,
      phoneMasked: phoneMasked,
      amount: amount,
      createdAt: createdAt,
    );
  }
}

class PayRechargeResultApiModel {
  final String transactionId;
  final RechargePaymentReceiptApiModel receipt;
  final bool idempotentReplay;

  const PayRechargeResultApiModel({
    required this.transactionId,
    required this.receipt,
    required this.idempotentReplay,
  });

  factory PayRechargeResultApiModel.fromJson(Map<String, dynamic> json) {
    return PayRechargeResultApiModel(
      transactionId: _asString(json['transactionId']),
      receipt: RechargePaymentReceiptApiModel.fromJson(_asMap(json['receipt'])),
      idempotentReplay: _asBool(json['idempotentReplay']),
    );
  }

  PayRechargeResultEntity toEntity() {
    return PayRechargeResultEntity(
      transactionId: transactionId,
      receipt: receipt.toEntity(),
      idempotentReplay: idempotentReplay,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

String _extractId(Map<String, dynamic> json) {
  return _asString(json['_id'] ?? json['id']);
}

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return null;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  if (value is num) return value != 0;
  return fallback;
}
