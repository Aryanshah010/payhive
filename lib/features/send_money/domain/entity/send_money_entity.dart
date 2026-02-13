import 'package:equatable/equatable.dart';

class RecipientEntity extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;

  const RecipientEntity({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [id, fullName, phoneNumber];
}

class PreviewEntity extends Equatable {
  final RecipientEntity recipient;
  final String? warning;

  const PreviewEntity({required this.recipient, this.warning});

  @override
  List<Object?> get props => [recipient, warning];
}

class ReceiptEntity extends Equatable {
  final String txId;
  final String status;
  final double amount;
  final String? remark;
  final RecipientEntity from;
  final RecipientEntity to;
  final DateTime createdAt;
  final String? direction;

  const ReceiptEntity({
    required this.txId,
    required this.status,
    required this.amount,
    this.remark,
    required this.from,
    required this.to,
    required this.createdAt,
    this.direction,
  });

  @override
  List<Object?> get props => [
    txId,
    status,
    amount,
    remark,
    from,
    to,
    createdAt,
    direction,
  ];
}
