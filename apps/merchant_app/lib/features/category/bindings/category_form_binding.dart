import 'package:get/get.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/supabase_category_repository.dart';
import '../controllers/category_form_controller.dart';

class CategoryFormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(() => SupabaseCategoryRepository());
    }

    Get.lazyPut<CategoryFormController>(
      () => CategoryFormController(
        categoryRepo: Get.find<CategoryRepository>(),
        contextService: Get.find<MerchantContextService>(),
      ),
    );
  }
}
