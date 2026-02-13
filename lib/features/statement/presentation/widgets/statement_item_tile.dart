import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';

enum StatementEntryDirection { debit, credit }

class StatementItemTile extends StatelessWidget {
  final ReceiptEntity transaction;
  final String? currentUserId;
  final VoidCallback? onUndoTap;

  const StatementItemTile({
    super.key,
    required this.transaction,
    this.currentUserId,
    this.onUndoTap,
  });

  @override
  Widget build(BuildContext context) {
    final direction = _resolveDirection();
    final isDebit = direction == StatementEntryDirection.debit;
    final counterparty = isDebit ? transaction.to : transaction.from;
    final amountColor = isDebit ? Colors.red.shade600 : Colors.green.shade600;
    final arrowIcon = isDebit
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    final title = isDebit
        ? 'Fund transferred to ${counterparty.fullName}'
        : 'Money received from ${counterparty.fullName}';
    final subtitle = DateFormat(
      'EEE, dd MMM yyyy hh:mm a',
    ).format(transaction.createdAt.toLocal());
    final amountText = NumberFormat('#,##0.00').format(transaction.amount);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if ((transaction.remark ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    transaction.remark!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          isDebit
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(arrowIcon, color: amountColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          amountText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onUndoTap,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(68, 30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'UNDO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(arrowIcon, color: amountColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      amountText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  StatementEntryDirection _resolveDirection() {
    final apiDirection = transaction.direction?.toUpperCase();
    if (apiDirection == 'DEBIT') return StatementEntryDirection.debit;
    if (apiDirection == 'CREDIT') return StatementEntryDirection.credit;

    if (currentUserId != null && currentUserId!.isNotEmpty) {
      if (transaction.from.id == currentUserId) {
        return StatementEntryDirection.debit;
      }
      if (transaction.to.id == currentUserId) {
        return StatementEntryDirection.credit;
      }
    }

    return StatementEntryDirection.debit;
  }
}
