import 'package:get/get.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/supabase_table_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../controllers/qr_controller.dart';

class QrBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TableRepository>()) {
      Get.lazyPut<TableRepository>(() => SupabaseTableRepository());
    }

    Get.lazyPut<QrController>(
      () => QrController(
        tableRepo: Get.find<TableRepository>(),
        contextService: Get.find<MerchantContextService>(),
      ),
    );
  }
}
