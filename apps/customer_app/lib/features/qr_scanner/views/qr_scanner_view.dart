import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/qr_scanner_controller.dart';

class QrScannerView extends GetView<QrScannerController> {
  const QrScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan Table QR'),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.torchEnabled.value
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: controller.torchEnabled.value
                    ? AppColors.primary
                    : Colors.white,
              ),
              tooltip: 'Toggle Flashlight',
              onPressed: controller.toggleTorch,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mobile Camera Viewport
          Positioned.fill(
            child: MobileScanner(
              controller: controller.scannerController,
              onDetect: controller.onDetect,
            ),
          ),

          // 2. Translucent Cutout Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                cutoutSize: 260.0,
                borderRadius: AppRadius.large,
              ),
            ),
          ),

          // 3. Instruction & Action Controls
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xxl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error card
                Obx(() {
                  final err = controller.errorMessage.value;
                  if (err == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.92),
                      borderRadius: AppRadius.mediumBorderRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: Text(
                            err,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: controller.clearError,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  );
                }),

                // Instruction helper pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: AppRadius.pillBorderRadius,
                  ),
                  child: Text(
                    'Point your camera at the QR code on your table',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                AppSpacing.gapLg,

                // Manual Input Button
                AppButton(
                  label: 'Enter Code Manually',
                  variant: AppButtonVariant.outline,
                  leadingIcon: const Icon(
                    Icons.keyboard_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _showManualEntrySheet(context),
                ),
              ],
            ),
          ),

          // 4. Loading Overlay
          Obx(() {
            if (!controller.isResolving.value) {
              return const SizedBox.shrink();
            }
            return Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    AppSpacing.gapLg,
                    Text(
                      'Resolving table QR...',
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showManualEntrySheet(BuildContext context) {
    controller.clearError();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.pillBorderRadius,
                ),
              ),
            ),
            AppSpacing.gapMd,
            const Text('Enter Table QR / Token', style: AppTextStyles.h3),
            AppSpacing.gapXs,
            Text(
              'Paste the table URL (e.g. https://order.example.com/q/<token>) or the UUID token.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapMd,
            TextField(
              controller: controller.manualInputController,
              decoration: const InputDecoration(
                hintText: 'e.g. 550e8400-e29b-41d4-a716-446655440000',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mediumBorderRadius,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              autofocus: true,
            ),
            AppSpacing.gapLg,
            AppButton(
              label: 'Resolve Table',
              onPressed: controller.submitManualInput,
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double cutoutSize;
  final double borderRadius;

  _ScannerOverlayPainter({
    required this.cutoutSize,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: cutoutSize,
      height: cutoutSize,
    );
    final rrect = RRect.fromRectAndRadius(
      cutoutRect,
      Radius.circular(borderRadius),
    );

    // Draw dark background with cutout path
    final path = Path()
      ..addRect(rect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Draw primary colored viewfinder frame
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutoutSize != cutoutSize ||
        oldDelegate.borderRadius != borderRadius;
  }
}
