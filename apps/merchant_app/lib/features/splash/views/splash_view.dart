import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_widgets/app_widgets.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88.0,
              height: 88.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.xlBorderRadius,
                boxShadow: AppShadows.card,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 48.0,
                color: AppColors.primaryDark,
              ),
            ),
            AppSpacing.gapXl,
            Text(
              'Merchant Portal',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
            AppSpacing.gapSm,
            Text(
              'Operations • Live Orders • KDS',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryLight,
              ),
            ),
            AppSpacing.gapXxl,
            const SizedBox(
              width: 24.0,
              height: 24.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
