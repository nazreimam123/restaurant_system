import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Brief animation delay before checking stored context
    await Future.delayed(const Duration(milliseconds: 1200));
    isLoading.value = false;

    // Navigate to scan page if not already deep-linked or routed
    if (Get.currentRoute == AppRoutes.splash) {
      Get.offNamed(AppRoutes.scan);
    }
  }
}
