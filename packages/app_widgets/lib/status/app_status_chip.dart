import 'package:flutter/material.dart';
import 'package:app_models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppStatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  factory AppStatusChip.forOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.awaitingPayment:
        return const AppStatusChip(
          label: 'Awaiting Payment',
          backgroundColor: AppColors.warningLight,
          foregroundColor: AppColors.warning,
          icon: Icons.hourglass_top_rounded,
        );
      case OrderStatus.placed:
        return const AppStatusChip(
          label: 'Placed',
          backgroundColor: AppColors.infoLight,
          foregroundColor: AppColors.info,
          icon: Icons.receipt_long_rounded,
        );
      case OrderStatus.accepted:
        return const AppStatusChip(
          label: 'Accepted',
          backgroundColor: AppColors.infoLight,
          foregroundColor: AppColors.info,
          icon: Icons.check_circle_outline_rounded,
        );
      case OrderStatus.preparing:
        return const AppStatusChip(
          label: 'Preparing',
          backgroundColor: AppColors.warningLight,
          foregroundColor: AppColors.warning,
          icon: Icons.restaurant_rounded,
        );
      case OrderStatus.ready:
        return const AppStatusChip(
          label: 'Ready',
          backgroundColor: AppColors.successLight,
          foregroundColor: AppColors.success,
          icon: Icons.done_all_rounded,
        );
      case OrderStatus.served:
        return const AppStatusChip(
          label: 'Served',
          backgroundColor: AppColors.successLight,
          foregroundColor: AppColors.success,
          icon: Icons.dinner_dining_rounded,
        );
      case OrderStatus.completed:
        return const AppStatusChip(
          label: 'Completed',
          backgroundColor: AppColors.successLight,
          foregroundColor: AppColors.success,
          icon: Icons.task_alt_rounded,
        );
      case OrderStatus.cancelled:
        return const AppStatusChip(
          label: 'Cancelled',
          backgroundColor: AppColors.dangerLight,
          foregroundColor: AppColors.danger,
          icon: Icons.cancel_outlined,
        );
    }
  }

  factory AppStatusChip.forPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const AppStatusChip(
          label: 'Paid',
          backgroundColor: AppColors.successLight,
          foregroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case PaymentStatus.pending:
      case PaymentStatus.authorized:
        return const AppStatusChip(
          label: 'Payment Pending',
          backgroundColor: AppColors.warningLight,
          foregroundColor: AppColors.warning,
          icon: Icons.schedule_rounded,
        );
      case PaymentStatus.failed:
        return const AppStatusChip(
          label: 'Payment Failed',
          backgroundColor: AppColors.dangerLight,
          foregroundColor: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
      case PaymentStatus.cancelled:
        return const AppStatusChip(
          label: 'Payment Cancelled',
          backgroundColor: AppColors.dangerLight,
          foregroundColor: AppColors.danger,
          icon: Icons.cancel_outlined,
        );
      case PaymentStatus.partiallyRefunded:
        return const AppStatusChip(
          label: 'Partially Refunded',
          backgroundColor: AppColors.infoLight,
          foregroundColor: AppColors.info,
          icon: Icons.replay_rounded,
        );
      case PaymentStatus.refunded:
        return const AppStatusChip(
          label: 'Refunded',
          backgroundColor: AppColors.infoLight,
          foregroundColor: AppColors.info,
          icon: Icons.replay_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pillBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14.0, color: foregroundColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
