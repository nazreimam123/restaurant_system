import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../../../app/routes/admin_routes.dart';
import '../controllers/category_controller.dart';

class CategoryListPage extends GetView<CategoryController> {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu Categories', style: AppTextStyles.h2),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.loadCategories,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppButton(
              label: 'Add Category',
              leadingIcon: const Icon(Icons.add, size: 18),
              height: 38,
              width: 150,
              onPressed: () => Get.toNamed(AdminRoutes.categoryNew),
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
                message: 'Loading categories...',
              );
            }

            if (controller.errorMessage.isNotEmpty) {
              return AppErrorState(
                message: controller.errorMessage.value,
                onRetry: controller.loadCategories,
              );
            }

            final items = controller.filteredCategories;

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: controller.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  controller.searchQuery.value = '',
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    onChanged: (val) => controller.searchQuery.value = val,
                  ),
                ),

                if (items.isEmpty)
                  Expanded(
                    child: AppEmptyState(
                      icon: Icons.category_outlined,
                      title: 'No categories found',
                      message: controller.categories.isEmpty
                          ? 'Create your first menu category to organize products.'
                          : 'No categories match your search term.',
                      actionLabel: controller.categories.isEmpty
                          ? 'Add Category'
                          : null,
                      onAction: controller.categories.isEmpty
                          ? () => Get.toNamed(AdminRoutes.categoryNew)
                          : null,
                    ),
                  )
                else
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: items.length,
                      onReorder: controller.onReorder,
                      itemBuilder: (context, index) {
                        final category = items[index];
                        return _buildCategoryTile(context, category);
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

  Widget _buildCategoryTile(BuildContext context, AdminCategoryModel category) {
    return Card(
      key: ValueKey(category.id),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: category.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceSecondary,
          child: Icon(
            Icons.category_outlined,
            color: category.isActive
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: category.isActive
                      ? null
                      : TextDecoration.lineThrough,
                ),
              ),
            ),
            AppStatusChip(
              label: category.isActive ? 'Active' : 'Inactive',
              backgroundColor: category.isActive
                  ? AppColors.successLight
                  : AppColors.surfaceSecondary,
              foregroundColor: category.isActive
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ],
        ),
        subtitle:
            category.description != null && category.description!.isNotEmpty
            ? Text(
                category.description!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: category.isActive,
              activeTrackColor: AppColors.primary,
              onChanged: (_) => controller.toggleActive(category),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == 'edit') {
                  Get.toNamed('/categories/${category.id}/edit');
                } else if (action == 'delete') {
                  _confirmDelete(context, category);
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
                      Text('Delete', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminCategoryModel category) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? Products linked to this category may prevent deletion.',
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
              controller.deleteCategory(category.id);
            },
          ),
        ],
      ),
    );
  }
}
