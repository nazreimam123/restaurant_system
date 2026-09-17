import 'package:get/get.dart';
import '../controllers/branch_select_controller.dart';

class BranchSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BranchSelectController>(() => BranchSelectController());
  }
}
