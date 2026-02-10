// ignore_for_file: unnecessary_cast

import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';

class RecipientApiModel {
  final String id;
  final String fullName;
  final String phoneNumber;

  RecipientApiModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
  });

  factory RecipientApiModel.fromJson(Map<String, dynamic> json) {
    return RecipientApiModel(
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

class PreviewApiModel {
  final RecipientApiModel recipient;
  final String? warning;

  PreviewApiModel({required this.recipient, this.warning});

  factory PreviewApiModel.fromJson(Map<String, dynamic> json) {
    final rawRecipient =
        json['recipient'] ?? json['to'] ?? json['beneficiary'] ?? {};

    // coerce to Map<String, dynamic> safely
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

    return PreviewApiModel(
      recipient: RecipientApiModel.fromJson(recipientMap),
      warning: warning,
    );
  }

  PreviewEntity toEntity() {
    return PreviewEntity(recipient: recipient.toEntity(), warning: warning);
  }
}

class ReceiptApiModel {
  final String txId;
  final String status;
  final double amount;
  final String? remark;
  final RecipientApiModel from;
  final RecipientApiModel to;
  final DateTime createdAt;

  ReceiptApiModel({
    required this.txId,
    required this.status,
    required this.amount,
    this.remark,
    required this.from,
    required this.to,
    required this.createdAt,
  });

  factory ReceiptApiModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload =
        (json['receipt'] is Map)
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

    return ReceiptApiModel(
      txId: (payload['txId'] ?? payload['_id'] ?? '').toString(),
      status: (payload['status'] ?? '').toString(),
      amount: _parseAmount(payload['amount']),
      remark: payload['remark']?.toString(),
      from: RecipientApiModel.fromJson(fromMap),
      to: RecipientApiModel.fromJson(toMap),
      createdAt: _parseDate(payload['createdAt']),
    );
  }

  ReceiptEntity toEntity() {
    return ReceiptEntity(
      txId: txId,
      status: status,
      amount: amount,
      remark: remark,
      from: from.toEntity(),
      to: to.toEntity(),
      createdAt: createdAt,
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
