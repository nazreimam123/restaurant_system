import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../app/routes/admin_routes.dart';
import '../../../core/services/admin_session_service.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/repositories/merchant_membership_repository.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final AdminSessionService _sessionService = Get.find<AdminSessionService>();
  final MerchantMembershipRepository _membershipRepo =
      Get.find<MerchantMembershipRepository>();
  final MerchantContextService _contextService =
      Get.find<MerchantContextService>();

  @override
  void onReady() {
    super.onReady();
    bootstrap();
  }

  Future<void> bootstrap() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 1. Initialize Supabase Client
      if (!_supabaseService.isInitialized) {
        await _supabaseService.init();
      }

      // 2. Initialize Session
      await _sessionService.init();

      // Brief animation pause
      await Future.delayed(const Duration(milliseconds: 600));

      // 3. If unauthenticated, redirect to Login
      if (!_sessionService.isAuthenticated.value) {
        developer.log(
          'SplashController: No active merchant session found. Routing to login.',
          name: 'SplashController',
        );
        isLoading.value = false;
        Get.offAllNamed(AdminRoutes.login);
        return;
      }

      // 4. If persisted context exists, validate against live backend
      final hasValidStoredContext = await _contextService.validateAndRestore(
        _membershipRepo,
      );

      if (hasValidStoredContext && _contextService.role != null) {
        developer.log(
          'SplashController: Restored and verified active merchant context (${_contextService.branchName}). Routing to operational dashboard.',
          name: 'SplashController',
        );
        isLoading.value = false;
        _navigateToRoleDestination(_contextService.role!);
        return;
      }

      // 5. Load active memberships from backend
      final memberships = await _membershipRepo.loadMemberships();

      if (memberships.isEmpty) {
        developer.log(
          'SplashController: Zero active memberships found. Routing to restaurant selection.',
          name: 'SplashController',
        );
        isLoading.value = false;
        Get.offAllNamed(AdminRoutes.selectRestaurant);
        return;
      }

      if (memberships.length == 1) {
        final singleRestaurant = memberships.first;
        final branches = await _membershipRepo.loadAccessibleBranches(
          restaurantId: singleRestaurant.restaurantId,
          role: singleRestaurant.role,
        );

        if (branches.length == 1) {
          final singleBranch = branches.first;
          _contextService.setContext(
            MerchantContext(
              restaurantId: singleRestaurant.restaurantId,
              restaurantName: singleRestaurant.restaurantName,
              branchId: singleBranch.branchId,
              branchName: singleBranch.branchName,
              role: singleRestaurant.role,
            ),
          );

          isLoading.value = false;
          _navigateToRoleDestination(singleRestaurant.role);
          return;
        } else {
          // Store restaurant and prompt branch selection
          _contextService.setContext(
            MerchantContext(
              restaurantId: singleRestaurant.restaurantId,
              restaurantName: singleRestaurant.restaurantName,
              branchId: '',
              branchName: '',
              role: singleRestaurant.role,
            ),
          );

          isLoading.value = false;
          Get.offAllNamed(AdminRoutes.selectBranch);
          return;
        }
      }

      // Multiple restaurants: let user select
      isLoading.value = false;
      Get.offAllNamed(AdminRoutes.selectRestaurant);
    } catch (e, st) {
      developer.log(
        'SplashController: Startup error: $e',
        name: 'SplashController',
        error: e,
        stackTrace: st,
      );
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
      isLoading.value = false;
    }
  }

  void _navigateToRoleDestination(StaffRole role) {
    switch (role) {
      case StaffRole.owner:
      case StaffRole.manager:
        Get.offAllNamed(AdminRoutes.dashboard);
        break;
      case StaffRole.cashier:
      case StaffRole.waiter:
        Get.offAllNamed(AdminRoutes.orders);
        break;
      case StaffRole.kitchen:
        Get.offAllNamed(AdminRoutes.kds);
        break;
    }
  }

  void retry() {
    bootstrap();
  }
}
