/// Contract for customer authentication operations.
///
/// NOTE (AGENTS.md rule 7 & 11):
/// The customer application uses Supabase anonymous authentication.
/// Customer users are never forced to register before ordering.
abstract class AuthRepository {
  /// Returns the current authenticated user ID if an active session exists.
  String? get currentUserId;

  /// Whether there is an active authenticated (anonymous or registered) session.
  bool get hasSession;

  /// Ensures an active anonymous session exists. If already authenticated, returns current user ID.
  Future<String> ensureAnonymousSession();

  /// Listens to auth state changes (emits user ID on auth, null on sign out).
  Stream<String?> get authStateChanges;

  /// Signs out of the current session.
  Future<void> signOut();
}
