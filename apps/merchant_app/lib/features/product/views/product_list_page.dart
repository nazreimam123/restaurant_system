import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../../../app/routes/admin_routes.dart';
import '../controllers/product_controller.dart';

class ProductListPage extends GetView<ProductController> {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Management', style: AppTextStyles.h2),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.reloadProducts,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppButton(
              label: 'Add Product',
              leadingIcon: const Icon(Icons.add, size: 18),
              height: 38,
              width: 145,
              onPressed: () => Get.toNamed(AdminRoutes.productNew),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.desktop),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const AppLoadingIndicator(message: 'Loading products...');
            }

            if (controller.errorMessage.isNotEmpty) {
              return AppErrorState(
                message: controller.errorMessage.value,
                onRetry: controller.loadInitialData,
              );
            }

            final items = controller.filteredProducts;

            return Column(
              children: [
                _buildFilterBar(context),
                if (items.isEmpty)
                  Expanded(
                    child: AppEmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'No products found',
                      message: controller.products.isEmpty
                          ? 'Add menu items so customers can start ordering.'
                          : 'Try adjusting your search or category filter.',
                      actionLabel: controller.products.isEmpty
                          ? 'Add Product'
                          : null,
                      onAction: controller.products.isEmpty
                          ? () => Get.toNamed(AdminRoutes.productNew)
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
                                  maxCrossAxisExtent: 420,
                                  mainAxisExtent: 220,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) =>
                                _buildProductCard(context, items[index]),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _buildProductCard(context, items[index]),
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

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products by name, SKU...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => controller.searchQuery.value = '',
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) => controller.searchQuery.value = val,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Category dropdown filter
              Expanded(
                flex: 2,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: controller.selectedCategoryId.value.isEmpty
                        ? null
                        : controller.selectedCategoryId.value,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...controller.categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) =>
                        controller.selectedCategoryId.value = val ?? '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Veg / Non-veg chip filters
          Obx(
            () => Row(
              children: [
                FilterChip(
                  label: const Text('All Diets'),
                  selected: controller.filterVeg.value == null,
                  onSelected: (_) => controller.filterVeg.value = null,
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: const Text('Veg'),
                  selected: controller.filterVeg.value == true,
                  avatar: const Icon(
                    Icons.circle,
                    color: AppColors.success,
                    size: 14,
                  ),
                  onSelected: (_) => controller.filterVeg.value = true,
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: const Text('Non-Veg'),
                  selected: controller.filterVeg.value == false,
                  avatar: const Icon(
                    Icons.circle,
                    color: AppColors.danger,
                    size: 14,
                  ),
                  onSelected: (_) => controller.filterVeg.value = false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, AdminProductModel product) {
    return Card(
      key: ValueKey(product.id),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.isVeg != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: AppSpacing.xs),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: product.isVeg!
                            ? AppColors.success
                            : AppColors.danger,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: product.isVeg!
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),

                // Name & category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.h3.copyWith(
                          decoration: product.isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.categoryName != null)
                        Text(
                          product.categoryName!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Price
                Text(
                  CurrencyFormatter.format(product.basePriceMinor),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    if (action == 'edit') {
                      Get.toNamed('/products/${product.id}/edit');
                    } else if (action == 'delete') {
                      _confirmDelete(context, product);
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

            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                product.description!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: AppSpacing.sm),
            const Divider(height: AppSpacing.md),

            // Bottom controls: Available toggle & Active toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: Icon(
                    product.isAvailable
                        ? Icons.check_circle_outline
                        : Icons.highlight_off,
                    size: 16,
                    color: product.isAvailable
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  label: Text(
                    product.isAvailable ? 'In Stock' : 'Sold Out',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.isAvailable
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    side: BorderSide(
                      color: product.isAvailable
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  onPressed: () => controller.toggleAvailability(product),
                ),

                // Active toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.isActive ? 'Active' : 'Archived',
                      style: AppTextStyles.caption.copyWith(
                        color: product.isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Switch.adaptive(
                      value: product.isActive,
                      activeTrackColor: AppColors.primary,
                      onChanged: (_) => controller.toggleActive(product),
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

  void _confirmDelete(BuildContext context, AdminProductModel product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
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
              controller.deleteProduct(product.id);
            },
          ),
        ],
      ),
    );
  }
}
