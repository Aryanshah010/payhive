import 'package:equatable/equatable.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';

class PaginationEntity extends Equatable {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  const PaginationEntity({this.page, this.limit, this.total, this.totalPages});

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}

class TransactionHistoryEntity extends Equatable {
  final List<ReceiptEntity> transactions;
  final PaginationEntity? pagination;

  const TransactionHistoryEntity({
    required this.transactions,
    this.pagination,
  });

  @override
  List<Object?> get props => [transactions, pagination];
}
