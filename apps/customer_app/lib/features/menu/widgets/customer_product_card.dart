import 'package:flutter/material.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';

class CustomerProductCard extends StatelessWidget {
  final ProductModel product;
  final String currencyCode;
  final VoidCallback onTap;

  const CustomerProductCard({
    super.key,
    required this.product,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = !product.isAvailable;

    return Opacity(
      opacity: isSoldOut ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mediumBorderRadius,
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSoldOut ? null : onTap,
          borderRadius: AppRadius.mediumBorderRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Text & Price details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Veg / Non-veg indicator & Tags
                      Row(
                        children: [
                          if (product.isVeg != null) ...[
                            _VegIndicator(isVeg: product.isVeg!),
                            AppSpacing.gapXs,
                          ],
                          if (product.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
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
                      AppSpacing.gapXs,

                      // Product Name
                      Text(
                        product.name,
                        style: AppTextStyles.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description
                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        AppSpacing.gapXs,
                        Text(
                          product.description!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      AppSpacing.gapSm,

                      // Price & Customization badge
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(
                              product.basePriceMinor,
                              currencyCode: currencyCode,
                            ),
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.modifierGroups.isNotEmpty) ...[
                            AppSpacing.gapSm,
                            Text(
                              'Customizable',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapMd,

                // 2. Product Image or Placeholder + Add/Sold-out CTA
                Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: AppRadius.mediumBorderRadius,
                            image:
                                product.imagePath != null &&
                                    product.imagePath!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(product.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              product.imagePath == null ||
                                  product.imagePath!.isEmpty
                              ? const Icon(
                                  Icons.restaurant_rounded,
                                  color: AppColors.textSecondary,
                                  size: 36,
                                )
                              : null,
                        ),

                        // Sold Out or Add Button Badge
                        if (isSoldOut)
                          Positioned(
                            bottom: -10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.textSecondary,
                                borderRadius: AppRadius.smallBorderRadius,
                              ),
                              child: Text(
                                'SOLD OUT',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            bottom: -12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.mediumBorderRadius,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ADD',
                                    style: AppTextStyles.button.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (product.modifierGroups.isNotEmpty)
                                    const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
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
