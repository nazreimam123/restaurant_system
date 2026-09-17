import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_core/app_core.dart';
import '../../core/services/supabase_service.dart';
import 'admin_auth_repository.dart';

/// Supabase implementation of [AdminAuthRepository] for merchant staff.
class SupabaseAdminAuthRepository implements AdminAuthRepository {
  final SupabaseService _supabaseService;

  SupabaseAdminAuthRepository({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  @override
  String? get currentUserId {
    if (!_supabaseService.isInitialized) return null;
    return _client.auth.currentUser?.id;
  }

  @override
  String? get currentUserEmail {
    if (!_supabaseService.isInitialized) return null;
    return _client.auth.currentUser?.email;
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
  Future<String> signIn(String email, String password) async {
    if (!_supabaseService.isInitialized) {
      throw const NetworkException(
        message: 'Backend service is not configured. Please verify connection.',
      );
    }

    try {
      final trimmedEmail = email.trim();
      final response = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AppAuthException(
          message: 'Invalid credentials. Please check your email and password.',
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
