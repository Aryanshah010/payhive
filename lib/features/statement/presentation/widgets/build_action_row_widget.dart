// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/core/utils/pdf_downloader.dart';
import 'package:payhive/core/utils/share_and_pdf_util.dart';
import 'package:payhive/core/utils/snackbar_util.dart';

class BuildActionRow extends StatelessWidget {
  const BuildActionRow({
    super.key,
    required this.context,
    required this.receipt,
  });

  final BuildContext context;
  final ReceiptEntity receipt;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await sharePdf(context, receipt);
            },
            icon: Icon(Icons.share, size: isTablet ? 20 : 18),
            label: Text(
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
            icon: Icon(Icons.download, size: isTablet ? 20 : 18),
            label: Text(
              'PDF',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
