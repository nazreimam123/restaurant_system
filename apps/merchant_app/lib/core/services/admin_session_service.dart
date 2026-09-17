import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../../data/repositories/admin_auth_repository.dart';

/// Long-lived service managing the merchant user session lifecycle.
class AdminSessionService extends GetxService {
  final AdminAuthRepository _authRepository;
  StreamSubscription<String?>? _authSubscription;

  final Rxn<String> currentUserId = Rxn<String>();
  final Rxn<String> currentUserEmail = Rxn<String>();
  final RxBool isAuthenticated = false.obs;

  AdminSessionService({required AdminAuthRepository authRepository})
    : _authRepository = authRepository;

  String? get userId => currentUserId.value;
  String? get email => currentUserEmail.value;

  Future<AdminSessionService> init() async {
    currentUserId.value = _authRepository.currentUserId;
    currentUserEmail.value = _authRepository.currentUserEmail;
    isAuthenticated.value = _authRepository.hasSession;

    _authSubscription = _authRepository.authStateChanges.listen((uid) {
      currentUserId.value = uid;
      currentUserEmail.value = _authRepository.currentUserEmail;
      isAuthenticated.value = uid != null;
      developer.log(
        'AdminSessionService: Merchant auth state changed. UID: $uid',
        name: 'AdminSessionService',
      );
    });

    return this;
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    currentUserId.value = null;
    currentUserEmail.value = null;
    isAuthenticated.value = false;
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
