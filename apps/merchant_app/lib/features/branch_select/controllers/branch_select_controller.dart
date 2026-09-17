import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../app/routes/admin_routes.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/merchant_membership_repository.dart';

class BranchSelectController extends GetxController {
  final MerchantMembershipRepository _membershipRepo =
      Get.find<MerchantMembershipRepository>();
  final MerchantContextService _contextService =
      Get.find<MerchantContextService>();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxList<BranchAccess> branches = <BranchAccess>[].obs;

  String get restaurantName => _contextService.restaurantName ?? 'Restaurant';
  String? get restaurantId => _contextService.restaurantId;
  StaffRole? get role => _contextService.role;

  @override
  void onReady() {
    super.onReady();
    loadBranches();
  }

  Future<void> loadBranches() async {
    final rId = restaurantId;
    final rRole = role;

    if (rId == null || rRole == null) {
      Get.offAllNamed(AdminRoutes.selectRestaurant);
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final list = await _membershipRepo.loadAccessibleBranches(
        restaurantId: rId,
        role: rRole,
      );
      branches.assignAll(list);
      developer.log(
        'BranchSelectController: Loaded ${list.length} branches for restaurant $rId.',
        name: 'BranchSelectController',
      );
    } catch (e, st) {
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isLoading.value = false;
    }
  }

  void selectBranch(BranchAccess branch) {
    final rRole = role;
    if (rRole == null) {
      Get.offAllNamed(AdminRoutes.selectRestaurant);
      return;
    }

    _contextService.switchBranch(
      branchId: branch.branchId,
      branchName: branch.branchName,
    );

    // Route based on role authority
    switch (rRole) {
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
}
