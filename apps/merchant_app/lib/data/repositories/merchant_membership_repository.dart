import 'package:app_models/app_models.dart';

/// Repository interface for merchant restaurant memberships and branch access.
abstract class MerchantMembershipRepository {
  /// Loads all active restaurant memberships for the currently authenticated staff member.
  Future<List<RestaurantMembership>> loadMemberships();

  /// Loads all active branches accessible to the staff member within the specified restaurant.
  ///
  /// Owners and managers have tenant-wide branch visibility.
  /// Cashiers, waiters, and kitchen staff have visibility into explicitly assigned branches.
  Future<List<BranchAccess>> loadAccessibleBranches({
    required String restaurantId,
    required StaffRole role,
  });
}
