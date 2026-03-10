import 'package:equatable/equatable.dart';
import 'package:payhive/core/entities/transaction_entity.dart';

class UndoRequestEntity extends Equatable {
  final String id;
  final String transactionId;
  final String? originalTxId;
  final RecipientEntity requester;
  final RecipientEntity receiver;
  final double amount;
  final String status;
  final String? refundTransactionId;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UndoRequestEntity({
    required this.id,
    required this.transactionId,
    required this.originalTxId,
    required this.requester,
    required this.receiver,
    required this.amount,
    required this.status,
    required this.refundTransactionId,
    required this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get normalizedStatus => status.trim().toUpperCase();

  bool get isPending => normalizedStatus == 'PENDING';

  bool get isAccepted => normalizedStatus == 'ACCEPTED';

  bool get isDenied => normalizedStatus == 'DENIED';

  @override
  List<Object?> get props => [
    id,
    transactionId,
    originalTxId,
    requester,
    receiver,
    amount,
    status,
    refundTransactionId,
    respondedAt,
    createdAt,
    updatedAt,
  ];
}

class AcceptUndoResultEntity extends Equatable {
  final UndoRequestEntity request;
  final ReceiptEntity receipt;

  const AcceptUndoResultEntity({required this.request, required this.receipt});

  @override
  List<Object?> get props => [request, receipt];
}
