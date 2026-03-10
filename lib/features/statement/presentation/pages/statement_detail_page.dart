// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/send_money/presentation/widgets/info_row.dart';
import 'package:payhive/features/statement/presentation/state/statement_detail_state.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';
import 'package:payhive/core/utils/statement_status_mapper.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_detail_view_model.dart';
import 'package:payhive/features/statement/presentation/widgets/build_action_row_widget.dart';
import 'package:payhive/features/statement/presentation/widgets/build_status_header_widget.dart';

class StatementDetailPage extends ConsumerStatefulWidget {
  final String txId;
  final ReceiptEntity? initialReceipt;
  final UndoStatusUi? initialUndoStatus;

  const StatementDetailPage({
    super.key,
    required this.txId,
    this.initialReceipt,
    this.initialUndoStatus,
  });

  @override
  ConsumerState<StatementDetailPage> createState() =>
      _StatementDetailPageState();
}

class _StatementDetailPageState extends ConsumerState<StatementDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(statementDetailViewModelProvider.notifier)
          .load(
            txId: widget.txId,
            fallback: widget.initialReceipt,
            initialUndoStatus: widget.initialUndoStatus,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statementDetailViewModelProvider);
    final viewModel = ref.read(statementDetailViewModelProvider.notifier);
    final receipt = state.receipt;
    final undoStatus = state.undoStatus;
    final statusUi = mapStatementStatus(receipt?.status);

    ref.listen<StatementDetailState>(statementDetailViewModelProvider, (
      prev,
      next,
    ) {
      if (prev?.errorMessage == next.errorMessage) return;
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      SnackbarUtil.showError(context, message);
      viewModel.clearError();
    });

    if (state.status == StatementDetailViewStatus.loading && receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == StatementDetailViewStatus.error && receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 46),
                const SizedBox(height: 12),
                const Text('Unable to load transaction details.'),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    viewModel.load(
                      txId: widget.txId,
                      fallback: widget.initialReceipt,
                      initialUndoStatus: widget.initialUndoStatus,
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: const Center(child: Text('No transaction details available.')),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ?? colorScheme.surface;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final contentMaxWidth = isTablet ? 820.0 : 600.0;

    final dateText = DateFormat(
      'dd MMMM yyyy hh:mm a',
    ).format(receipt.createdAt.toLocal());
    final remarks = (receipt.remark ?? '').trim();
    final meta = receipt.meta;
    final baseAmount = _readMetaDouble(meta, const ['amount', 'baseAmount']);
    final feeAmount = _readMetaDouble(meta, const ['fee']);
    final totalDebited = _readMetaDouble(meta, const ['totalDebited']);
    final hasFeeBreakdown =
        baseAmount != null || feeAmount != null || totalDebited != null;
    final displayAmount = baseAmount ?? receipt.amount;
    final displayTotal =
        totalDebited ??
        (feeAmount != null
            ? receipt.amount
            : (baseAmount != null &&
                  (receipt.amount - baseAmount).abs() > 0.009)
            ? receipt.amount
            : null);
    final amountText = _formatAmount(displayAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.status == StatementDetailViewStatus.loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  BuildStatusHeader(context: context, statusUi: statusUi),
                  const SizedBox(height: 20),
                  BuildActionRow(context: context, receipt: receipt),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Column(
                      children: [
                        InfoRow(label: 'Status', value: statusUi.label),
                        if (undoStatus != null)
                          InfoRow(
                            label: 'Undo Status',
                            value: undoStatus.label,
                          ),
                        InfoRow(label: 'From', value: receipt.from.fullName),
                        InfoRow(label: 'To', value: receipt.to.fullName),
                        InfoRow(label: 'Transaction ID', value: receipt.txId),
                        InfoRow(label: 'Date&Time', value: dateText),
                        InfoRow(label: 'Amount(NPR)', value: amountText),
                        if (hasFeeBreakdown && feeAmount != null)
                          InfoRow(
                            label: 'Fee(NPR)',
                            value: _formatAmount(feeAmount),
                          ),
                        if (hasFeeBreakdown && displayTotal != null)
                          InfoRow(
                            label: 'Total Debited(NPR)',
                            value: _formatAmount(displayTotal),
                          ),
                        InfoRow(
                          label: 'Remarks',
                          value: remarks.isNotEmpty ? remarks : '--',
                        ),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receiver Payhive Id:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    receipt.to.phoneNumber.isNotEmpty
                                        ? receipt.to.phoneNumber
                                        : '--',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sender Payhive Id:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    receipt.from.phoneNumber.isNotEmpty
                                        ? receipt.from.phoneNumber
                                        : '--',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _readMetaDouble(Map<String, dynamic>? meta, List<String> keys) {
    if (meta == null || meta.isEmpty) return null;

    for (final key in keys) {
      final raw = meta[key];
      final parsed = _toNullableDouble(raw);
      if (parsed != null) return parsed;
    }

    final normalizedKeys = keys.map(_normalizeMetaKey).toSet();
    for (final entry in meta.entries) {
      if (!normalizedKeys.contains(_normalizeMetaKey(entry.key))) {
        continue;
      }
      final parsed = _toNullableDouble(entry.value);
      if (parsed != null) return parsed;
    }

    return null;
  }

  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _normalizeMetaKey(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  String _formatAmount(double value) {
    return NumberFormat('#,##0.00').format(value);
  }
}
