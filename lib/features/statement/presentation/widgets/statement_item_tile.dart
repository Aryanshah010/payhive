import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

enum StatementEntryDirection { debit, credit }

class StatementItemTile extends StatelessWidget {
  final ReceiptEntity transaction;
  final String? currentUserId;
  final UndoStatusUi? undoStatus;
  final bool isRequestingUndo;
  final VoidCallback? onUndoTap;
  final VoidCallback? onTap;

  const StatementItemTile({
    super.key,
    required this.transaction,
    this.currentUserId,
    this.undoStatus,
    this.isRequestingUndo = false,
    this.onUndoTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final direction = _resolveDirection();
    final isDebit = direction == StatementEntryDirection.debit;
    final isBankTransfer = _isBankTransferTransaction();
    final isServiceDebit = isDebit && _isServiceDebitTransaction();
    final canShowUndoControls = isDebit && !isServiceDebit && !isBankTransfer;
    final showUndoButton = canShowUndoControls && undoStatus == null;
    final showUndoStatusChip = canShowUndoControls && undoStatus != null;
    final counterparty = isDebit ? transaction.to : transaction.from;
    final amountColor = isDebit ? Colors.red.shade600 : Colors.green.shade600;
    final arrowIcon = isDebit
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    final title = isDebit
        ? (isServiceDebit
              ? 'Service Payment'
              : 'Fund transferred to ${counterparty.fullName}')
        : 'Money received from ${counterparty.fullName}';
    final subtitle = DateFormat(
      'EEE, dd MMM yyyy hh:mm a',
    ).format(transaction.createdAt.toLocal());
    final amountText = NumberFormat('#,##0.00').format(transaction.amount);
    final theme = Theme.of(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final scale = isTablet ? 1.12 : 1.0;
    final cardRadius = isTablet ? 18.0 : 16.0;
    final amountSize = isTablet ? 22.0 : 18.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Ink(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
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
                        fontSize: 16 * scale,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14 * scale,
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
                          fontSize: 12.5 * scale,
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
                            Icon(
                              arrowIcon,
                              color: amountColor,
                              size: amountSize,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              amountText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: amountColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 19 * scale,
                              ),
                            ),
                          ],
                        ),
                        if (showUndoButton) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isRequestingUndo ? null : onUndoTap,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size(
                                isTablet ? 132 : 110,
                                isTablet ? 34 : 30,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: isRequestingUndo
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'REQUEST UNDO',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ],
                        if (showUndoStatusChip) ...[
                          const SizedBox(height: 10),
                          _UndoStatusChip(status: undoStatus!),
                        ],
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(arrowIcon, color: amountColor, size: amountSize),
                        const SizedBox(width: 4),
                        Text(
                          amountText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 19 * scale,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
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

  bool _isServiceDebitTransaction() {
    if (_matchesServicePaymentType()) {
      return true;
    }
    if (_matchesServiceRemark()) {
      return true;
    }
    return _isLegacyServiceSelfTransfer();
  }

  bool _matchesServicePaymentType() {
    final type = (transaction.paymentType ?? '').trim().toUpperCase();
    if (type.startsWith('BOOKING_') || type.startsWith('UTILITY_')) {
      return true;
    }
    return type == 'BOOKING_PAYMENT' || type == 'UTILITY_PAYMENT';
  }

  bool _matchesServiceRemark() {
    final remark = (transaction.remark ?? '').trim().toLowerCase();
    if (remark.isEmpty) return false;

    const tokens = <String>[
      'booking payment',
      'internet payment',
      'topup payment',
      'recharge payment',
      'utility payment',
    ];

    return tokens.any(remark.contains);
  }

  bool _isLegacyServiceSelfTransfer() {
    final fromId = transaction.from.id.trim();
    final toId = transaction.to.id.trim();

    if (fromId.isNotEmpty && toId.isNotEmpty && fromId == toId) {
      return true;
    }

    if (fromId.isEmpty && toId.isEmpty) {
      final fromPhone = transaction.from.phoneNumber.trim();
      final toPhone = transaction.to.phoneNumber.trim();
      if (fromPhone.isNotEmpty && fromPhone == toPhone) {
        return true;
      }
    }

    return false;
  }

  bool _isBankTransferTransaction() {
    final type = (transaction.paymentType ?? '').trim().toUpperCase();
    if (type == 'BANK_TRANSFER') return true;
    return _matchesBankTransferMeta();
  }

  bool _matchesBankTransferMeta() {
    final meta = transaction.meta;
    if (meta == null || meta.isEmpty) return false;

    final rawType = meta['type'];
    final typeValue = rawType?.toString().trim().toLowerCase();
    if (typeValue != null && typeValue.contains('bank_transfer')) {
      return true;
    }

    const keys = <String>[
      'bankId',
      'bankCode',
      'bankName',
      'accountNumber',
      'accountNumberMasked',
      'receiverId',
    ];

    for (final key in keys) {
      final raw = meta[key];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isNotEmpty) return true;
    }

    return false;
  }
}

class _UndoStatusChip extends StatelessWidget {
  final UndoStatusUi status;

  const _UndoStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withOpacity(0.45)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: isTablet ? 12 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
