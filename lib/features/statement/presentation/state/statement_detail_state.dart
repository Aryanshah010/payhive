import 'package:equatable/equatable.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

enum StatementDetailViewStatus { initial, loading, loaded, error }

class StatementDetailState extends Equatable {
  static const _unset = Object();

  final StatementDetailViewStatus status;
  final ReceiptEntity? receipt;
  final UndoStatusUi? undoStatus;
  final String? errorMessage;

  const StatementDetailState({
    required this.status,
    this.receipt,
    this.undoStatus,
    this.errorMessage,
  });

  factory StatementDetailState.initial() {
    return const StatementDetailState(
      status: StatementDetailViewStatus.initial,
      receipt: null,
      undoStatus: null,
      errorMessage: null,
    );
  }

  StatementDetailState copyWith({
    StatementDetailViewStatus? status,
    Object? receipt = _unset,
    Object? undoStatus = _unset,
    Object? errorMessage = _unset,
  }) {
    return StatementDetailState(
      status: status ?? this.status,
      receipt: receipt == _unset ? this.receipt : receipt as ReceiptEntity?,
      undoStatus: undoStatus == _unset
          ? this.undoStatus
          : undoStatus as UndoStatusUi?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, receipt, undoStatus, errorMessage];
}
