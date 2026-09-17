import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import '../../../app/routes/admin_routes.dart';
import '../../../data/repositories/admin_auth_repository.dart';

class AdminAuthController extends GetxController {
  final AdminAuthRepository _authRepository = Get.find<AdminAuthRepository>();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxnString errorMessage = RxnString();

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _authRepository.signIn(
        emailController.text.trim(),
        passwordController.text,
      );

      // Re-trigger splash / startup router to re-evaluate memberships
      Get.offAllNamed(AdminRoutes.splash);
    } catch (e, st) {
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
