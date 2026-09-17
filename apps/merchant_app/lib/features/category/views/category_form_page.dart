import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/category_form_controller.dart';

class CategoryFormPage extends GetView<CategoryFormController> {
  const CategoryFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditMode ? 'Edit Category' : 'Create Category',
            style: AppTextStyles.h2,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingData.value) {
          return const AppLoadingIndicator(message: 'Loading category...');
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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

                    // Basic Details Card
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
                              'Category Information',
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Name field
                            TextFormField(
                              controller: controller.nameController,
                              decoration: InputDecoration(
                                labelText: 'Category Name *',
                                hintText:
                                    'e.g. Appetizers, Desserts, Beverages',
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.small,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Category name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Description field
                            TextFormField(
                              controller: controller.descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'Brief note about this category',
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

                            // Image Path field
                            TextFormField(
                              controller: controller.imagePathController,
                              decoration: InputDecoration(
                                labelText:
                                    'Image Storage Path / URL (Optional)',
                                hintText: 'e.g. categories/appetizers.webp',
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.small,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Active Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Active Status',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    Text(
                                      'Active categories are visible to customers on the menu.',
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
                                : 'Create Category',
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
}
