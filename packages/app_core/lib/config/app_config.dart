import 'package:meta/meta.dart';
import 'app_environment.dart';

/// Immutable environment and client-safe runtime configuration.
///
/// NOTE:
/// In accordance with the security architecture (AGENTS.md rule 12):
/// Flutter clients may ONLY receive client-safe configuration:
/// - [supabaseUrl]
/// - [supabaseAnonKey] (publishable anonymous/client key)
///
/// Under NO CIRCUMSTANCES should service_role keys, Supabase secret keys,
/// payment secrets, webhook secrets, or FCM server credentials ever be added here.
@immutable
class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String appName;
  final String apiBaseUrl;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.appName,
    this.apiBaseUrl = '',
  });

  /// Factory loading configuration from environment variables / --dart-define.
  /// Falls back to local development defaults only when running in development mode.
  factory AppConfig.fromEnvironment({
    AppEnvironment? environment,
    String? appName,
  }) {
    const envString = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final activeEnv = environment ?? AppEnvironment.fromString(envString);

    const envSupabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const envSupabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    const envApiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    // In development mode, credentials come from --dart-define or explicit config.
    // If not provided, isConfigured remains false so the app boots in offline/unconfigured mode.
    final resolvedUrl = envSupabaseUrl;
    final resolvedAnonKey = envSupabaseAnonKey;

    if (activeEnv.isProduction) {
      if (resolvedUrl.isEmpty || resolvedAnonKey.isEmpty) {
        throw StateError(
          'Production build requires SUPABASE_URL and SUPABASE_ANON_KEY passed via --dart-define.',
        );
      }
    }

    return AppConfig(
      environment: activeEnv,
      supabaseUrl: resolvedUrl,
      supabaseAnonKey: resolvedAnonKey,
      appName:
          appName ??
          (activeEnv.isProduction
              ? 'Restaurant Ordering'
              : 'Restaurant Ordering (${activeEnv.name})'),
      apiBaseUrl: envApiBaseUrl,
    );
  }

  bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  @override
  String toString() =>
      'AppConfig(env: ${environment.name}, url: $supabaseUrl, configured: $isConfigured)';
}
