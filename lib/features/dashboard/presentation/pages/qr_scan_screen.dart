import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:payhive/features/dashboard/presentation/widgets/scanner_overlay_painter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:payhive/app/theme/colors.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final PageController _pageController = PageController();
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  // Mock user data
  final String userName = "Aryan Shah";
  final String payHiveId = "9876543210";

  @override
  void dispose() {
    _scannerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  void _handleQrResult(String value) async {
    if (_isProcessing) return;
    _isProcessing = true;

    _scannerController.stop();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("QR Detected"),
        content: Text(value),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Proceed with payment flow")),
              );
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );

    _isProcessing = false;
    _scannerController.start();
  }

  Future<void> _scanFromGallery() async {}

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: PageView(
        controller: _pageController,
        children: [
          // -------- Scan QR --------
          FutureBuilder<bool>(
            future: _requestCameraPermission(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data != true) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 64),
                      const SizedBox(height: 12),
                      const Text("Camera permission required"),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: openAppSettings,
                        child: const Text("Open Settings"),
                      ),
                    ],
                  ),
                );
              }

              // ...

              return Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      if (capture.barcodes.isEmpty) return;
                      final value = capture.barcodes.first.rawValue;
                      if (value != null) _handleQrResult(value);
                    },
                  ),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenSize = constraints.biggest;

                      final scanSize = 260.0;
                      final scanWindow = Rect.fromLTWH(
                        (screenSize.width - scanSize) / 2,
                        (screenSize.height - scanSize) / 2 - 40,
                        scanSize,
                        scanSize,
                      );

                      return CustomPaint(
                        size: Size.infinite,
                        painter: ScannerOverlayPainter(
                          scanWindow: scanWindow,
                          overlayColor: Colors.black.withOpacity(0.55),
                          borderColor: AppColors.backgroundLight,
                          borderWidth: 3.0,
                          borderRadius: 16.0,
                        ),
                      );
                    },
                  ),

                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                          ),
                          onPressed: _scanFromGallery,
                        ),
                        const Text(
                          "Scan QR from gallery",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Swipe left to view My QR",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // -------- My QR --------
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      userName.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "PayHive ID: $payHiveId",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greyText.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: "payhive://user?id=$payHiveId",
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ask others to scan this QR to send you money",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
