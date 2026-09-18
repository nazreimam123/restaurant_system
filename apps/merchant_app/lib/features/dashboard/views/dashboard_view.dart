import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Merchant Hub'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.store_mall_directory_outlined),
            tooltip: 'Switch Branch',
            onPressed: controller.switchBranch,
          ),
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Switch Restaurant',
            onPressed: controller.switchRestaurant,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: controller.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidthAdminDesktop,
            ),
            child: ListView(
              padding: AppSpacing.edgeInsetsLg,
              children: [
                // Context Header Banner
                _buildContextHeader(context),

                AppSpacing.gapXl,

                // Operational Quick Action Hub
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width < AppBreakpoints.mobile
                        ? 1
                        : width < AppBreakpoints.tablet
                        ? 2
                        : 3;

                    final List<Widget> actionCards = [];

                    // Menu & Catalog Actions (Owner / Manager)
                    if (controller.canManageMenu) {
                      actionCards.add(
                        _buildNavCard(
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          subtitle: 'Organize your menu structure and sections',
                          onTap: controller.goToCategories,
                        ),
                      );
                      actionCards.add(
                        _buildNavCard(
                          icon: Icons.fastfood_outlined,
                          title: 'Products',
                          subtitle: 'Manage items, pricing, and availability',
                          onTap: controller.goToProducts,
                        ),
                      );
                      actionCards.add(
                        _buildNavCard(
                          icon: Icons.tune_rounded,
                          title: 'Modifier Groups',
                          subtitle: 'Configure add-ons, options, and choices',
                          onTap: controller.goToModifiers,
                        ),
                      );
                    }

                    // Tables & QR Codes (Owner / Manager / Waiter)
                    if (controller.canManageTables) {
                      actionCards.add(
                        _buildNavCard(
                          icon: Icons.qr_code_2_rounded,
                          title: 'Dining Tables & QR',
                          subtitle:
                              'Manage tables and rotate secure ordering QR codes',
                          onTap: controller.goToTables,
                        ),
                      );
                    }

                    // Live Orders (Cashier / Waiter / Owner / Manager)
                    if (controller.canViewOrders) {
                      actionCards.add(
                        _buildNavCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Live Orders',
                          subtitle: 'View and track incoming customer orders',
                          onTap: controller.goToOrders,
                        ),
                      );
                    }

                    // KDS (Kitchen / Owner / Manager)
                    if (controller.canViewKds) {
                      actionCards.add(
                        _buildNavCard(
                          icon: Icons.soup_kitchen_rounded,
                          title: 'Kitchen Display (KDS)',
                          subtitle: 'Realtime kitchen preparation screen',
                          onTap: controller.goToKds,
                        ),
                      );
                    }

                    if (crossAxisCount == 1) {
                      return Column(
                        children: actionCards
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: c,
                              ),
                            )
                            .toList(),
                      );
                    }

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 2.2,
                      children: actionCards,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextHeader(BuildContext context) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.largeBorderRadius,
        side: BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: AppSpacing.edgeInsetsLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.restaurantName, style: AppTextStyles.h2),
                      AppSpacing.gapXs,
                      Row(
                        children: [
                          const Icon(
                            Icons.store_outlined,
                            size: 16.0,
                            color: AppColors.textSecondary,
                          ),
                          AppSpacing.gapXs,
                          Text(
                            controller.branchName,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(controller.role),
              ],
            ),
            AppSpacing.gapMd,
            const Divider(height: 1.0, color: AppColors.border),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.storefront_outlined, size: 18.0),
                  label: const Text('Switch Restaurant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mediumBorderRadius,
                    ),
                  ),
                  onPressed: controller.switchRestaurant,
                ),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 18.0,
                  ),
                  label: const Text('Switch Branch'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mediumBorderRadius,
                    ),
                  ),
                  onPressed: controller.switchBranch,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(StaffRole role) {
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

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.largeBorderRadius,
        side: BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.largeBorderRadius,
        child: Padding(
          padding: AppSpacing.edgeInsetsLg,
          child: Row(
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mediumBorderRadius,
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 24.0),
              ),
              AppSpacing.gapLg,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.title),
                    AppSpacing.gapXs,
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
