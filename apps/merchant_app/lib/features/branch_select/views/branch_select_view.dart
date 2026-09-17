import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/branch_select_controller.dart';

class BranchSelectView extends GetView<BranchSelectController> {
  const BranchSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Select Branch')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingIndicator(message: 'Loading branches...');
        }

        if (controller.errorMessage.value != null &&
            controller.branches.isEmpty) {
          return AppErrorState(
            title: 'Unable to load branches',
            message: controller.errorMessage.value!,
            onRetry: controller.loadBranches,
          );
        }

        if (controller.branches.isEmpty) {
          return AppEmptyState(
            icon: Icons.location_off_rounded,
            title: 'No Accessible Branches',
            message:
                'You do not have active access to any branches under ${controller.restaurantName}. Contact your manager.',
            actionLabel: 'Go Back',
            onAction: () => Get.back(),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxFormWidth,
            ),
            child: ListView(
              padding: AppSpacing.edgeInsetsLg,
              children: [
                if (controller.errorMessage.value != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    padding: AppSpacing.edgeInsetsMd,
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: AppRadius.mediumBorderRadius,
                    ),
                    child: Text(
                      controller.errorMessage.value!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                Text(controller.restaurantName, style: AppTextStyles.h3),
                AppSpacing.gapSm,
                Text(
                  'Select the branch you are operating at today.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapLg,
                ...controller.branches.map((branch) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.largeBorderRadius,
                      side: BorderSide(color: AppColors.border, width: 1.0),
                    ),
                    child: Padding(
                      padding: AppSpacing.edgeInsetsLg,
                      child: Row(
                        children: [
                          Container(
                            width: 52.0,
                            height: 52.0,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: AppRadius.mediumBorderRadius,
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primaryDark,
                              size: 28.0,
                            ),
                          ),
                          AppSpacing.gapLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.branchName,
                                  style: AppTextStyles.title,
                                ),
                                AppSpacing.gapXs,
                                Text(
                                  'Active Branch',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapMd,
                          AppButton(
                            label: 'Select',
                            width: 96.0,
                            height: 40.0,
                            onPressed: () => controller.selectBranch(branch),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}
