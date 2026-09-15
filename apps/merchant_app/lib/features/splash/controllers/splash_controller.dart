import 'package:get/get.dart';
import '../../../app/routes/admin_routes.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    isLoading.value = false;

    // Navigate to login page if unauthenticated
    if (Get.currentRoute == AdminRoutes.splash) {
      Get.offNamed(AdminRoutes.login);
    }
  }
}
