import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';

class QRScannerScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Function(String) onCodeScanned;

  const QRScannerScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.onCodeScanned,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController _controller;
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (_isScanned) return;

    final barcode = barcodeCapture.barcodes.first;
    final code = barcode.rawValue;

    if (code != null) {
      setState(() => _isScanned = true);

      // Vibrate on scan
      // HapticFeedback.mediumImpact();

      widget.onCodeScanned(code);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backdrop,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTypography.h2Style.copyWith(color: AppColors.surface),
        ),
        backgroundColor: AppColors.backdrop,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppColors.surface),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: AppSpacing.lgAll,
              color: AppColors.backdrop,
              child: Column(
                children: [
                  if (widget.subtitle != null) ...[
                    Text(
                      widget.subtitle!,
                      style: AppTypography.bodyLargeStyle.copyWith(
                        color: AppColors.surface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.md),
                  ],
                  Text(
                    'Position the QR code within the frame to scan',
                    style: AppTypography.bodySmallStyle.copyWith(
                      color: AppColors.surface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Scanner
            Expanded(
              child: Stack(
                children: [
                  // Camera view
                  MobileScanner(controller: _controller, onDetect: _onDetect),

                  // Overlay with scanning frame
                  CustomPaint(
                    painter: ScannerOverlayPainter(),
                    child: Container(),
                  ),

                  // Scanning indicator
                  if (!_isScanned)
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.accentBlue,
                            width: 2,
                          ),
                          borderRadius: AppRadius.lgRadius,
                        ),
                        child: Stack(
                          children: [
                            // Corner indicators
                            Positioned(
                              top: 0,
                              left: 0,
                              child: _buildCornerIndicator(topLeft: true),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: _buildCornerIndicator(topRight: true),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: _buildCornerIndicator(bottomLeft: true),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: _buildCornerIndicator(bottomRight: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom instructions
            Container(
              width: double.infinity,
              padding: AppSpacing.lgAll,
              color: AppColors.backdrop,
              child: Column(
                children: [
                  Text(
                    'Ensure the QR code is well-lit and clear',
                    style: AppTypography.bodySmallStyle.copyWith(
                      color: AppColors.surface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => _controller.switchCamera(),
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: AppColors.surface,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.surface,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicator({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight
              ? BorderSide(color: AppColors.accentBlue, width: 3)
              : BorderSide.none,
          bottom: bottomLeft || bottomRight
              ? BorderSide(color: AppColors.accentBlue, width: 3)
              : BorderSide.none,
          left: topLeft || bottomLeft
              ? BorderSide(color: AppColors.accentBlue, width: 3)
              : BorderSide.none,
          right: topRight || bottomRight
              ? BorderSide(color: AppColors.accentBlue, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.backdrop.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final scanAreaSize = 250.0;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;
    final scanAreaRect = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize,
    );

    // Draw overlay with hole for scan area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(scanAreaRect, Radius.circular(AppRadius.lg)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
