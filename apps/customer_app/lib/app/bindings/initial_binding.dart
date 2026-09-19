import 'package:get/get.dart';
import '../../core/services/restaurant_context_service.dart';
import '../../core/services/session_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_menu_repository.dart';
import '../../data/repositories/customer_qr_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_customer_menu_repository.dart';
import '../../data/repositories/supabase_customer_qr_repository.dart';

/// Global bindings initialized at customer application startup.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Supabase Client Service
    final supabaseService = Get.put<SupabaseService>(
      SupabaseService(),
      permanent: true,
    );

    // 2. Auth Repository
    final authRepository = Get.put<AuthRepository>(
      SupabaseAuthRepository(supabaseService: supabaseService),
      permanent: true,
    );

    // 3. Session Service
    Get.put<SessionService>(
      SessionService(authRepository: authRepository),
      permanent: true,
    );

    // 4. Restaurant & Table Context Service
    Get.put<RestaurantContextService>(
      RestaurantContextService(),
      permanent: true,
    );

    // 5. QR Repository
    Get.put<CustomerQrRepository>(
      SupabaseCustomerQrRepository(supabaseService: supabaseService),
      permanent: true,
    );

    // 6. Menu Repository
    Get.put<CustomerMenuRepository>(
      SupabaseCustomerMenuRepository(supabaseService: supabaseService),
      permanent: true,
    );
  }
}
