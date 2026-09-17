import 'package:get/get.dart';
import '../../core/services/admin_session_service.dart';
import '../../core/services/merchant_context_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/repositories/admin_auth_repository.dart';
import '../../data/repositories/merchant_membership_repository.dart';
import '../../data/repositories/supabase_admin_auth_repository.dart';
import '../../data/repositories/supabase_merchant_membership_repository.dart';

/// Global bindings initialized at merchant application startup.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Supabase Client Service
    final supabaseService = Get.put<SupabaseService>(
      SupabaseService(),
      permanent: true,
    );

    // 2. Merchant Auth Repository
    final authRepository = Get.put<AdminAuthRepository>(
      SupabaseAdminAuthRepository(supabaseService: supabaseService),
      permanent: true,
    );

    // 3. Admin Session Service
    Get.put<AdminSessionService>(
      AdminSessionService(authRepository: authRepository),
      permanent: true,
    );

    // 4. Membership & Branch Access Repository
    Get.put<MerchantMembershipRepository>(
      SupabaseMerchantMembershipRepository(supabaseService: supabaseService),
      permanent: true,
    );

    // 5. Merchant Context Service
    Get.put<MerchantContextService>(MerchantContextService(), permanent: true);
  }
}
