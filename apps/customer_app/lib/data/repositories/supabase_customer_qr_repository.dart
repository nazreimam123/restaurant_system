import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../core/services/supabase_service.dart';
import 'customer_qr_repository.dart';

/// Supabase implementation of [CustomerQrRepository] using authoritative `resolve_qr` RPC.
///
/// Follows AGENTS.md rule 14:
/// "The following operations must remain trusted backend operations: resolve_qr ...
/// Call it exactly according to API_CONTRACTS.md. Do not replace with direct client writes."
class SupabaseCustomerQrRepository implements CustomerQrRepository {
  final SupabaseService _supabaseService;

  SupabaseCustomerQrRepository({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<QrContext> resolveQr(String qrToken) async {
    try {
      // 1. Ensure Supabase client is initialized
      if (!_supabaseService.isInitialized) {
        developer.log(
          'SupabaseCustomerQrRepository: Supabase not initialized, initializing now...',
          name: 'SupabaseCustomerQrRepository',
        );
        await _supabaseService.init();
      }

      // 2. Ensure an active session (anonymous or authenticated) before making RPC call
      if (_client.auth.currentSession == null) {
        developer.log(
          'SupabaseCustomerQrRepository: No active session, signing in anonymously...',
          name: 'SupabaseCustomerQrRepository',
        );
        await _client.auth.signInAnonymously();
      }

      developer.log(
        'SupabaseCustomerQrRepository: Invoking resolve_qr RPC for token: $qrToken',
        name: 'SupabaseCustomerQrRepository',
      );

      final response = await _client.rpc(
        'resolve_qr',
        params: {'p_qr_token': qrToken},
      );

      developer.log(
        'SupabaseCustomerQrRepository: resolve_qr response: $response',
        name: 'SupabaseCustomerQrRepository',
      );

      if (response is Map<String, dynamic>) {
        final ok = response['ok'] as bool? ?? false;
        if (!ok) {
          final errMap = response['error'] as Map<String, dynamic>?;
          final codeStr = errMap?['code'] as String? ?? 'INVALID_QR';
          final message =
              errMap?['message'] as String? ?? 'This QR code is not valid.';
          throw ErrorMapper.fromApiError(code: codeStr, message: message);
        }

        final data = response['data'] as Map<String, dynamic>;
        return QrContext.fromJson(data);
      }

      throw ServerException(
        message: 'Invalid response from resolve_qr RPC.',
        code: ErrorCode.serverError,
      );
    } catch (e, st) {
      developer.log(
        'SupabaseCustomerQrRepository: Caught error during resolveQr: $e',
        name: 'SupabaseCustomerQrRepository',
        error: e,
        stackTrace: st,
      );
      if (e is AppException) rethrow;
      throw ErrorMapper.map(e, st);
    }
  }
}
