// ignore_for_file: unnecessary_cast

import 'package:payhive/core/entities/transaction_entity.dart';

class BankTransferRecipientApiModel {
  final String id;
  final String fullName;
  final String phoneNumber;

  BankTransferRecipientApiModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
  });

  factory BankTransferRecipientApiModel.fromJson(Map<String, dynamic> json) {
    return BankTransferRecipientApiModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
    );
  }

  RecipientEntity toEntity() {
    return RecipientEntity(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}

class BankTransferPreviewApiModel {
  final BankTransferRecipientApiModel recipient;
  final String? warning;

  BankTransferPreviewApiModel({required this.recipient, this.warning});

  factory BankTransferPreviewApiModel.fromJson(Map<String, dynamic> json) {
    final rawRecipient =
        json['recipient'] ?? json['to'] ?? json['beneficiary'] ?? {};

    final Map<String, dynamic> recipientMap = (rawRecipient is Map)
        ? Map<String, dynamic>.from(rawRecipient as Map)
        : <String, dynamic>{};

    final rawWarning = json['warning'];
    String? warning;
    if (rawWarning is String && rawWarning.trim().isNotEmpty) {
      warning = rawWarning;
    } else if (rawWarning is bool && rawWarning) {
      warning = 'This amount is significantly higher than your recent average.';
    }

    return BankTransferPreviewApiModel(
      recipient: BankTransferRecipientApiModel.fromJson(recipientMap),
      warning: warning,
    );
  }

  PreviewEntity toEntity() {
    return PreviewEntity(recipient: recipient.toEntity(), warning: warning);
  }
}

class BankTransferReceiptApiModel {
  final String txId;
  final String status;
  final double amount;
  final String? remark;
  final String? paymentType;
  final Map<String, dynamic>? meta;
  final BankTransferRecipientApiModel from;
  final BankTransferRecipientApiModel to;
  final DateTime createdAt;
  final String? direction;

  BankTransferReceiptApiModel({
    required this.txId,
    required this.status,
    required this.amount,
    this.remark,
    this.paymentType,
    this.meta,
    required this.from,
    required this.to,
    required this.createdAt,
    this.direction,
  });

  factory BankTransferReceiptApiModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload = (json['receipt'] is Map)
        ? Map<String, dynamic>.from(json['receipt'] as Map)
        : json;

    final rawFrom = payload['from'] ?? {};
    final rawTo = payload['to'] ?? {};

    final Map<String, dynamic> fromMap = (rawFrom is Map)
        ? Map<String, dynamic>.from(rawFrom as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> toMap = (rawTo is Map)
        ? Map<String, dynamic>.from(rawTo as Map)
        : <String, dynamic>{};

    return BankTransferReceiptApiModel(
      txId: (payload['txId'] ?? payload['_id'] ?? '').toString(),
      status: (payload['status'] ?? '').toString(),
      amount: _parseAmount(payload['amount']),
      remark: payload['remark']?.toString(),
      paymentType: payload['paymentType']?.toString(),
      meta: _asNullableMap(payload['meta']),
      from: BankTransferRecipientApiModel.fromJson(fromMap),
      to: BankTransferRecipientApiModel.fromJson(toMap),
      createdAt: _parseDate(payload['createdAt']),
      direction: payload['direction']?.toString(),
    );
  }

  ReceiptEntity toEntity() {
    return ReceiptEntity(
      txId: txId,
      status: status,
      amount: amount,
      remark: remark,
      paymentType: paymentType,
      meta: meta,
      from: from.toEntity(),
      to: to.toEntity(),
      createdAt: createdAt,
      direction: direction,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic>? _asNullableMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
