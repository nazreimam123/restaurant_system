/// Contract for merchant authentication operations.
///
/// NOTE (AGENTS.md & Part I):
/// Merchant staff authenticate using Supabase email/password.
/// Roles are strictly determined by public.restaurant_members and validated server-side.
abstract class AdminAuthRepository {
  /// Returns the current authenticated user ID if an active session exists.
  String? get currentUserId;

  /// Returns the current user's email if available.
  String? get currentUserEmail;

  /// Whether there is an active authenticated merchant session.
  bool get hasSession;

  /// Signs in using email and password credentials.
  Future<String> signIn(String email, String password);

  /// Signs out of the current merchant session.
  Future<void> signOut();

  /// Listens to merchant auth state changes.
  Stream<String?> get authStateChanges;
}
