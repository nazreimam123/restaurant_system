import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/modifier_form_controller.dart';

class ModifierGroupFormPage extends GetView<ModifierFormController> {
  const ModifierGroupFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditMode
                ? 'Edit Modifier Group'
                : 'New Modifier Group',
            style: AppTextStyles.h2,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingData.value) {
          return const AppLoadingIndicator(
            message: 'Loading modifier group...',
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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

                    // Group Settings Card
                    Card(
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
                            const Text(
                              'Group Configuration',
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Group Name
                            TextFormField(
                              controller: controller.nameController,
                              decoration: InputDecoration(
                                labelText: 'Group Name *',
                                hintText:
                                    'e.g. Size, Crust, Toppings, Spice Level',
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
                                  return 'Group name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Required switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Required Selection',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    Text(
                                      'Customer must pick at least one option before adding to cart',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Obx(
                                  () => Switch.adaptive(
                                    value: controller.isRequired.value,
                                    activeTrackColor: AppColors.primary,
                                    onChanged: (val) {
                                      controller.isRequired.value = val;
                                      if (val &&
                                          controller.minSelect.value < 1) {
                                        controller.minSelect.value = 1;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: AppSpacing.xl),

                            // Min & Max Select
                            Row(
                              children: [
                                Expanded(
                                  child: Obx(
                                    () => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Min Select',
                                          style: AppTextStyles.captionMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed:
                                                  controller.minSelect.value > 0
                                                  ? () => controller
                                                        .minSelect
                                                        .value--
                                                  : null,
                                            ),
                                            Text(
                                              '${controller.minSelect.value}',
                                              style: AppTextStyles.h3,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              onPressed: () {
                                                controller.minSelect.value++;
                                                if (controller.maxSelect.value <
                                                    controller
                                                        .minSelect
                                                        .value) {
                                                  controller.maxSelect.value =
                                                      controller
                                                          .minSelect
                                                          .value;
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Obx(
                                    () => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Max Select',
                                          style: AppTextStyles.captionMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed:
                                                  controller.maxSelect.value > 1
                                                  ? () => controller
                                                        .maxSelect
                                                        .value--
                                                  : null,
                                            ),
                                            Text(
                                              '${controller.maxSelect.value}',
                                              style: AppTextStyles.h3,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              onPressed: () =>
                                                  controller.maxSelect.value++,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Options List Card
                    Card(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Modifier Options',
                                  style: AppTextStyles.h3,
                                ),
                                AppButton(
                                  label: 'Add Option',
                                  leadingIcon: const Icon(Icons.add, size: 16),
                                  variant: AppButtonVariant.secondary,
                                  height: 36,
                                  width: 130,
                                  onPressed: controller.addOption,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Individual choices available within this group (e.g. Regular, Extra Cheese).',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            Obx(
                              () => Column(
                                children: List.generate(
                                  controller.options.length,
                                  (index) => _buildOptionRow(
                                    context,
                                    controller.options[index],
                                    index,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Actions
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
                                : 'Create Group',
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

  Widget _buildOptionRow(
    BuildContext context,
    ModifierOptionFormItem item,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name field
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: item.nameController,
              decoration: const InputDecoration(
                labelText: 'Option Name *',
                hintText: 'e.g. Extra Cheese',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Price delta field
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: item.priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Price +₹',
                hintText: '0.00',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Available toggle
          Obx(
            () => Tooltip(
              message: item.isAvailable.value ? 'In Stock' : 'Sold Out',
              child: IconButton(
                icon: Icon(
                  item.isAvailable.value
                      ? Icons.check_circle
                      : Icons.remove_circle,
                  color: item.isAvailable.value
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
                onPressed: () =>
                    item.isAvailable.value = !item.isAvailable.value,
              ),
            ),
          ),

          // Remove option button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Remove Option',
            onPressed: () => controller.removeOption(index),
          ),
        ],
      ),
    );
  }
}
