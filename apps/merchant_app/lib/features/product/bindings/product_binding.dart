import 'package:get/get.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/supabase_category_repository.dart';
import '../../../data/repositories/supabase_product_repository.dart';
import '../controllers/product_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProductRepository>()) {
      Get.lazyPut<ProductRepository>(() => SupabaseProductRepository());
    }
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(() => SupabaseCategoryRepository());
    }

    Get.lazyPut<ProductController>(
      () => ProductController(
        productRepo: Get.find<ProductRepository>(),
        categoryRepo: Get.find<CategoryRepository>(),
        contextService: Get.find<MerchantContextService>(),
      ),
    );
  }
}
