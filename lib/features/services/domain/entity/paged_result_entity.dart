import 'package:equatable/equatable.dart';

class PagedResultEntity<T> extends Equatable {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PagedResultEntity({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [items, total, page, limit, totalPages];
}
