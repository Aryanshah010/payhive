import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:payhive/features/qr/presentation/widgets/my_qr_page_widget.dart';
import 'package:payhive/features/qr/presentation/widgets/scanner_overlay_painter.dart';
import 'package:payhive/features/qr/presentation/widgets/swipe_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/snackbar_util.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  late final MobileScannerController _scannerController;

  bool _cameraGranted = false;
  bool _permissionChecked = false;
  bool _askedCameraRequest = false;
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

    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      autoStart: false,
    );

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
    final page = _pageController.hasClients
        ? _pageController.page?.round() ?? 0
        : 0;

    if (page != _currentPage) {
      _currentPage = page;
      _updateScannerState();
    }
  }

  Future<void> _checkCameraPermission({bool forceRequest = false}) async {
    _permissionChecked = false;
    if (mounted) setState(() {});

    final status = await Permission.camera.status;

    if (status.isGranted) {
      _cameraGranted = true;
    } else if (forceRequest || !_askedCameraRequest) {
      _askedCameraRequest = true;
      final result = await Permission.camera.request();
      _cameraGranted = result.isGranted;
    } else {
      _cameraGranted = false;
    }

    _permissionChecked = true;
    if (mounted) setState(() {});
    _updateScannerState();
  }

  void _updateScannerState() {
    if (!mounted || !_permissionChecked) return;

    try {
      if (_currentPage == 0 && _cameraGranted) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    } catch (_) {}
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

      if (data == null || data.isEmpty) {
        throw Exception("Invalid QR");
      }

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
        SnackbarUtil.showError(context, "Gallery access denied.");
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      _galleryDenied = true;
      if (mounted) {
        SnackbarUtil.showError(
          context,
          "Gallery permission permanently denied. Enable it from settings.",
        );
        await openAppSettings();
      }
    }
  }

  Widget _buildScannerPage() {
    final colorScheme = Theme.of(context).colorScheme;

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
            const scanSize = 260.0;

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
                borderColor: colorScheme.onSurface.withOpacity(0.9),
                borderWidth: 3,
                borderRadius: 16,
              ),
            );
          },
        ),

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

        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SwipeArrowHint(),
                  SizedBox(width: 8),
                  Text(
                    "Swipe left to view your QR",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
            const Icon(Icons.camera_alt_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Camera permission is required to scan QR codes.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkCameraPermission(forceRequest: true),
              child: const Text("Try Again"),
            ),
            TextButton(
              onPressed: openAppSettings,
              child: const Text("Open Settings"),
            ),
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
        children: [
          _buildScannerPage(),
          BuildMyQrPage(
            context: context,
            userName: userName,
            payHiveId: payHiveId,
            scannedQrData: scannedQrData,
          ),
        ],
      ),
    );
  }
}
