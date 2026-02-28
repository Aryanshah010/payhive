import 'package:flutter/material.dart';

enum UndoStatusType { pending, accepted, rejected }

class UndoStatusUi {
  final UndoStatusType type;
  final String label;
  final Color color;

  const UndoStatusUi({
    required this.type,
    required this.label,
    required this.color,
  });

  bool get isTerminal =>
      type == UndoStatusType.accepted || type == UndoStatusType.rejected;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UndoStatusUi &&
        other.type == type &&
        other.label == label &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(type, label, color);
}

const UndoStatusUi pendingUndoStatus = UndoStatusUi(
  type: UndoStatusType.pending,
  label: 'Pending',
  color: Colors.amber,
);

const UndoStatusUi acceptedUndoStatus = UndoStatusUi(
  type: UndoStatusType.accepted,
  label: 'Accepted',
  color: Colors.green,
);

const UndoStatusUi rejectedUndoStatus = UndoStatusUi(
  type: UndoStatusType.rejected,
  label: 'Rejected',
  color: Colors.red,
);

UndoStatusUi? mapUndoRequestStatus(String? rawStatus) {
  final normalized = rawStatus?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;

  if (normalized == 'PENDING') return pendingUndoStatus;
  if (normalized == 'ACCEPTED') return acceptedUndoStatus;
  if (normalized == 'DENIED' ||
      normalized == 'REJECTED' ||
      normalized == 'UNDO_REJECTED') {
    return rejectedUndoStatus;
  }

  return null;
}

UndoStatusUi? mapUndoLifecycleAction(String? rawAction) {
  final normalized = rawAction?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;

  if (normalized == 'CREATED') return pendingUndoStatus;
  if (normalized == 'ACCEPTED') return acceptedUndoStatus;
  if (normalized == 'DENIED') return rejectedUndoStatus;

  return null;
}
