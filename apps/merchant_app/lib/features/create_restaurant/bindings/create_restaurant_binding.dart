import 'package:get/get.dart';
import '../controllers/create_restaurant_controller.dart';

class CreateRestaurantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateRestaurantController>(() => CreateRestaurantController());
  }
}
