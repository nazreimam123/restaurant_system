import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/restaurant_select_controller.dart';

class RestaurantSelectView extends GetView<RestaurantSelectController> {
  const RestaurantSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Restaurant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Create Restaurant',
            onPressed: controller.goToCreateRestaurant,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: controller.signOut,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingIndicator(
            message: 'Loading assigned restaurants...',
          );
        }

        if (controller.errorMessage.value != null &&
            controller.memberships.isEmpty) {
          return AppErrorState(
            title: 'Unable to load restaurants',
            message: controller.errorMessage.value!,
            onRetry: controller.loadMemberships,
          );
        }

        if (controller.memberships.isEmpty) {
          if (controller.isAuthenticated) {
            return AppEmptyState(
              icon: Icons.storefront_outlined,
              title: 'No restaurants yet.',
              message:
                  'You are not associated with any restaurant yet. Create your first restaurant to get started.',
              actionLabel: 'Create Restaurant',
              onAction: controller.goToCreateRestaurant,
            );
          } else {
            return AppEmptyState(
              icon: Icons.store_outlined,
              title: 'No Restaurant Access',
              message:
                  'Your account is not assigned to any active restaurant.\nContact your restaurant owner or administrator.',
              actionLabel: 'Sign Out',
              onAction: controller.signOut,
            );
          }
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
                Text('Select Restaurant to Manage', style: AppTextStyles.h3),
                AppSpacing.gapSm,
                Text(
                  'Choose from the restaurants your account has permission to access.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapLg,
                ...controller.memberships.map((membership) {
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
                              Icons.restaurant_rounded,
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
                                  membership.restaurantName,
                                  style: AppTextStyles.title,
                                ),
                                AppSpacing.gapXs,
                                Row(
                                  children: [_buildRoleChip(membership.role)],
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapMd,
                          AppButton(
                            label: 'Select',
                            isLoading: controller.isSelecting.value,
                            width: 96.0,
                            height: 40.0,
                            onPressed: () =>
                                controller.selectRestaurant(membership),
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

  Widget _buildRoleChip(StaffRole role) {
    Color bg = AppColors.infoLight;
    Color fg = AppColors.info;

    switch (role) {
      case StaffRole.owner:
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        break;
      case StaffRole.manager:
        bg = AppColors.infoLight;
        fg = AppColors.info;
        break;
      case StaffRole.cashier:
      case StaffRole.waiter:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
      case StaffRole.kitchen:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
    }

    return AppStatusChip(
      label: role.name.toUpperCase(),
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }
}
