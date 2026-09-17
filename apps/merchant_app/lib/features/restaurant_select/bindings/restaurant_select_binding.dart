import 'package:get/get.dart';
import '../controllers/restaurant_select_controller.dart';

class RestaurantSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RestaurantSelectController>(() => RestaurantSelectController());
  }
}
