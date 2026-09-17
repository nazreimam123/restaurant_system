import 'package:get/get.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/modifier_repository.dart';
import '../../../data/repositories/supabase_modifier_repository.dart';
import '../controllers/modifier_form_controller.dart';

class ModifierFormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ModifierRepository>()) {
      Get.lazyPut<ModifierRepository>(() => SupabaseModifierRepository());
    }

    Get.lazyPut<ModifierFormController>(
      () => ModifierFormController(
        modifierRepo: Get.find<ModifierRepository>(),
        contextService: Get.find<MerchantContextService>(),
      ),
    );
  }
}
