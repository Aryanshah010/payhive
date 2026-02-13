import 'package:flutter/material.dart';

enum StatementStatusType { complete, pending, paymentRejected }

class StatementStatusUi {
  final StatementStatusType type;
  final String label;
  final Color color;
  final IconData icon;

  const StatementStatusUi({
    required this.type,
    required this.label,
    required this.color,
    required this.icon,
  });
}

StatementStatusUi mapStatementStatus(String? rawStatus) {
  final normalized = rawStatus?.trim().toUpperCase();

  if (normalized == 'PENDING') {
    return const StatementStatusUi(
      type: StatementStatusType.pending,
      label: 'Pending',
      color: Colors.amber,
      icon: Icons.hourglass_top_rounded,
    );
  }

  if (normalized == 'UNDO_REJECTED' ||
      normalized == 'REJECTED' ||
      normalized == 'FAILED' ||
      normalized == 'REVERSAL_REJECTED') {
    return const StatementStatusUi(
      type: StatementStatusType.paymentRejected,
      label: 'Payment Rejected',
      color: Colors.red,
      icon: Icons.cancel_rounded,
    );
  }

  return const StatementStatusUi(
    type: StatementStatusType.complete,
    label: 'Complete',
    color: Colors.green,
    icon: Icons.check_circle_rounded,
  );
}
