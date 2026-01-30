import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:payhive/features/dashboard/presentation/widgets/scanner_overlay_painter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  late final MobileScannerController _scannerController;

  bool _cameraGranted = false;
  bool _permissionChecked = false;
  bool _isProcessing = false;
  bool _galleryDenied = false;
  int _currentPage = 0;

  String? scannedQrData;

  final String userName = "Aryan Shah";
  final String payHiveId = "9876543210";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(facing: CameraFacing.back);
    _pageController.addListener(_onPageChangedInternal);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.removeListener(_onPageChangedInternal);
    _pageController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCameraPermission();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _onPageChangedInternal() {
    final page = (_pageController.hasClients)
        ? _pageController.page?.round() ?? 0
        : 0;
    if (page != _currentPage) {
      _currentPage = page;
      _updateScannerState();
    }
  }

  Future<void> _checkCameraPermission() async {
    _permissionChecked = false;
    setState(() {});

    final status = await Permission.camera.status;

    if (status.isGranted) {
      _cameraGranted = true;
    } else {
      final result = await Permission.camera.request();
      _cameraGranted = result.isGranted;
    }

    _permissionChecked = true;
    setState(() {});

    _updateScannerState();
  }

  void _updateScannerState() {
    if (_currentPage == 0 && _cameraGranted) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  void _handleQrResult(String value) {
    if (_isProcessing) return;
    _isProcessing = true;

    scannedQrData = value;
    SnackbarUtil.showSuccess(context, "Valid QR detected");

    Future.delayed(const Duration(seconds: 1), () {
      _isProcessing = false;
    });
  }

  Future<void> _pickAndScanImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    try {
      final String? data = await QrCodeToolsPlugin.decodeFrom(file.path);

      if (data == null || data.isEmpty) throw Exception("Invalid QR");

      scannedQrData = data;
      if (mounted) {
        SnackbarUtil.showSuccess(context, "Valid QR detected from gallery");
      }
    } catch (_) {
      if (mounted) {
        SnackbarUtil.showError(context, "No valid QR found in selected image");
      }
    }
  }

  Future<void> _scanFromGallery() async {
    if (_galleryDenied) return;

    final permission = Platform.isIOS ? Permission.photos : Permission.photos;
    final status = await permission.status;

    if (status.isGranted || status.isLimited) {
      await _pickAndScanImage();
      return;
    }

    if (status.isDenied) {
      final result = await permission.request();

      if (result.isGranted || result.isLimited) {
        await _pickAndScanImage();
        return;
      }

      _galleryDenied = true;
      if (mounted) {
        SnackbarUtil.showError(
          context,
          "Gallery access denied. Returning to home.",
        );
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _galleryDenied = true;
        SnackbarUtil.showError(
          context,
          "Gallery permission permanently denied. Enable it from settings.",
        );
        await Future.delayed(const Duration(milliseconds: 2000));
        await openAppSettings();
      }
    }
  }

  Widget _buildScannerPage() {
    if (!_permissionChecked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_cameraGranted) {
      return _buildPermissionDeniedUI();
    }

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

        // Top button
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: _galleryDenied ? null : _scanFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text("Scan QR from gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundDark.withOpacity(0.45),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom hint
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Swipe left to view My QR",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Camera permission is required to scan QR codes.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkCameraPermission,
              child: const Text("Try Again"),
            ),
            TextButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyQrPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                userName.isNotEmpty ? userName[0] : '',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: QrImageView(
                data: "payhive://user?id=$payHiveId",
                size: 220,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ask others to scan this QR to send you money",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (scannedQrData != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                "Last scanned (temp):",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(scannedQrData!),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: PageView(
        controller: _pageController,
        children: [_buildScannerPage(), _buildMyQrPage()],
      ),
    );
  }
}
