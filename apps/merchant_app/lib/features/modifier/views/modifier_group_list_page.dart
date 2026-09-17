import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../../../app/routes/admin_routes.dart';
import '../controllers/modifier_controller.dart';

class ModifierGroupListPage extends GetView<ModifierController> {
  const ModifierGroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier Groups', style: AppTextStyles.h2),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.loadModifierGroups,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppButton(
              label: 'Add Group',
              leadingIcon: const Icon(Icons.add, size: 18),
              height: 38,
              width: 140,
              onPressed: () => Get.toNamed(AdminRoutes.modifierNew),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.desktop),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const AppLoadingIndicator(
                message: 'Loading modifier groups...',
              );
            }

            if (controller.errorMessage.isNotEmpty) {
              return AppErrorState(
                message: controller.errorMessage.value,
                onRetry: controller.loadModifierGroups,
              );
            }

            final items = controller.groups;

            if (items.isEmpty) {
              return AppEmptyState(
                icon: Icons.tune,
                title: 'No modifier groups yet',
                message:
                    'Create customization options like sizes, add-ons, or spice levels.',
                actionLabel: 'Add Modifier Group',
                onAction: () => Get.toNamed(AdminRoutes.modifierNew),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
                if (isWide) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          mainAxisExtent: 260,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildGroupCard(context, items[index]),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildGroupCard(context, items[index]),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, AdminModifierGroupModel group) {
    return Card(
      key: ValueKey(group.id),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Name, status chip, menu
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: AppTextStyles.h3.copyWith(
                      decoration: group.isActive
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppStatusChip(
                  label: group.isRequired ? 'Required' : 'Optional',
                  backgroundColor: group.isRequired
                      ? AppColors.warningLight
                      : AppColors.surfaceSecondary,
                  foregroundColor: group.isRequired
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    if (action == 'edit') {
                      Get.toNamed('/modifiers/${group.id}/edit');
                    } else if (action == 'delete') {
                      _confirmDelete(context, group);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: AppSpacing.xs),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Selection rule info
            Text(
              'Select: min ${group.minSelect} • max ${group.maxSelect} (${group.modifiers.length} options)',
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: AppSpacing.md),

            // Options preview
            Expanded(
              child: group.modifiers.isEmpty
                  ? Text(
                      'No options defined',
                      style: AppTextStyles.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : ListView(
                      physics: const ClampingScrollPhysics(),
                      children: group.modifiers.map((m) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: AppTextStyles.body.copyWith(
                                    decoration: m.isAvailable
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                m.priceDeltaMinor > 0
                                    ? '+${CurrencyFormatter.format(m.priceDeltaMinor)}'
                                    : 'Free',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: m.priceDeltaMinor > 0
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            // Footer row: Active toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.isActive ? 'Active' : 'Inactive',
                  style: AppTextStyles.caption.copyWith(
                    color: group.isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                Switch.adaptive(
                  value: group.isActive,
                  activeTrackColor: AppColors.primary,
                  onChanged: (_) => controller.toggleGroupActive(group),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminModifierGroupModel group) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Modifier Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? Products attached to this modifier group will lose this customization.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.danger,
            height: 38,
            width: 100,
            onPressed: () {
              Get.back();
              controller.deleteGroup(group.id);
            },
          ),
        ],
      ),
    );
  }
}
