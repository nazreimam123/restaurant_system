import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';

/// Long-lived service managing the customer user session lifecycle.
///
/// Responsibilities:
/// - Expose current authenticated customer/session
/// - Initialize and restore session state
/// - Ensure anonymous session when required
/// - Observe Supabase auth state changes safely
/// - Expose authenticated user ID
/// - Provide future logout / account-upgrade hooks
///
/// NOTE (AGENTS.md rule 7 & Part E):
/// Navigation logic must NOT be placed inside SessionService.
class SessionService extends GetxService {
  final AuthRepository _authRepository;
  StreamSubscription<String?>? _authSubscription;

  final Rxn<String> currentUserId = Rxn<String>();
  final RxBool isAuthenticated = false.obs;

  SessionService({required AuthRepository authRepository})
    : _authRepository = authRepository;

  String? get userId => currentUserId.value;

  Future<SessionService> init() async {
    // Sync existing session
    currentUserId.value = _authRepository.currentUserId;
    isAuthenticated.value = _authRepository.hasSession;

    // Listen to background auth changes
    _authSubscription = _authRepository.authStateChanges.listen((uid) {
      currentUserId.value = uid;
      isAuthenticated.value = uid != null;
      developer.log(
        'SessionService: Auth state changed. UID: $uid',
        name: 'SessionService',
      );
    });

    return this;
  }

  /// Ensures that a valid anonymous customer session exists.
  Future<String> ensureSession() async {
    final uid = await _authRepository.ensureAnonymousSession();
    currentUserId.value = uid;
    isAuthenticated.value = true;
    return uid;
  }

  /// Hook for future logout or session reset.
  Future<void> signOut() async {
    await _authRepository.signOut();
    currentUserId.value = null;
    isAuthenticated.value = false;
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
