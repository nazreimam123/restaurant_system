import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/product_detail_controller.dart';

class ProductDetailView extends GetView<ProductDetailController> {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Customize Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: AppLoadingIndicator(message: 'Loading item details...'),
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return Center(
            child: AppErrorState(
              title: 'Item Unavailable',
              message: error,
              retryLabel: 'Back to Menu',
              onRetry: () => Get.back(),
            ),
          );
        }

        final product = controller.product.value;
        if (product == null) {
          return Center(
            child: AppEmptyState(
              icon: Icons.restaurant_rounded,
              title: 'Item Not Found',
              message: 'This menu item could not be found.',
              actionLabel: 'Back to Menu',
              onAction: () => Get.back(),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Product Image / Placeholder
                    _buildProductImage(product),

                    // 2. Product Header Information
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (product.isVeg != null) ...[
                                _VegIndicator(isVeg: product.isVeg!),
                                AppSpacing.gapSm,
                              ],
                              if (product.tags.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: AppRadius.smallBorderRadius,
                                  ),
                                  child: Text(
                                    product.tags.first.toUpperCase(),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          AppSpacing.gapSm,
                          Text(product.name, style: AppTextStyles.h2),
                          if (product.description != null &&
                              product.description!.isNotEmpty) ...[
                            AppSpacing.gapXs,
                            Text(
                              product.description!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          AppSpacing.gapMd,
                          Text(
                            CurrencyFormatter.format(
                              product.basePriceMinor,
                              currencyCode: controller.currencyCode,
                            ),
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppColors.border),

                    // 3. Modifier Groups
                    ...product.modifierGroups.map((group) {
                      return _buildModifierGroup(group);
                    }),

                    // 4. Special Instructions / Notes
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Special Instructions',
                            style: AppTextStyles.title,
                          ),
                          AppSpacing.gapXs,
                          Text(
                            'Optional notes for the kitchen (e.g., less spicy, no onion)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.gapSm,
                          TextField(
                            controller: controller.notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Add instructions...',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.mediumBorderRadius,
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              contentPadding: EdgeInsets.all(AppSpacing.md),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5. Quantity Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity', style: AppTextStyles.title),
                          _buildQuantitySelector(),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // 6. Sticky Bottom Add to Cart CTA Bar
            _buildBottomBar(product),
          ],
        );
      }),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          image: DecorationImage(
            image: NetworkImage(product.imagePath!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      height: 160,
      color: AppColors.surfaceSecondary,
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 64,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildModifierGroup(ModifierGroupModel group) {
    final isSingleSelect = group.maxSelect == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: AppTextStyles.title),
                      AppSpacing.gapXs,
                      Text(
                        _buildGroupInstruction(group),
                        style: AppTextStyles.caption.copyWith(
                          color: group.isRequired
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: group.isRequired
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: group.isRequired
                        ? AppColors.primaryLight
                        : AppColors.surfaceSecondary,
                    borderRadius: AppRadius.smallBorderRadius,
                  ),
                  child: Text(
                    group.isRequired ? 'REQUIRED' : 'OPTIONAL',
                    style: AppTextStyles.caption.copyWith(
                      color: group.isRequired
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Options List
          ...group.modifiers.map((modifier) {
            return Obx(() {
              final isSelected = controller.isModifierSelected(
                group.id,
                modifier.id,
              );
              final isAvailable = modifier.isAvailable;

              return Opacity(
                opacity: isAvailable ? 1.0 : 0.4,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  enabled: isAvailable,
                  onTap: () => controller.toggleModifier(group, modifier),
                  leading: isSingleSelect
                      ? _buildRadioIndicator(isSelected, isAvailable)
                      : Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.smallBorderRadius,
                          ),
                          onChanged: isAvailable
                              ? (_) =>
                                    controller.toggleModifier(group, modifier)
                              : null,
                        ),
                  title: Text(
                    modifier.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    modifier.priceDeltaMinor > 0
                        ? '+${CurrencyFormatter.format(modifier.priceDeltaMinor, currencyCode: controller.currencyCode)}'
                        : 'Free',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: modifier.priceDeltaMinor > 0
                          ? AppColors.textPrimary
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  Widget _buildRadioIndicator(bool isSelected, bool isAvailable) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  String _buildGroupInstruction(ModifierGroupModel group) {
    if (group.minSelect == 1 && group.maxSelect == 1) {
      return 'Select 1 option';
    }
    if (group.minSelect > 0 && group.maxSelect > group.minSelect) {
      return 'Select between ${group.minSelect} and ${group.maxSelect} options';
    }
    if (group.maxSelect > 1) {
      return 'Select up to ${group.maxSelect} options';
    }
    return 'Optional';
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.mediumBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: controller.decrementQuantity,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Obx(
              () => Text(
                '${controller.quantity.value}',
                style: AppTextStyles.title,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: controller.incrementQuantity,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Live Preview Price
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Obx(
                  () => Text(
                    CurrencyFormatter.format(
                      controller.totalPriceMinor,
                      currencyCode: controller.currencyCode,
                    ),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,

            // Add to Cart Button
            Expanded(
              child: Obx(() {
                final isValid = controller.isValid;
                return AppButton(
                  label: product.isAvailable ? 'Add to Cart' : 'Sold Out',
                  onPressed: (product.isAvailable && isValid)
                      ? controller.onAddToCartTapped
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _VegIndicator extends StatelessWidget {
  final bool isVeg;

  const _VegIndicator({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? const Color(0xFF1B8E2D) : const Color(0xFFD32F2F);

    return Container(
      width: 16,
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
