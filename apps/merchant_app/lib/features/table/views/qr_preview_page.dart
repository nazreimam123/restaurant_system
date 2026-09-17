import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/qr_controller.dart';

class QrPreviewPage extends GetView<QrController> {
  const QrPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Table QR Code', style: AppTextStyles.h2),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingIndicator(message: 'Loading table QR...');
        }

        if (controller.errorMessage.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: () {
              final id = Get.parameters['id'];
              if (id != null) controller.loadTable(id);
            },
          );
        }

        final table = controller.table.value;
        if (table == null) {
          return const AppEmptyState(
            icon: Icons.qr_code,
            title: 'Table not found',
            message: 'Could not load QR code for the requested table.',
          );
        }

        final qrUrl = controller.qrUrl;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // QR Printable Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Restaurant / Brand Header
                          if (controller.restaurantName != null)
                            Text(
                              controller.restaurantName!,
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (controller.branchName != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              controller.branchName!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),

                          // Table Name Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              table.name.toUpperCase(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // QR Image
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: QrImageView(
                              data: qrUrl,
                              version: QrVersions.auto,
                              size: 240.0,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Instruction
                          Text(
                            'Scan to Browse Menu & Order',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'No app download required',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // URL Info Box with Copy action
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            qrUrl,
                            style: AppTextStyles.caption.copyWith(
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy URL',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: qrUrl));
                            Get.snackbar(
                              'Copied',
                              'QR order link copied to clipboard',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Security / QR Rotation Section
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      side: BorderSide(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    color: AppColors.warning.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.security,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'QR Security & Rotation',
                                style: AppTextStyles.captionMedium.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'If a printed QR code is compromised or misplaced, rotate the QR code immediately. This creates a new secret token and invalidates the previous QR URL.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Obx(
                            () => AppButton(
                              label: 'Rotate QR Code',
                              leadingIcon: const Icon(Icons.refresh, size: 18),
                              variant: AppButtonVariant.outline,
                              isLoading: controller.isRotating.value,
                              height: 42,
                              width: 180,
                              onPressed: controller.isRotating.value
                                  ? null
                                  : () => _confirmRotateQr(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _confirmRotateQr(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: AppSpacing.xs),
            Text('Rotate Table QR?'),
          ],
        ),
        content: const Text(
          'Rotating this QR code will permanently invalidate all previously printed QR codes for this table.\n\nCustomers scanning old physical cards or stickers will receive an inactive error.\n\nYou will need to print and display the newly generated QR code.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          AppButton(
            label: 'Rotate QR Code',
            variant: AppButtonVariant.danger,
            height: 38,
            width: 140,
            onPressed: () {
              Get.back();
              controller.rotateQr();
            },
          ),
        ],
      ),
    );
  }
}
