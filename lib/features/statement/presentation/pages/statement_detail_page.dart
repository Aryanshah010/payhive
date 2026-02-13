// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:payhive/core/utils/pdf_downloader.dart';
import 'package:payhive/core/utils/share_and_pdf_util.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/send_money/presentation/widgets/info_row.dart';
import 'package:payhive/features/statement/presentation/state/statement_detail_state.dart';
import 'package:payhive/core/utils/statement_status_mapper.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_detail_view_model.dart';

class StatementDetailPage extends ConsumerStatefulWidget {
  final String txId;
  final ReceiptEntity? initialReceipt;

  const StatementDetailPage({
    super.key,
    required this.txId,
    this.initialReceipt,
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
          .load(txId: widget.txId, fallback: widget.initialReceipt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statementDetailViewModelProvider);
    final viewModel = ref.read(statementDetailViewModelProvider.notifier);
    final receipt = state.receipt;
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
    final amountText = receipt.amount.toStringAsFixed(2);
    final remarks = (receipt.remark ?? '').trim();

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
                  _buildStatusHeader(context, statusUi),
                  const SizedBox(height: 20),
                  _buildActionRow(context, receipt),
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
                        InfoRow(label: 'From', value: receipt.from.fullName),
                        InfoRow(label: 'To', value: receipt.to.fullName),
                        InfoRow(label: 'Transaction ID', value: receipt.txId),
                        InfoRow(label: 'Date&Time', value: dateText),
                        InfoRow(label: 'Amount(NPR)', value: amountText),
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

  Widget _buildStatusHeader(BuildContext context, StatementStatusUi statusUi) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusBg = statusUi.color.withOpacity(0.16);

    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusBg),
          child: Icon(statusUi.icon, color: statusUi.color, size: 44),
        ),
        const SizedBox(height: 10),
        Text(
          'Transaction Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusUi.color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusUi.icon, color: statusUi.color, size: 16),
              const SizedBox(width: 6),
              Text(
                statusUi.label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, ReceiptEntity receipt) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await sharePdf(context, receipt);
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text(
              'Share',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final bytes = await buildPdfBytes(receipt);

                if (Platform.isAndroid) {
                  await PdfDownloader.saveToDownloads(
                    bytes: bytes,
                    filename: 'statement_${receipt.txId}.pdf',
                  );
                  SnackbarUtil.showInfo(context, 'Saved to Downloads');
                  return;
                }

                if (Platform.isIOS) {
                  await sharePdf(context, receipt);
                  return;
                }

                SnackbarUtil.showWarning(
                  context,
                  'PDF export not supported on this platform',
                );
              } catch (_) {
                SnackbarUtil.showError(context, 'Failed to save PDF');
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text(
              'PDF',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
