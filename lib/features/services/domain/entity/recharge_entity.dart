import 'package:equatable/equatable.dart';

class RechargeServiceEntity extends Equatable {
  final String id;
  final String type;
  final String provider;
  final String name;
  final String packageLabel;
  final double amount;
  final String validationRegex;
  final bool isActive;
  final Map<String, dynamic> meta;

  const RechargeServiceEntity({
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

  @override
  List<Object?> get props => [
    id,
    type,
    provider,
    name,
    packageLabel,
    amount,
    validationRegex,
    isActive,
    meta,
  ];
}

class RechargePaymentReceiptEntity extends Equatable {
  final String receiptNo;
  final String serviceType;
  final String serviceId;
  final String carrier;
  final String packageLabel;
  final String phoneMasked;
  final double amount;
  final DateTime? createdAt;

  const RechargePaymentReceiptEntity({
    required this.receiptNo,
    required this.serviceType,
    required this.serviceId,
    required this.carrier,
    required this.packageLabel,
    required this.phoneMasked,
    required this.amount,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    receiptNo,
    serviceType,
    serviceId,
    carrier,
    packageLabel,
    phoneMasked,
    amount,
    createdAt,
  ];
}

class PayRechargeResultEntity extends Equatable {
  final String transactionId;
  final RechargePaymentReceiptEntity receipt;
  final bool idempotentReplay;

  const PayRechargeResultEntity({
    required this.transactionId,
    required this.receipt,
    required this.idempotentReplay,
  });

  @override
  List<Object?> get props => [transactionId, receipt, idempotentReplay];
}
