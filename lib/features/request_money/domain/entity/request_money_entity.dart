import 'package:equatable/equatable.dart';
import 'package:payhive/core/entities/transaction_entity.dart';

class MoneyRequestEntity extends Equatable {
  final String id;
  final RecipientEntity requester;
  final RecipientEntity receiver;
  final double amount;
  final String remark;
  final String status;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MoneyRequestEntity({
    required this.id,
    required this.requester,
    required this.receiver,
    required this.amount,
    required this.remark,
    required this.status,
    required this.expiresAt,
    this.respondedAt,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status.trim().toUpperCase() == 'PENDING';

  @override
  List<Object?> get props => [
    id,
    requester,
    receiver,
    amount,
    remark,
    status,
    expiresAt,
    respondedAt,
    transactionId,
    createdAt,
    updatedAt,
  ];
}

class MoneyRequestPageEntity extends Equatable {
  final List<MoneyRequestEntity> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const MoneyRequestPageEntity({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, total, page, limit, totalPages];
}
