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

Future<Uint8List> buildPdfBytes(ReceiptEntity receipt) async {
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

Future<File> _writeTempPdf(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<void> sharePdf(BuildContext context, ReceiptEntity receipt) async {
  final bytes = await buildPdfBytes(receipt);
  final file = await _writeTempPdf(bytes, 'receipt_${receipt.txId}.pdf');
  await Share.shareXFiles([XFile(file.path)], text: 'Payment receipt');
}