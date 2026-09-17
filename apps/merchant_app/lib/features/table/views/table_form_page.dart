import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/table_form_controller.dart';

class TableFormPage extends GetView<TableFormController> {
  const TableFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditMode ? 'Edit Dining Table' : 'Add Dining Table',
            style: AppTextStyles.h2,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingData.value) {
          return const AppLoadingIndicator(message: 'Loading table info...');
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
                              'Table Information',
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Table Name
                            TextFormField(
                              controller: controller.nameController,
                              decoration: InputDecoration(
                                labelText: 'Table Name / Number *',
                                hintText: 'e.g. Table 1, Booth 4, Patio 2',
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
                                  return 'Table name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Capacity
                            TextFormField(
                              controller: controller.capacityController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Capacity (Number of Guests)',
                                hintText: 'e.g. 4',
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

                            // Dining Area dropdown
                            Obx(
                              () => DropdownButtonFormField<String>(
                                initialValue: controller.selectedAreaId.value,
                                decoration: InputDecoration(
                                  labelText: 'Dining Area (Optional)',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.small,
                                    ),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('None (General Seating)'),
                                  ),
                                  ...controller.areas.map((a) {
                                    return DropdownMenuItem(
                                      value: a.id,
                                      child: Text(a.name),
                                    );
                                  }),
                                ],
                                onChanged: (val) =>
                                    controller.selectedAreaId.value = val,
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
                                      'Active tables can be used for QR ordering and seating.',
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

                    const SizedBox(height: AppSpacing.md),

                    if (!controller.isEditMode)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'A unique, cryptographically secure QR code is automatically created by the backend when you save this table.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
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
                                : 'Create Table',
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
