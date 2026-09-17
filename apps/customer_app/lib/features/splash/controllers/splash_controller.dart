import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/restaurant_context_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final SessionService _sessionService = Get.find<SessionService>();
  final RestaurantContextService _restaurantContextService =
      Get.find<RestaurantContextService>();

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

      // 5. Route determination based on restored context
      if (Get.currentRoute == AppRoutes.splash) {
        if (_restaurantContextService.hasValidContext) {
          developer.log(
            'SplashController: Found valid saved restaurant context (${_restaurantContextService.branchId}). Routing to menu.',
            name: 'SplashController',
          );
          Get.offNamed(AppRoutes.menu);
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
