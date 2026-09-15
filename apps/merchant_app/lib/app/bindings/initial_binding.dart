import 'package:get/get.dart';
import '../../core/services/supabase_service.dart';

/// Global bindings initialized at merchant application startup.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.putAsync<SupabaseService>(
      () => SupabaseService().init(),
      permanent: true,
    );
  }
}
