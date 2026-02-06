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
    return RecipientEntity(id: id, fullName: fullName, phoneNumber: phoneNumber);
  }
}

class PreviewApiModel {
  final RecipientApiModel recipient;
  final String? warning;

  PreviewApiModel({required this.recipient, this.warning});

  factory PreviewApiModel.fromJson(Map<String, dynamic> json) {
    final recipientJson = (json['recipient'] ?? json['to'] ?? json['beneficiary'])
        as Map<String, dynamic>?;

    final rawWarning = json['warning'];
    String? warning;
    if (rawWarning is String && rawWarning.trim().isNotEmpty) {
      warning = rawWarning;
    } else if (rawWarning is bool && rawWarning) {
      warning =
          'This amount is significantly higher than your recent average.';
    }

    return PreviewApiModel(
      recipient: RecipientApiModel.fromJson(recipientJson ?? {}),
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
    return ReceiptApiModel(
      txId: (json['txId'] ?? json['_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: _parseAmount(json['amount']),
      remark: json['remark']?.toString(),
      from: RecipientApiModel.fromJson((json['from'] ?? {}) as Map<String, dynamic>),
      to: RecipientApiModel.fromJson((json['to'] ?? {}) as Map<String, dynamic>),
      createdAt: _parseDate(json['createdAt']),
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
