import 'package:flutter/material.dart';
import 'package:payhive/app/theme/colors.dart';

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;           
  final Color overlayColor;       
  final Color borderColor;         
  final double borderWidth;        
  final double borderRadius;      

  ScannerOverlayPainter({
    required this.scanWindow,
    this.overlayColor = const Color(0xB2000000), 
    this.borderColor = AppColors.backgroundLight,
    this.borderWidth = 3.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = overlayColor;

    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final innerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          Radius.circular(borderRadius),
        ),
      );

    final combinedPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(combinedPath, overlayPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}