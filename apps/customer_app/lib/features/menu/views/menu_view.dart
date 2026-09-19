import 'package:flutter/material.dart' hide MenuController;
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/menu_controller.dart';
import '../widgets/customer_product_card.dart';

class MenuView extends GetView<MenuController> {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: AppLoadingIndicator(message: 'Loading delicious menu...'),
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return Center(
            child: AppErrorState(
              title: 'Unable to Load Menu',
              message: error,
              onRetry: controller.loadMenu,
            ),
          );
        }

        final currentMenu = controller.menu.value;
        if (currentMenu == null || currentMenu.categories.isEmpty) {
          return Center(
            child: AppEmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'Menu Unavailable',
              message:
                  'This restaurant has no active menu items at the moment.',
              actionLabel: 'Refresh Menu',
              onAction: controller.loadMenu,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadMenu,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Ordering Paused Banner (if applicable)
              if (currentMenu.ordering.isOrderingPaused)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: AppRadius.mediumBorderRadius,
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pause_circle_outline_rounded,
                          color: AppColors.warning,
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: Text(
                            currentMenu.ordering.pauseReason ??
                                'Ordering is temporarily paused by the restaurant.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Search Field
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search dishes, drinks, tags...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: Obx(() {
                        if (controller.searchQuery.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: controller.clearSearch,
                        );
                      }),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.mediumBorderRadius,
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.mediumBorderRadius,
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.mediumBorderRadius,
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Category Horizontal Tab List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    children: [
                      // "All" Category Pill
                      Obx(() {
                        final isSelected =
                            controller.selectedCategoryId.value == null ||
                            controller.selectedCategoryId.value == 'all';
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: const Text('All Dishes'),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: AppTextStyles.button.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.pillBorderRadius,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            showCheckmark: false,
                            onSelected: (_) => controller.selectCategory('all'),
                          ),
                        );
                      }),

                      // Dynamic Categories from API
                      ...currentMenu.categories.map((category) {
                        return Obx(() {
                          final isSelected =
                              controller.selectedCategoryId.value ==
                              category.id;
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: ChoiceChip(
                              label: Text(category.name),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: AppTextStyles.button.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.pillBorderRadius,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              showCheckmark: false,
                              onSelected: (_) =>
                                  controller.selectCategory(category.id),
                            ),
                          );
                        });
                      }),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // 4. Products List
              Obx(() {
                final products = controller.displayedProducts;

                if (products.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No Dishes Found',
                        message: controller.searchQuery.value.isNotEmpty
                            ? 'No menu items match "${controller.searchQuery.value}".'
                            : 'No items in this category.',
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = products[index];
                    return CustomerProductCard(
                      product: product,
                      currencyCode: currentMenu.restaurant.currencyCode,
                      onTap: () => controller.onProductTapped(product),
                    );
                  }, childCount: products.length),
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      titleSpacing: AppSpacing.md,
      title: Obx(() {
        final ctx = controller.contextService.currentContext;
        final menu = controller.menu.value;
        final restName =
            menu?.restaurant.name ?? ctx?.restaurantName ?? 'Restaurant Menu';
        final branchName = menu?.branch.name ?? ctx?.branchName ?? '';
        final tableName = ctx?.tableName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              restName,
              style: AppTextStyles.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                if (branchName.isNotEmpty) ...[
                  Text(
                    branchName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (tableName != null)
                    Text(
                      ' • ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
                if (tableName != null)
                  Text(
                    tableName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded),
          tooltip: 'Switch Table',
          onPressed: controller.changeTable,
        ),
      ],
    );
  }
}
