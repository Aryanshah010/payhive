import 'dart:io';
import 'package:flutter/services.dart';

class PdfDownloader {
  static const MethodChannel _channel = MethodChannel(
    'com.aryan.payhive/saveToDownloads',
  );

  static Future<String?> saveToDownloads({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Android only');
    }

    if (!filename.toLowerCase().endsWith('.pdf')) {
      filename = '$filename.pdf';
    }

    return await _channel.invokeMethod<String>('saveToDownloads', {
      'bytes': bytes,
      'filename': filename,
    });
  }
}
