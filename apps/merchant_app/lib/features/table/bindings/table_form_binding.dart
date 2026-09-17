import 'package:get/get.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/supabase_table_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../controllers/table_form_controller.dart';

class TableFormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TableRepository>()) {
      Get.lazyPut<TableRepository>(() => SupabaseTableRepository());
    }

    Get.lazyPut<TableFormController>(
      () => TableFormController(
        tableRepo: Get.find<TableRepository>(),
        contextService: Get.find<MerchantContextService>(),
      ),
    );
  }
}
