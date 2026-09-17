import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../app/routes/admin_routes.dart';
import '../../../core/services/admin_session_service.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/merchant_membership_repository.dart';

class RestaurantSelectController extends GetxController {
  final MerchantMembershipRepository _membershipRepo =
      Get.find<MerchantMembershipRepository>();
  final MerchantContextService _contextService =
      Get.find<MerchantContextService>();
  final AdminSessionService _sessionService = Get.find<AdminSessionService>();

  final RxBool isLoading = true.obs;
  final RxBool isSelecting = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<RestaurantMembership> memberships = <RestaurantMembership>[].obs;

  @override
  void onReady() {
    super.onReady();
    loadMemberships();
  }

  Future<void> loadMemberships() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final list = await _membershipRepo.loadMemberships();
      memberships.assignAll(list);
      developer.log(
        'RestaurantSelectController: Loaded ${list.length} memberships.',
        name: 'RestaurantSelectController',
      );
    } catch (e, st) {
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectRestaurant(RestaurantMembership membership) async {
    isSelecting.value = true;
    errorMessage.value = null;

    try {
      // 1. Fetch accessible branches for this restaurant & role
      final branches = await _membershipRepo.loadAccessibleBranches(
        restaurantId: membership.restaurantId,
        role: membership.role,
      );

      if (branches.isEmpty) {
        errorMessage.value =
            'You do not have access to any active branches in ${membership.restaurantName}. Contact your manager.';
        isSelecting.value = false;
        return;
      }

      if (branches.length == 1) {
        // Auto-select the single available branch
        final singleBranch = branches.first;
        _contextService.setContext(
          MerchantContext(
            restaurantId: membership.restaurantId,
            restaurantName: membership.restaurantName,
            branchId: singleBranch.branchId,
            branchName: singleBranch.branchName,
            role: membership.role,
          ),
        );

        _navigateToRoleDestination(membership.role);
      } else {
        // Multiple branches available: save preliminary restaurant context and navigate to BranchSelectPage
        _contextService.setContext(
          MerchantContext(
            restaurantId: membership.restaurantId,
            restaurantName: membership.restaurantName,
            branchId: '',
            branchName: '',
            role: membership.role,
          ),
        );

        Get.toNamed(AdminRoutes.selectBranch);
      }
    } catch (e, st) {
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isSelecting.value = false;
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

  bool get isAuthenticated => _sessionService.isAuthenticated.value;

  void goToCreateRestaurant() {
    Get.toNamed(AdminRoutes.createRestaurant);
  }

  Future<void> signOut() async {
    await _sessionService.signOut();
    _contextService.clearContext();
    Get.offAllNamed(AdminRoutes.login);
  }
}
