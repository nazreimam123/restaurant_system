import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/create_restaurant_controller.dart';

class CreateRestaurantView extends GetView<CreateRestaurantController> {
  const CreateRestaurantView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Restaurant'), elevation: 0),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxFormWidth,
            ),
            child: Form(
              key: controller.formKey,
              child: ListView(
                padding: AppSpacing.edgeInsetsLg,
                children: [
                  Text('Set Up Your Restaurant', style: AppTextStyles.h2),
                  AppSpacing.gapSm,
                  Text(
                    'Configure your primary restaurant profile and initial branch. You will be assigned as the owner.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapLg,

                  // Error Banner
                  Obx(() {
                    final err = controller.errorMessage.value;
                    if (err == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: AppSpacing.edgeInsetsMd,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: AppRadius.mediumBorderRadius,
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            child: Text(
                              err,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Restaurant Details Section
                  _buildSectionCard(
                    title: 'Restaurant Details',
                    subtitle: 'Brand and default operating parameters',
                    children: [
                      TextFormField(
                        controller: controller.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant Name *',
                          hintText: 'e.g. Pizza House Patna',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: controller.validateRestaurantName,
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: controller.slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug (URL Identifier) *',
                          hintText: 'e.g. pizza-house-patna',
                          helperText:
                              'Used in unique order URLs. Auto-generated or editable.',
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: controller.onSlugUserEdited,
                        validator: controller.validateSlug,
                      ),
                      AppSpacing.gapMd,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.currencyController,
                              decoration: const InputDecoration(
                                labelText: 'Currency (ISO) *',
                                hintText: 'e.g. INR',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: controller.validateCurrency,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: controller.timezoneController,
                              decoration: const InputDecoration(
                                labelText: 'Timezone *',
                                hintText: 'e.g. Asia/Kolkata',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: controller.validateTimezone,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  AppSpacing.gapLg,

                  // Initial Branch Details Section
                  _buildSectionCard(
                    title: 'Initial Branch',
                    subtitle: 'Physical location or primary outlet',
                    children: [
                      TextFormField(
                        controller: controller.branchNameController,
                        decoration: const InputDecoration(
                          labelText: 'Branch Name *',
                          hintText: 'e.g. Main Branch',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: controller.validateBranchName,
                      ),
                      AppSpacing.gapMd,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.branchCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Branch Code',
                                hintText: 'e.g. MAIN',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            child: TextFormField(
                              controller: controller.countryCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Country (2-letter) *',
                                hintText: 'e.g. IN',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: controller.validateCountryCode,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: controller.phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          hintText: 'e.g. +91 98765 43210',
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: controller.addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1',
                          hintText: 'e.g. 101 Food Street, Fraser Road',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      AppSpacing.gapMd,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                hintText: 'e.g. Patna',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            child: TextFormField(
                              controller: controller.stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                                hintText: 'e.g. Bihar',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: controller.postalCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code',
                          hintText: 'e.g. 800001',
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),

                  AppSpacing.gapXl,

                  // Submit Button
                  Obx(
                    () => AppButton(
                      label: 'Create Restaurant & Start',
                      leadingIcon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      isLoading: controller.isSubmitting.value,
                      onPressed: controller.submit,
                    ),
                  ),

                  AppSpacing.gapLg,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.largeBorderRadius,
        side: BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: AppSpacing.edgeInsetsLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            AppSpacing.gapXs,
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapLg,
            ...children,
          ],
        ),
      ),
    );
  }
}
