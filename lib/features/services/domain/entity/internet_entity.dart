import 'package:equatable/equatable.dart';

class InternetServiceEntity extends Equatable {
  final String id;
  final String type;
  final String provider;
  final String name;
  final String packageLabel;
  final double amount;
  final String validationRegex;
  final bool isActive;
  final Map<String, dynamic> meta;

  const InternetServiceEntity({
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

class InternetPaymentReceiptEntity extends Equatable {
  final String receiptNo;
  final String serviceType;
  final String serviceId;
  final String provider;
  final String planName;
  final String customerIdMasked;
  final double amount;
  final DateTime? createdAt;

  const InternetPaymentReceiptEntity({
    required this.receiptNo,
    required this.serviceType,
    required this.serviceId,
    required this.provider,
    required this.planName,
    required this.customerIdMasked,
    required this.amount,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    receiptNo,
    serviceType,
    serviceId,
    provider,
    planName,
    customerIdMasked,
    amount,
    createdAt,
  ];
}

class PayInternetResultEntity extends Equatable {
  final String transactionId;
  final InternetPaymentReceiptEntity receipt;
  final bool idempotentReplay;

  const PayInternetResultEntity({
    required this.transactionId,
    required this.receipt,
    required this.idempotentReplay,
  });

  @override
  List<Object?> get props => [transactionId, receipt, idempotentReplay];
}
