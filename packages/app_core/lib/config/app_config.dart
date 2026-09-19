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
  final String orderBaseUrl;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.appName,
    this.apiBaseUrl = '',
    this.orderBaseUrl = 'https://order.example.com',
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
    const envSupabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: '',
    );
    const envApiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    const envOrderBaseUrl = String.fromEnvironment(
      'ORDER_BASE_URL',
      defaultValue: 'https://order.example.com',
    );

    var resolvedUrl = envSupabaseUrl;
    var resolvedAnonKey = envSupabaseAnonKey.isNotEmpty
        ? envSupabaseAnonKey
        : envSupabasePublishableKey;

    // In development mode, fallback to linked development project credentials if not passed via flags
    if (activeEnv.isDevelopment &&
        (resolvedUrl.isEmpty || resolvedAnonKey.isEmpty)) {
      resolvedUrl = 'https://gizipwqdumsmiarsauig.supabase.co';
      resolvedAnonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdpemlwd3FkdW1zbWlhcnNhdWlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1OTkyMjgsImV4cCI6MjEwNTE3NTIyOH0.pdpXHHkcHGbN0f1e-zLtw01zkMr0GEWtnbWWpt5ZTU4';
    }

    if (activeEnv.isProduction) {
      if (resolvedUrl.isEmpty || resolvedAnonKey.isEmpty) {
        throw StateError(
          'Production build requires SUPABASE_URL and SUPABASE_ANON_KEY (or SUPABASE_PUBLISHABLE_KEY) passed via --dart-define or file.',
        );
      }
    }

    final config = AppConfig(
      environment: activeEnv,
      supabaseUrl: resolvedUrl,
      supabaseAnonKey: resolvedAnonKey,
      appName:
          appName ??
          (activeEnv.isProduction
              ? 'Restaurant Ordering'
              : 'Restaurant Ordering (${activeEnv.name})'),
      apiBaseUrl: envApiBaseUrl,
      orderBaseUrl: envOrderBaseUrl,
    );
    _current = config;
    return config;
  }

  static AppConfig? _current;
  static AppConfig get current => _current ??= AppConfig.fromEnvironment();
  static set current(AppConfig config) => _current = config;

  bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Client-safe publishable key alias for [supabaseAnonKey]
  String get supabasePublishableKey => supabaseAnonKey;

  @override
  String toString() =>
      'AppConfig(env: ${environment.name}, url: $supabaseUrl, configured: $isConfigured)';
}
