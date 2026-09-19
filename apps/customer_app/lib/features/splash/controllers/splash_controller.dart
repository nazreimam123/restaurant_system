import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/restaurant_context_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/repositories/customer_menu_repository.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final SessionService _sessionService = Get.find<SessionService>();
  final RestaurantContextService _restaurantContextService =
      Get.find<RestaurantContextService>();
  final CustomerMenuRepository _menuRepository =
      Get.find<CustomerMenuRepository>();

  @override
  void onReady() {
    super.onReady();
    bootstrap();
  }

  Future<void> bootstrap() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 1. Initialize Supabase if not yet initialized
      if (!_supabaseService.isInitialized) {
        await _supabaseService.init();
      }

      // 2. Initialize Session Service
      await _sessionService.init();

      // 3. Ensure an active anonymous customer session if configured
      if (_supabaseService.isInitialized) {
        await _sessionService.ensureSession();
      } else {
        developer.log(
          'SplashController: Supabase credentials not configured in current environment. Proceeding in offline development shell.',
          name: 'SplashController',
        );
      }

      // 4. Restore Restaurant Context
      await _restaurantContextService.init();

      // Brief transition delay for visual polish
      await Future.delayed(const Duration(milliseconds: 600));

      isLoading.value = false;

      // 5. Route determination based on validated restored context
      if (Get.currentRoute == AppRoutes.splash) {
        if (_restaurantContextService.hasValidContext) {
          final branchId = _restaurantContextService.branchId;
          bool isValidBranch = false;

          if (branchId != null) {
            try {
              // Validate that branch is active and accessible
              await _menuRepository.getPublicMenu(branchId);
              isValidBranch = true;
            } catch (e) {
              developer.log(
                'SplashController: Restored context branch ($branchId) is no longer valid: $e. Clearing context.',
                name: 'SplashController',
              );
              _restaurantContextService.clearContext();
            }
          }

          if (isValidBranch) {
            developer.log(
              'SplashController: Verified saved restaurant context ($branchId). Routing to menu.',
              name: 'SplashController',
            );
            Get.offNamed(AppRoutes.menu);
          } else {
            developer.log(
              'SplashController: Routing to QR scanner.',
              name: 'SplashController',
            );
            Get.offNamed(AppRoutes.scan);
          }
        } else {
          developer.log(
            'SplashController: No saved restaurant context found. Routing to QR scanner.',
            name: 'SplashController',
          );
          Get.offNamed(AppRoutes.scan);
        }
      }
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

  void retry() {
    bootstrap();
  }
}
