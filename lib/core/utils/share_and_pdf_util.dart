// add these imports at top of the file
// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';

// --- PDF builder ---
Future<Uint8List> _buildPdfBytes(ReceiptEntity receipt) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Padding(
          padding: pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payment Receipt',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('From: ${receipt.from.fullName}'),
              pw.Text('To: ${receipt.to.fullName}'),
              pw.Text('Transaction ID: ${receipt.txId}'),
              pw.Text(
                'Date: ${DateFormat('dd MMM yyyy hh:mm a').format(receipt.createdAt.toLocal())}',
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.Text(
                'Amount (NPR): ${receipt.amount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Remarks: ${receipt.remark ?? '--'}'),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}

// --- write temporary file (used for sharing) ---
Future<File> _writeTempPdf(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

// --- share as PDF using platform share sheet ---
Future<void> sharePdf(BuildContext context, ReceiptEntity receipt) async {
  final bytes = await _buildPdfBytes(receipt);
  final file = await _writeTempPdf(bytes, 'receipt_${receipt.txId}.pdf');

  // Use share_plus to open the native share dialog
  await Share.shareXFiles([XFile(file.path)], text: 'Payment receipt');
}

// --- save PDF to device (Downloads or app folder) ---
Future<String?> savePdfToDevice(
  BuildContext context,
  ReceiptEntity receipt,
) async {
  final bytes = await _buildPdfBytes(receipt);
  final filename = 'receipt_${receipt.txId}.pdf';

  try {
    // Preferred: let file_saver trigger OS save dialog or save to Downloads on supported platforms:
    await FileSaver.instance.saveFile(name: filename, bytes: bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to device (Downloads or chosen folder).')),
    );
    return filename;
  } catch (e) {
    // fallback: write into app documents folder and inform user of path
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    return file.path;
  }
}
