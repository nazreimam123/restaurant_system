import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../core/services/supabase_service.dart';
import 'customer_menu_repository.dart';

/// Supabase implementation of [CustomerMenuRepository] using authoritative `get_public_menu` RPC.
///
/// Follows AGENTS.md rule 14:
/// "The following operations must remain trusted backend operations: get_public_menu ...
/// When corresponding SQL exists, call it exactly according to API_CONTRACTS.md."
class SupabaseCustomerMenuRepository implements CustomerMenuRepository {
  final SupabaseService _supabaseService;

  SupabaseCustomerMenuRepository({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<RestaurantMenu> getPublicMenu(String branchId) async {
    try {
      // 1. Ensure Supabase client is initialized
      if (!_supabaseService.isInitialized) {
        developer.log(
          'SupabaseCustomerMenuRepository: Supabase not initialized, initializing now...',
          name: 'SupabaseCustomerMenuRepository',
        );
        await _supabaseService.init();
      }

      // 2. Ensure an active session (anonymous or authenticated) before making RPC call
      if (_client.auth.currentSession == null) {
        developer.log(
          'SupabaseCustomerMenuRepository: No active session, signing in anonymously...',
          name: 'SupabaseCustomerMenuRepository',
        );
        await _client.auth.signInAnonymously();
      }

      developer.log(
        'SupabaseCustomerMenuRepository: Invoking get_public_menu RPC for branch: $branchId',
        name: 'SupabaseCustomerMenuRepository',
      );

      final response = await _client.rpc(
        'get_public_menu',
        params: {'p_branch_id': branchId},
      );

      if (response is Map<String, dynamic>) {
        final ok = response['ok'] as bool? ?? false;
        if (!ok) {
          final errMap = response['error'] as Map<String, dynamic>?;
          final codeStr = errMap?['code'] as String? ?? 'BRANCH_NOT_FOUND';
          final message =
              errMap?['message'] as String? ?? 'Failed to load menu.';
          throw ErrorMapper.fromApiError(code: codeStr, message: message);
        }

        final data = response['data'] as Map<String, dynamic>;
        return RestaurantMenu.fromJson(data);
      }

      throw ServerException(
        message: 'Invalid response from get_public_menu RPC.',
        code: ErrorCode.serverError,
      );
    } catch (e, st) {
      developer.log(
        'SupabaseCustomerMenuRepository: Caught error during getPublicMenu: $e',
        name: 'SupabaseCustomerMenuRepository',
        error: e,
        stackTrace: st,
      );
      if (e is AppException) rethrow;
      throw ErrorMapper.map(e, st);
    }
  }
}
