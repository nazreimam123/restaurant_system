import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../core/services/supabase_service.dart';
import 'merchant_membership_repository.dart';

/// Supabase implementation of [MerchantMembershipRepository].
///
/// Queries backend RLS-secured tables (`restaurant_members`, `restaurants`, `branches`, `branch_members`).
class SupabaseMerchantMembershipRepository
    implements MerchantMembershipRepository {
  final SupabaseService _supabaseService;

  SupabaseMerchantMembershipRepository({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<List<RestaurantMembership>> loadMemberships() async {
    if (!_supabaseService.isInitialized) {
      throw const NetworkException(
        message: 'Backend service is not configured. Please verify connection.',
      );
    }

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AppAuthException(
          message: 'Authentication required to fetch memberships.',
        );
      }

      final response = await _client
          .from('restaurant_members')
          .select(
            'restaurant_id, role, is_active, restaurants(name, slug, logo_path, is_active)',
          )
          .eq('user_id', userId)
          .eq('is_active', true);

      final List<RestaurantMembership> memberships = [];
      for (final item in (response as List<dynamic>)) {
        final row = item as Map<String, dynamic>;
        final restaurant = row['restaurants'] as Map<String, dynamic>?;
        final isRestaurantActive = restaurant?['is_active'] as bool? ?? true;

        if (isRestaurantActive) {
          memberships.add(
            RestaurantMembership(
              restaurantId: row['restaurant_id'] as String,
              restaurantName: restaurant?['name'] as String? ?? 'Restaurant',
              restaurantLogoPath: restaurant?['logo_path'] as String?,
              role: StaffRole.fromJson(row['role'] as String),
              isActive: row['is_active'] as bool? ?? true,
            ),
          );
        }
      }

      return memberships;
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  @override
  Future<List<BranchAccess>> loadAccessibleBranches({
    required String restaurantId,
    required StaffRole role,
  }) async {
    if (!_supabaseService.isInitialized) {
      throw const NetworkException(
        message: 'Backend service is not configured. Please verify connection.',
      );
    }

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AppAuthException(
          message: 'Authentication required to fetch branches.',
        );
      }

      final List<BranchAccess> branches = [];

      // Owners and managers have tenant-wide visibility
      if (role == StaffRole.owner || role == StaffRole.manager) {
        final response = await _client
            .from('branches')
            .select('id, name, restaurant_id, is_active')
            .eq('restaurant_id', restaurantId)
            .eq('is_active', true)
            .order('name');

        for (final item in (response as List<dynamic>)) {
          final row = item as Map<String, dynamic>;
          branches.add(
            BranchAccess(
              branchId: row['id'] as String,
              branchName: row['name'] as String? ?? 'Branch',
              restaurantId: restaurantId,
              isActive: row['is_active'] as bool? ?? true,
            ),
          );
        }
      } else {
        // Staff roles (cashier, waiter, kitchen) query assigned branches
        final response = await _client
            .from('branch_members')
            .select('branch_id, branches(id, name, restaurant_id, is_active)')
            .eq('user_id', userId)
            .eq('restaurant_id', restaurantId)
            .eq('is_active', true);

        for (final item in (response as List<dynamic>)) {
          final row = item as Map<String, dynamic>;
          final branch = row['branches'] as Map<String, dynamic>?;
          final isBranchActive = branch?['is_active'] as bool? ?? true;

          if (isBranchActive && branch != null) {
            branches.add(
              BranchAccess(
                branchId: branch['id'] as String,
                branchName: branch['name'] as String? ?? 'Branch',
                restaurantId: restaurantId,
                isActive: true,
              ),
            );
          }
        }
      }

      return branches;
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  @override
  Future<CreateRestaurantResult> createRestaurant(
    CreateRestaurantRequest request,
  ) async {
    if (!_supabaseService.isInitialized) {
      throw const NetworkException(
        message: 'Backend service is not configured. Please verify connection.',
      );
    }

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AppAuthException(
          message: 'Authentication required to create a restaurant.',
        );
      }

      final response = await _client.rpc(
        'create_restaurant',
        params: request.toRpcParams(),
      );

      if (response is Map<String, dynamic>) {
        final ok = response['ok'] as bool? ?? false;
        if (!ok) {
          final errMap = response['error'] as Map<String, dynamic>?;
          final codeStr = errMap?['code'] as String? ?? 'CONFLICT';
          final message =
              errMap?['message'] as String? ?? 'Failed to create restaurant.';
          throw ErrorMapper.fromApiError(code: codeStr, message: message);
        }

        final data = response['data'] as Map<String, dynamic>;
        return CreateRestaurantResult.fromJson(data);
      }

      throw ServerException(
        message: 'Invalid response from create_restaurant RPC.',
        code: ErrorCode.serverError,
      );
    } catch (e, st) {
      if (e is AppException) rethrow;
      throw ErrorMapper.map(e, st);
    }
  }
}
