import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../../../app/routes/admin_routes.dart';
import '../controllers/table_controller.dart';

class TableListPage extends GetView<TableController> {
  const TableListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dining Tables & QR', style: AppTextStyles.h2),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.loadTables,
          ),
          TextButton.icon(
            icon: const Icon(Icons.add_business_outlined, size: 18),
            label: const Text('Add Area'),
            onPressed: () => controller.createAreaDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.sm,
              left: AppSpacing.xs,
            ),
            child: AppButton(
              label: 'Add Table',
              leadingIcon: const Icon(Icons.add, size: 18),
              height: 38,
              width: 130,
              onPressed: () => Get.toNamed(AdminRoutes.tableNew),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.desktop),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const AppLoadingIndicator(message: 'Loading tables...');
            }

            if (controller.errorMessage.isNotEmpty) {
              return AppErrorState(
                message: controller.errorMessage.value,
                onRetry: controller.loadTables,
              );
            }

            final items = controller.filteredTables;

            return Column(
              children: [
                // Dining Area Filter Chips
                if (controller.areas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    color: AppColors.surface,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Obx(
                        () => Row(
                          children: [
                            FilterChip(
                              label: const Text('All Areas'),
                              selected: controller.selectedAreaId.value.isEmpty,
                              onSelected: (_) =>
                                  controller.selectedAreaId.value = '',
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            ...controller.areas.map((area) {
                              final isSelected =
                                  controller.selectedAreaId.value == area.id;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: FilterChip(
                                  label: Text(area.name),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      controller.selectedAreaId.value = area.id,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (items.isEmpty)
                  Expanded(
                    child: AppEmptyState(
                      icon: Icons.table_restaurant,
                      title: 'No dining tables found',
                      message: controller.tables.isEmpty
                          ? 'Add tables to generate QR codes for customer self-ordering.'
                          : 'No tables in this dining area.',
                      actionLabel: controller.tables.isEmpty
                          ? 'Add Table'
                          : null,
                      onAction: controller.tables.isEmpty
                          ? () => Get.toNamed(AdminRoutes.tableNew)
                          : null,
                    ),
                  )
                else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= AppBreakpoints.tablet;
                        if (isWide) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 360,
                                  mainAxisExtent: 220,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) =>
                                _buildTableCard(context, items[index]),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _buildTableCard(context, items[index]),
                        );
                      },
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, DiningTableModel table) {
    return Card(
      key: ValueKey(table.id),
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: table.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceSecondary,
                  child: Icon(
                    Icons.table_restaurant_outlined,
                    color: table.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.name,
                        style: AppTextStyles.h3.copyWith(
                          decoration: table.isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        table.diningAreaName ?? 'General Area',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppStatusChip(
                  label: table.isActive ? 'Active' : 'Inactive',
                  backgroundColor: table.isActive
                      ? AppColors.successLight
                      : AppColors.surfaceSecondary,
                  foregroundColor: table.isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (table.capacity != null)
              Text(
                'Capacity: ${table.capacity} guests',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

            const SizedBox(height: AppSpacing.sm),
            const Divider(height: AppSpacing.sm),

            // Actions row: View QR, Edit, Active switch, Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('View QR'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                  onPressed: () => Get.toNamed('/tables/${table.id}/qr'),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit Table',
                      onPressed: () => Get.toNamed('/tables/${table.id}'),
                    ),
                    Switch.adaptive(
                      value: table.isActive,
                      activeTrackColor: AppColors.primary,
                      onChanged: (_) => controller.toggleTableActive(table),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      tooltip: 'Delete Table',
                      onPressed: () => _confirmDelete(context, table),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DiningTableModel table) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Table'),
        content: Text(
          'Are you sure you want to delete "${table.name}"? Active orders or reservations on this table may prevent deletion.',
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
              controller.deleteTable(table.id);
            },
          ),
        ],
      ),
    );
  }
}
