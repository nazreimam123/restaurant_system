import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/admin_auth_controller.dart';

class LoginView extends GetView<AdminAuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.edgeInsetsLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxAuthFormWidth,
            ),
            child: Card(
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.largeBorderRadius,
                side: BorderSide(color: AppColors.border, width: 1.0),
              ),
              child: Padding(
                padding: AppSpacing.edgeInsetsXl,
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Center(
                        child: Container(
                          width: 64.0,
                          height: 64.0,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.largeBorderRadius,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 36.0,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      AppSpacing.gapLg,
                      Text(
                        'Merchant Portal',
                        style: AppTextStyles.h2,
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        'Sign in to manage your restaurant operations',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapXl,

                      // Error message banner
                      Obx(() {
                        final error = controller.errorMessage.value;
                        if (error == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          padding: AppSpacing.edgeInsetsMd,
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: AppRadius.mediumBorderRadius,
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.danger,
                                size: 20.0,
                              ),
                              AppSpacing.gapSm,
                              Expanded(
                                child: Text(
                                  error,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Email Field
                      Text('Email Address', style: AppTextStyles.captionMedium),
                      AppSpacing.gapXs,
                      TextFormField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          hintText: 'staff@restaurant.com',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            size: 20.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.gapLg,

                      // Password Field
                      Text('Password', style: AppTextStyles.captionMedium),
                      AppSpacing.gapXs,
                      Obx(
                        () => TextFormField(
                          controller: controller.passwordController,
                          obscureText: controller.obscurePassword.value,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20.0,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscurePassword.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20.0,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      AppSpacing.gapXl,

                      // Submit Button
                      Obx(
                        () => AppButton(
                          label: 'Sign In',
                          isLoading: controller.isLoading.value,
                          onPressed: controller.signIn,
                        ),
                      ),
                      AppSpacing.gapLg,

                      // Forgot password note
                      Text(
                        'Forgot your credentials? Contact your restaurant administrator.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
