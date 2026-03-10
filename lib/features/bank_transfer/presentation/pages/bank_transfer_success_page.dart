// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/utils/pdf_downloader.dart';
import 'package:payhive/core/utils/share_and_pdf_util.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/send_money/presentation/widgets/info_row.dart';

class BankTransferSuccessPage extends StatelessWidget {
  final ReceiptEntity receipt;

  const BankTransferSuccessPage({super.key, required this.receipt});

  static const double tabletBreakpoint = 600;
  static const double wideBreakpoint = 900;
  static const double tabletContentMaxWidth = 820;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= tabletBreakpoint;
    final isPhone = width < tabletBreakpoint;
    final isTabletNarrow = width >= tabletBreakpoint && width < wideBreakpoint;
    final double scale = isPhone ? 1.0 : 1.5;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;

    final paymentType = (receipt.paymentType ?? '').trim().toUpperCase();
    final isBankTransfer =
        paymentType.isEmpty || paymentType == 'BANK_TRANSFER';

    final dateText = DateFormat(
      'dd MMMM yyyy hh:mm a',
    ).format(receipt.createdAt.toLocal());

    final fromName = receipt.from.fullName;
    final toName = receipt.to.fullName;
    final bankName = _resolveBankName(receipt);
    final accountNumber = _resolveAccountNumber(receipt);
    final maskedAccountNumber = _maskAccountNumber(accountNumber);
    final displayToName = isBankTransfer ? (bankName ?? toName) : toName;
    final fromPhone = receipt.from.phoneNumber;
    final toPhone = receipt.to.phoneNumber;
    final txId = receipt.txId;
    final amountText = receipt.amount.toStringAsFixed(2);
    final remarkText = receipt.remark != null && receipt.remark!.isNotEmpty
        ? receipt.remark!
        : '--';

    final double horizontalPadding = isPhone ? 16 : (isTabletNarrow ? 44 : 52);
    final double sectionSpacing = isPhone ? 16 : (isTabletNarrow ? 28 : 32);
    final double successBoxSize = isPhone ? 72 : 96;
    final double successIconSize = isPhone ? 36 : 52;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isPhone ? 600 : tabletContentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sectionSpacing),
                  Center(
                    child: Container(
                      width: successBoxSize,
                      height: successBoxSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: Icon(
                        Icons.check,
                        color: colorScheme.onPrimary,
                        size: successIconSize,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 18 : 12),
                  Center(
                    child: Text(
                      isBankTransfer
                          ? "Bank Transfer Success!"
                          : "Payment Success!",
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await sharePdf(context, receipt);
                          },
                          icon: Icon(Icons.share, size: isTablet ? 20 : 18),
                          label: Text(
                            "Share",
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await buildPdfBytes(receipt);

                              if (Platform.isAndroid) {
                                await PdfDownloader.saveToDownloads(
                                  bytes: bytes,
                                  filename: 'receipt_${receipt.txId}.pdf',
                                );

                                SnackbarUtil.showInfo(
                                  context,
                                  'Saved to Downloads',
                                );
                              } else if (Platform.isIOS) {
                                await sharePdf(context, receipt);
                              }
                            } catch (e) {
                              SnackbarUtil.showError(
                                context,
                                'Failed to save PDF',
                              );
                            }
                          },

                          icon: Icon(Icons.download, size: isTablet ? 20 : 18),
                          label: Text(
                            "PDF",
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionSpacing),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Column(
                      children: [
                        InfoRow(label: "From", value: fromName),
                        InfoRow(label: "To", value: displayToName),
                        if (isBankTransfer)
                          InfoRow(
                            label: "Transfer Type",
                            value: "Bank Transfer",
                          ),
                        if (isBankTransfer && bankName != null)
                          InfoRow(label: "Bank", value: bankName),
                        if (isBankTransfer && maskedAccountNumber != null)
                          InfoRow(
                            label: "Account No.",
                            value: maskedAccountNumber,
                          ),
                        InfoRow(label: "Transaction ID", value: txId),
                        InfoRow(label: "Date&Time", value: dateText),
                        InfoRow(label: "Amount(NPR)", value: amountText),
                        InfoRow(label: "Remarks", value: remarkText),
                        Divider(height: isTablet ? 28 : 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBankTransfer
                                        ? "Receiver Account:"
                                        : "Receiver Payhive Id:",
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isBankTransfer
                                        ? (maskedAccountNumber ??
                                              (toPhone.isNotEmpty
                                                  ? toPhone
                                                  : "--"))
                                        : (toPhone.isNotEmpty ? toPhone : "--"),
                                    style: TextStyle(
                                      fontSize: 13 * scale,
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
                                    "Sender Payhive Id:",
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fromPhone.isNotEmpty ? fromPhone : "--",
                                    style: TextStyle(
                                      fontSize: 13 * scale,
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
                  SizedBox(height: sectionSpacing),
                  PrimaryButtonWidget(
                    onPressed: () {
                      AppRoutes.popToFirst(context);
                    },
                    text: "DONE",
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _resolveBankName(ReceiptEntity? receipt) {
  if (receipt == null) return null;
  return _readMetaString(receipt.meta, const [
    'bankName',
    'bank',
    'bank_name',
    'bankTitle',
  ]);
}

String? _resolveAccountNumber(ReceiptEntity? receipt) {
  if (receipt == null) return null;
  return _readMetaString(receipt.meta, const [
    'accountNumber',
    'accountNo',
    'account',
    'account_number',
  ]);
}

String? _readMetaString(
  Map<String, dynamic>? meta,
  List<String> candidateKeys,
) {
  if (meta == null || meta.isEmpty) return null;

  for (final key in candidateKeys) {
    final raw = meta[key];
    if (raw == null) continue;
    final value = raw.toString().trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  final normalizedCandidates = candidateKeys
      .map((key) => _normalizeMetaKey(key))
      .toSet();
  for (final entry in meta.entries) {
    if (!normalizedCandidates.contains(_normalizeMetaKey(entry.key))) {
      continue;
    }
    final raw = entry.value;
    if (raw == null) continue;
    final value = raw.toString().trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  return null;
}

String _normalizeMetaKey(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
}

String? _maskAccountNumber(String? accountNumber) {
  if (accountNumber == null || accountNumber.trim().isEmpty) return null;
  final clean = accountNumber.trim();
  if (clean.length <= 4) return clean;
  final hiddenLength = clean.length - 4;
  final hidden = List.filled(hiddenLength, '*').join();
  return '$hidden${clean.substring(clean.length - 4)}';
}
