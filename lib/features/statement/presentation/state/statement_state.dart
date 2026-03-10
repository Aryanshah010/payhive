import 'package:equatable/equatable.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

enum StatementViewStatus { initial, loading, loaded, error }

enum StatementDirectionFilter { all, debit, credit }

extension StatementDirectionFilterX on StatementDirectionFilter {
  String get apiValue {
    switch (this) {
      case StatementDirectionFilter.all:
        return 'all';
      case StatementDirectionFilter.debit:
        return 'debit';
      case StatementDirectionFilter.credit:
        return 'credit';
    }
  }
}

class StatementState extends Equatable {
  static const _unset = Object();

  final StatementViewStatus status;
  final List<ReceiptEntity> transactions;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String search;
  final StatementDirectionFilter direction;
  final Map<String, UndoStatusUi> undoStatusByTxId;
  final Set<String> requestingUndoTxIds;
  final String? actionMessage;

  const StatementState({
    required this.status,
    required this.transactions,
    this.errorMessage,
    required this.page,
    required this.totalPages,
    required this.isLoadingMore,
    required this.search,
    required this.direction,
    required this.undoStatusByTxId,
    required this.requestingUndoTxIds,
    this.actionMessage,
  });

  factory StatementState.initial() {
    return const StatementState(
      status: StatementViewStatus.initial,
      transactions: [],
      errorMessage: null,
      page: 0,
      totalPages: 1,
      isLoadingMore: false,
      search: '',
      direction: StatementDirectionFilter.all,
      undoStatusByTxId: <String, UndoStatusUi>{},
      requestingUndoTxIds: <String>{},
      actionMessage: null,
    );
  }

  bool get hasMore => page < totalPages;

  StatementState copyWith({
    StatementViewStatus? status,
    List<ReceiptEntity>? transactions,
    Object? errorMessage = _unset,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? search,
    StatementDirectionFilter? direction,
    Map<String, UndoStatusUi>? undoStatusByTxId,
    Set<String>? requestingUndoTxIds,
    Object? actionMessage = _unset,
  }) {
    return StatementState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      search: search ?? this.search,
      direction: direction ?? this.direction,
      undoStatusByTxId: undoStatusByTxId ?? this.undoStatusByTxId,
      requestingUndoTxIds: requestingUndoTxIds ?? this.requestingUndoTxIds,
      actionMessage: actionMessage == _unset
          ? this.actionMessage
          : actionMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    errorMessage,
    page,
    totalPages,
    isLoadingMore,
    search,
    direction,
    undoStatusByTxId,
    requestingUndoTxIds,
    actionMessage,
  ];
}
