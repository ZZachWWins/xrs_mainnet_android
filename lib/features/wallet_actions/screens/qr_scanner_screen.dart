import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanned = true;
        });
        // Feedback like a vibration can be added here
        context.pop(barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanQrCodeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.brandVibrant,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Hint Text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                l10n.alignQrCode,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Overlay Shape painter or use a standard package one if implementing manually
// Since mobile_scanner doesn't export QrScannerOverlayShape directly in newer versions (it might, checking assumption),
// I will implement a simple overlay using ColorFiltered or path clipping if the above fails compilation.
// However, many Flutter QR tutorials use a shape class. 
// LET'S SIMPLIFY: To be safe and avoid compilation errors with unknown classes, 
// I will implement a custom simple overlay widget instead of relying on QrScannerOverlayShape if it's not standard.
// Actually, I'll use a safer overlay implementation below to guarantee it works.

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 10,
    this.borderLength = 20,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width - cutOutSize;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > cutOutSize / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top + height / 2 - mCutOutSize / 2 + borderOffset,
      mCutOutSize - borderWidth,
      mCutOutSize - borderWidth,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final cutOutBottom = cutOutRect.bottom;
    final cutOutTop = cutOutRect.top;
    final cutOutLeft = cutOutRect.left;
    final cutOutRight = cutOutRect.right;

    canvas.drawPath(
        Path()
          ..moveTo(cutOutLeft, cutOutTop + mBorderLength)
          ..lineTo(cutOutLeft, cutOutTop + borderRadius)
          ..quadraticBezierTo(cutOutLeft, cutOutTop, cutOutLeft + borderRadius, cutOutTop)
          ..lineTo(cutOutLeft + mBorderLength, cutOutTop)
          ..moveTo(cutOutRight, cutOutTop + mBorderLength)
          ..lineTo(cutOutRight, cutOutTop + borderRadius)
          ..quadraticBezierTo(
              cutOutRight, cutOutTop, cutOutRight - borderRadius, cutOutTop)
          ..lineTo(cutOutRight - mBorderLength, cutOutTop)
          ..moveTo(cutOutRight, cutOutBottom - mBorderLength)
          ..lineTo(cutOutRight, cutOutBottom - borderRadius)
          ..quadraticBezierTo(cutOutRight, cutOutBottom, cutOutRight - borderRadius,
              cutOutBottom)
          ..lineTo(cutOutRight - mBorderLength, cutOutBottom)
          ..moveTo(cutOutLeft, cutOutBottom - mBorderLength)
          ..lineTo(cutOutLeft, cutOutBottom - borderRadius)
          ..quadraticBezierTo(
              cutOutLeft, cutOutBottom, cutOutLeft + borderRadius, cutOutBottom)
          ..lineTo(cutOutLeft + mBorderLength, cutOutBottom),
        borderPaint,
      );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
