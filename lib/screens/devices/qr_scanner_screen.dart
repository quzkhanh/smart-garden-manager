import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isApproved = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || _isApproved) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final scannedValue = barcode.rawValue!;

    // Validate: must be a Smart Garden QR session ID (starts with "sg-")
    if (!scannedValue.startsWith('sg-')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('qr_invalid')),
            backgroundColor: AppColors.alertHigh,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Stop scanning
    _scannerController.stop();

    try {
      // Check if the session exists and is pending
      final doc = await FirebaseFirestore.instance
          .collection('qr_sessions')
          .doc(scannedValue)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        _showError(AppLocalizations.of(context).t('qr_session_not_found'));
        return;
      }

      final status = doc.data()?['status'];
      if (status != 'pending') {
        _showError(AppLocalizations.of(context).t('qr_session_expired'));
        return;
      }

      // Approve the session!
      final currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('qr_sessions')
          .doc(scannedValue)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUser?.uid,
      });

      if (mounted) {
        setState(() {
          _isApproved = true;
          _isProcessing = false;
        });

        // Wait a moment to show success, then pop
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerController.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.alertHigh,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Dark overlay with scan window cutout
          _ScanOverlay(isApproved: _isApproved, isProcessing: _isProcessing),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.t('scan_qr_login'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Flash toggle
                    IconButton(
                      onPressed: () => _scannerController.toggleTorch(),
                      icon: ValueListenableBuilder(
                        valueListenable: _scannerController,
                        builder: (_, state, child) {
                          return Icon(
                            state.torchState == TorchState.on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                          );
                        },
                      ),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: _isApproved
                    ? _buildSuccessContent(theme, l10n)
                    : _isProcessing
                        ? _buildProcessingContent(theme, l10n)
                        : _buildInstructionContent(theme, l10n),
              ).animate().fadeIn(duration: 400.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionContent(ThemeData theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.qr_code_scanner_rounded,
          size: 36,
          color: AppColors.primaryGreen,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.t('scan_qr_instruction'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.t('scan_qr_description'),
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProcessingContent(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          l10n.t('approving_login'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(ThemeData theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 40,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.t('login_approved'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.t('login_approved_desc'),
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
  }
}

/// Custom painter for the scan window overlay
class _ScanOverlay extends StatelessWidget {
  final bool isApproved;
  final bool isProcessing;

  const _ScanOverlay({required this.isApproved, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanOverlayPainter(
        borderColor: isApproved
            ? AppColors.primaryGreen
            : isProcessing
                ? Colors.amber
                : Colors.white,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Color borderColor;

  _ScanOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = size.width * 0.65;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2 - 40;
    final scanRect =
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Corner lines
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(20));

    // Top-left
    canvas.drawLine(
      Offset(rrect.left, rrect.top + cornerLength),
      Offset(rrect.left, rrect.top + 10),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rrect.left, rrect.top, 20, 20),
      3.14159,
      1.5708,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rrect.left + 10, rrect.top),
      Offset(rrect.left + cornerLength, rrect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rrect.right - cornerLength, rrect.top),
      Offset(rrect.right - 10, rrect.top),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rrect.right - 20, rrect.top, 20, 20),
      -1.5708,
      1.5708,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rrect.right, rrect.top + 10),
      Offset(rrect.right, rrect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rrect.left, rrect.bottom - cornerLength),
      Offset(rrect.left, rrect.bottom - 10),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rrect.left, rrect.bottom - 20, 20, 20),
      1.5708,
      1.5708,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rrect.left + 10, rrect.bottom),
      Offset(rrect.left + cornerLength, rrect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rrect.right - cornerLength, rrect.bottom),
      Offset(rrect.right - 10, rrect.bottom),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rrect.right - 20, rrect.bottom - 20, 20, 20),
      0,
      1.5708,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rrect.right, rrect.bottom - 10),
      Offset(rrect.right, rrect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      borderColor != oldDelegate.borderColor;
}
