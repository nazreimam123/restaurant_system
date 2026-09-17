import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/product_form_controller.dart';

class ProductFormPage extends GetView<ProductFormController> {
  const ProductFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditMode ? 'Edit Product' : 'New Product',
            style: AppTextStyles.h2,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingData.value) {
          return const AppLoadingIndicator(
            message: 'Loading product details...',
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controller.errorMessage.isNotEmpty) ...[
                      AppErrorState(message: controller.errorMessage.value),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Section 1: Basic Information
                    _buildCard(
                      title: 'Basic Information',
                      children: [
                        // Name
                        TextFormField(
                          controller: controller.nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            hintText: 'e.g. Margherita Pizza, Cold Coffee',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Product name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Category Dropdown
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue:
                                controller.selectedCategoryId.value.isEmpty
                                ? null
                                : controller.selectedCategoryId.value,
                            decoration: InputDecoration(
                              labelText: 'Menu Category *',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.small,
                                ),
                              ),
                            ),
                            items: controller.categories.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedCategoryId.value = val;
                              }
                            },
                            validator: (val) => val == null || val.isEmpty
                                ? 'Please select a category'
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Description
                        TextFormField(
                          controller: controller.descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText:
                                'Ingredients, flavors, preparation notes...',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // SKU
                        TextFormField(
                          controller: controller.skuController,
                          decoration: InputDecoration(
                            labelText: 'SKU / Item Code (Optional)',
                            hintText: 'e.g. PIZ-MAR-01',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Pricing & Preparation
                    _buildCard(
                      title: 'Pricing & Preparation',
                      children: [
                        Row(
                          children: [
                            // Base Price
                            Expanded(
                              child: TextFormField(
                                controller: controller.priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Base Price (₹) *',
                                  hintText: '0.00',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.small,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Price is required';
                                  }
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num < 0) {
                                    return 'Must be valid positive number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),

                            // Prep Time
                            Expanded(
                              child: TextFormField(
                                controller: controller.prepMinutesController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Prep Time (Minutes)',
                                  hintText: 'e.g. 15',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.small,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: Dietary & Visibility
                    _buildCard(
                      title: 'Dietary & Availability',
                      children: [
                        const Text(
                          'Dietary Preference',
                          style: AppTextStyles.captionMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Obx(
                          () => Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Unspecified'),
                                selected: controller.isVeg.value == null,
                                onSelected: (_) =>
                                    controller.isVeg.value = null,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ChoiceChip(
                                label: const Text('Vegetarian'),
                                avatar: const Icon(
                                  Icons.circle,
                                  color: AppColors.success,
                                  size: 14,
                                ),
                                selected: controller.isVeg.value == true,
                                onSelected: (_) =>
                                    controller.isVeg.value = true,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ChoiceChip(
                                label: const Text('Non-Vegetarian'),
                                avatar: const Icon(
                                  Icons.circle,
                                  color: AppColors.danger,
                                  size: 14,
                                ),
                                selected: controller.isVeg.value == false,
                                onSelected: (_) =>
                                    controller.isVeg.value = false,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: AppSpacing.xl),

                        // Available switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'In Stock / Available',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                Text(
                                  'If disabled, item is displayed as "Sold Out".',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Obx(
                              () => Switch.adaptive(
                                value: controller.isAvailable.value,
                                activeTrackColor: AppColors.primary,
                                onChanged: (val) =>
                                    controller.isAvailable.value = val,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Active switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active on Menu',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                Text(
                                  'Archived items are completely hidden from customer view.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Obx(
                              () => Switch.adaptive(
                                value: controller.isActive.value,
                                activeTrackColor: AppColors.primary,
                                onChanged: (val) =>
                                    controller.isActive.value = val,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 4: Image Path
                    _buildCard(
                      title: 'Product Image',
                      children: [
                        TextFormField(
                          controller: controller.imagePathController,
                          decoration: InputDecoration(
                            labelText: 'Storage Path / Image URL',
                            hintText: 'e.g. products/margherita.webp',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 5: Modifier Groups Selection
                    _buildCard(
                      title: 'Modifier Groups',
                      children: [
                        Text(
                          'Attach modifier groups (sizes, add-ons, extras) to allow customer customization for this product.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Obx(() {
                          if (controller.availableModifierGroups.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                'No modifier groups found. Create groups under Modifiers first.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: controller.availableModifierGroups.map((
                              group,
                            ) {
                              final isSelected = controller
                                  .selectedModifierGroupIds
                                  .contains(group.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(group.name),
                                subtitle: Text(
                                  '${group.isRequired ? "Required" : "Optional"} • ${group.modifiers.length} options',
                                  style: AppTextStyles.caption,
                                ),
                                activeColor: AppColors.primary,
                                onChanged: (_) =>
                                    controller.toggleModifierGroup(group.id),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit & Cancel buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.outline,
                          height: 42,
                          width: 110,
                          onPressed: () => Get.back(),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Obx(
                          () => AppButton(
                            label: controller.isEditMode
                                ? 'Save Changes'
                                : 'Create Product',
                            isLoading: controller.isSubmitting.value,
                            height: 42,
                            width: 170,
                            onPressed: controller.isSubmitting.value
                                ? null
                                : controller.submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
