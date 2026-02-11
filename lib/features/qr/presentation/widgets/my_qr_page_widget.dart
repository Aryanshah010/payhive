import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BuildMyQrPage extends StatelessWidget {
  const BuildMyQrPage({
    super.key,
    required this.context,
    required this.userName,
    required this.payHiveId,
    required this.scannedQrData,
  });

  final BuildContext context;
  final String userName;
  final String payHiveId;
  final String? scannedQrData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "PayHive ID: $payHiveId",
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.12),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: "payhive://user?id=$payHiveId",
                  size: 220,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Scan to receive money", textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
