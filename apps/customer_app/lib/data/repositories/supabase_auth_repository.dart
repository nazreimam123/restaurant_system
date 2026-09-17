import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_core/app_core.dart';
import '../../core/services/supabase_service.dart';
import 'auth_repository.dart';

/// Supabase implementation of customer [AuthRepository].
///
/// Ensures an authenticated anonymous session via Supabase Auth without forcing registration.
/// Raw transport and auth errors are cleanly mapped to [AppException].
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseService _supabaseService;

  SupabaseAuthRepository({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  @override
  String? get currentUserId {
    if (!_supabaseService.isInitialized) return null;
    return _client.auth.currentUser?.id;
  }

  @override
  bool get hasSession {
    if (!_supabaseService.isInitialized) return false;
    return _client.auth.currentSession != null;
  }

  @override
  Stream<String?> get authStateChanges {
    if (!_supabaseService.isInitialized) {
      return const Stream.empty();
    }
    return _client.auth.onAuthStateChange.map((event) {
      return event.session?.user.id;
    });
  }

  @override
  Future<String> ensureAnonymousSession() async {
    if (!_supabaseService.isInitialized) {
      throw const NetworkException(
        message: 'Backend service is not configured. Please verify connection.',
      );
    }

    try {
      final existingUser = _client.auth.currentUser;
      if (existingUser != null && _client.auth.currentSession != null) {
        return existingUser.id;
      }

      final response = await _client.auth.signInAnonymously();
      final user = response.user;
      if (user == null) {
        throw const AppAuthException(
          message: 'Failed to establish anonymous session.',
        );
      }
      return user.id;
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  @override
  Future<void> signOut() async {
    if (!_supabaseService.isInitialized) return;
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}
