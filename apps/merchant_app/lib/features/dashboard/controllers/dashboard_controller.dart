import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:app_models/app_models.dart';
import '../../../app/routes/admin_routes.dart';
import '../../../core/services/admin_session_service.dart';
import '../../../core/services/merchant_context_service.dart';

/// Controller managing the merchant operational dashboard launchpad.
///
/// NOTE (AGENTS.md rule 10 & 29):
/// This is an operational launchpad for Phase 6 features, not the final analytics dashboard.
/// It displays active restaurant/branch context from [MerchantContextService] and coordinates
/// navigation. It contains NO fake metrics, charts, or reports RPC calls.
class DashboardController extends GetxController {
  final MerchantContextService _contextService =
      Get.find<MerchantContextService>();
  final AdminSessionService _sessionService = Get.find<AdminSessionService>();

  String get restaurantName =>
      _contextService.restaurantName ?? 'Active Restaurant';
  String get branchName => _contextService.branchName ?? 'Main Branch';
  StaffRole get role => _contextService.role ?? StaffRole.owner;
  String get roleLabel => role.name.toUpperCase();

  // Role-aware visibility flags (UX only; backend RLS enforces authoritative security)
  bool get isOwnerOrManager =>
      role == StaffRole.owner || role == StaffRole.manager;
  bool get isCashier => role == StaffRole.cashier;
  bool get isWaiter => role == StaffRole.waiter;
  bool get isKitchen => role == StaffRole.kitchen;

  /// Menu management is visible to Owner and Manager.
  bool get canManageMenu => isOwnerOrManager;

  /// Tables & QR codes are visible to Owner, Manager, and Waiter.
  bool get canManageTables => isOwnerOrManager || isWaiter;

  /// Orders station is visible to Cashier, Waiter, and Owner/Manager.
  bool get canViewOrders => isCashier || isWaiter || isOwnerOrManager;

  /// KDS station is visible to Kitchen, Manager, and Owner.
  bool get canViewKds => isKitchen || isOwnerOrManager;

  void goToCategories() {
    Get.toNamed(AdminRoutes.categories);
  }

  void goToProducts() {
    Get.toNamed(AdminRoutes.products);
  }

  void goToModifiers() {
    Get.toNamed(AdminRoutes.modifiers);
  }

  void goToTables() {
    Get.toNamed(AdminRoutes.tables);
  }

  void goToOrders() {
    Get.toNamed(AdminRoutes.orders);
  }

  void goToKds() {
    Get.toNamed(AdminRoutes.kds);
  }

  void switchRestaurant() {
    Get.toNamed(AdminRoutes.selectRestaurant);
  }

  void switchBranch() {
    Get.toNamed(AdminRoutes.selectBranch);
  }

  Future<void> signOut() async {
    developer.log(
      'DashboardController: Signing out staff member.',
      name: 'Dashboard',
    );
    await _sessionService.signOut();
    _contextService.clearContext();
    Get.offAllNamed(AdminRoutes.login);
  }
}
