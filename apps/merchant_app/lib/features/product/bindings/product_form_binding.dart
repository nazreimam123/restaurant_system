import 'package:get/get.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/modifier_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/supabase_category_repository.dart';
import '../../../data/repositories/supabase_modifier_repository.dart';
import '../../../data/repositories/supabase_product_repository.dart';
import '../controllers/product_form_controller.dart';

class ProductFormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProductRepository>()) {
      Get.lazyPut<ProductRepository>(() => SupabaseProductRepository());
    }
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(() => SupabaseCategoryRepository());
    }
    if (!Get.isRegistered<ModifierRepository>()) {
      Get.lazyPut<ModifierRepository>(() => SupabaseModifierRepository());
    }

    Get.lazyPut<ProductFormController>(
      () => ProductFormController(
        productRepo: Get.find<ProductRepository>(),
        categoryRepo: Get.find<CategoryRepository>(),
        modifierRepo: Get.find<ModifierRepository>(),
        contextService: Get.find<MerchantContextService>(),
      ),
    );
  }
}
