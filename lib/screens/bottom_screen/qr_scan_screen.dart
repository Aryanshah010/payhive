import 'package:flutter/material.dart';

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan Qr"),),
      body: Center(child: Text("Welcome to Scan QR screen")));
  }
}
