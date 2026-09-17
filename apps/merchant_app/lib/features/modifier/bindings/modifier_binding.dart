import 'package:get/get.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/modifier_repository.dart';
import '../../../data/repositories/supabase_modifier_repository.dart';
import '../controllers/modifier_controller.dart';

class ModifierBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ModifierRepository>()) {
      Get.lazyPut<ModifierRepository>(() => SupabaseModifierRepository());
    }

    Get.lazyPut<ModifierController>(
      () => ModifierController(
        modifierRepo: Get.find<ModifierRepository>(),
        contextService: Get.find<MerchantContextService>(),
      ),
    );
  }
}
