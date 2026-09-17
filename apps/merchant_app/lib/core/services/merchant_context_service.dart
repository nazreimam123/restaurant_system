import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:app_models/app_models.dart';
import '../../data/repositories/merchant_membership_repository.dart';

/// Long-lived service managing the active merchant restaurant and branch context.
///
/// IMPORTANT (AGENTS.md rule 29 & Part K):
/// MerchantContextService is UX/navigation state only.
/// It is NEVER proof of authorization.
/// Backend RLS and PostgreSQL policies validate every tenant-sensitive operation.
class MerchantContextService extends GetxService {
  static const String _storageKey = 'merchant_context';
  final GetStorage _storage = GetStorage();

  final Rxn<MerchantContext> _context = Rxn<MerchantContext>();

  MerchantContext? get currentContext => _context.value;
  bool get hasValidContext => _context.value != null;

  String? get restaurantId => _context.value?.restaurantId;
  String? get restaurantName => _context.value?.restaurantName;
  String? get branchId => _context.value?.branchId;
  String? get branchName => _context.value?.branchName;
  StaffRole? get role => _context.value?.role;

  /// Sets complete context and persists safe snapshot locally.
  void setContext(MerchantContext context) {
    _context.value = context;
    try {
      _storage.write(_storageKey, context.toJson());
      developer.log(
        'MerchantContextService: Active context set -> Restaurant: ${context.restaurantName} (${context.restaurantId}), Branch: ${context.branchName} (${context.branchId}), Role: ${context.role.name}',
        name: 'MerchantContextService',
      );
    } catch (e) {
      developer.log(
        'MerchantContextService: Failed to persist context: $e',
        name: 'MerchantContextService',
      );
    }
  }

  /// Sets or updates the active branch under current restaurant.
  void switchBranch({required String branchId, required String branchName}) {
    final current = _context.value;
    if (current == null) {
      throw StateError(
        'Cannot switch branch without an active restaurant context.',
      );
    }

    _prepareBranchSwitchHooks();

    final updated = MerchantContext(
      restaurantId: current.restaurantId,
      restaurantName: current.restaurantName,
      branchId: branchId,
      branchName: branchName,
      role: current.role,
    );

    setContext(updated);
  }

  /// Clears stored context when logging out or switching accounts.
  void clearContext() {
    _prepareBranchSwitchHooks();
    _context.value = null;
    try {
      _storage.remove(_storageKey);
    } catch (_) {}
  }

  /// Restores persisted context from local storage if available.
  MerchantContext? restoreContext() {
    try {
      final raw = _storage.read<Map<String, dynamic>>(_storageKey);
      if (raw != null) {
        final restored = MerchantContext.fromJson(
          Map<String, dynamic>.from(raw),
        );
        _context.value = restored;
        return restored;
      }
    } catch (e) {
      developer.log(
        'MerchantContextService: Corrupted context in local storage, clearing: $e',
        name: 'MerchantContextService',
      );
      clearContext();
    }
    return null;
  }

  /// Revalidates locally persisted context against live backend memberships and branch access.
  ///
  /// Never routes based solely on stale local role/context.
  Future<bool> validateAndRestore(
    MerchantMembershipRepository membershipRepo,
  ) async {
    final saved = restoreContext();
    if (saved == null) return false;

    try {
      // 1. Verify restaurant membership is still active and retrieve latest role
      final memberships = await membershipRepo.loadMemberships();
      final matchingMembership = memberships.firstWhereOrNull(
        (m) => m.restaurantId == saved.restaurantId && m.isActive,
      );

      if (matchingMembership == null) {
        developer.log(
          'MerchantContextService: Restaurant membership revoked or inactive. Clearing context.',
          name: 'MerchantContextService',
        );
        clearContext();
        return false;
      }

      // 2. Verify branch access is still valid for the active role
      final branches = await membershipRepo.loadAccessibleBranches(
        restaurantId: saved.restaurantId,
        role: matchingMembership.role,
      );

      final matchingBranch = branches.firstWhereOrNull(
        (b) => b.branchId == saved.branchId && b.isActive,
      );

      if (matchingBranch == null) {
        developer.log(
          'MerchantContextService: Branch access revoked or inactive. Clearing context.',
          name: 'MerchantContextService',
        );
        clearContext();
        return false;
      }

      // Update context with backend-verified values
      final validated = MerchantContext(
        restaurantId: matchingMembership.restaurantId,
        restaurantName: matchingMembership.restaurantName,
        branchId: matchingBranch.branchId,
        branchName: matchingBranch.branchName,
        role: matchingMembership.role,
      );

      setContext(validated);
      return true;
    } catch (e) {
      developer.log(
        'MerchantContextService: Error validating context against backend: $e',
        name: 'MerchantContextService',
      );
      clearContext();
      return false;
    }
  }

  /// Internal hook preparing for Realtime unsubscriptions and cache resets.
  void _prepareBranchSwitchHooks() {
    // Hooks reserved for Phase 9 Realtime and state invalidation
    developer.log(
      'MerchantContextService: Triggering branch switch/teardown hooks.',
      name: 'MerchantContextService',
    );
  }
}
