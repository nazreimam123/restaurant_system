import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_core/app_core.dart';

/// Long-lived service managing the Supabase client lifecycle.
///
/// NOTE (AGENTS.md rule 12 & 29):
/// Flutter clients may only receive Supabase URL and the publishable/client anonKey.
/// Under NO circumstances should service_role or payment secret keys be used here.
class SupabaseService extends GetxService {
  final AppConfig config;
  bool _isInitialized = false;

  SupabaseService({AppConfig? config})
    : config = config ?? AppConfig.fromEnvironment(appName: 'Customer App');

  bool get isInitialized => _isInitialized;

  SupabaseClient? get clientOrNull =>
      _isInitialized ? Supabase.instance.client : null;

  /// Returns the authenticated or anonymous Supabase client.
  /// Throws [StateError] if Supabase failed to initialize.
  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'SupabaseService has not been initialized. Ensure valid Supabase credentials in AppConfig.',
      );
    }
    return Supabase.instance.client;
  }

  Future<SupabaseService> init() async {
    if (!config.isConfigured) {
      developer.log(
        'SupabaseService: Supabase credentials are missing or empty. '
        'Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
        name: 'SupabaseService',
      );
      return this;
    }

    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: config.supabaseAnonKey,
      );
      _isInitialized = true;
      developer.log(
        'SupabaseService: Successfully initialized Supabase client (${config.environment.name}).',
        name: 'SupabaseService',
      );
    } catch (e, st) {
      developer.log(
        'SupabaseService: Error initializing Supabase client: $e',
        name: 'SupabaseService',
        error: e,
        stackTrace: st,
      );
    }

    return this;
  }
}
