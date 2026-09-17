import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/modifier_repository.dart';

class ModifierController extends GetxController {
  final ModifierRepository _modifierRepo;
  final MerchantContextService _contextService;

  ModifierController({
    required ModifierRepository modifierRepo,
    required MerchantContextService contextService,
  }) : _modifierRepo = modifierRepo,
       _contextService = contextService;

  final RxList<AdminModifierGroupModel> groups =
      <AdminModifierGroupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadModifierGroups();
  }

  Future<void> loadModifierGroups() async {
    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) {
      errorMessage.value = 'No active restaurant context.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _modifierRepo.getModifierGroups(restaurantId);
      groups.assignAll(result);
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleGroupActive(AdminModifierGroupModel group) async {
    final newStatus = !group.isActive;
    try {
      await _modifierRepo.toggleModifierGroupActive(
        groupId: group.id,
        isActive: newStatus,
      );
      final index = groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        groups[index] = group.copyWith(isActive: newStatus);
      }
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _modifierRepo.deleteModifierGroup(groupId);
      groups.removeWhere((g) => g.id == groupId);
      Get.snackbar('Success', 'Modifier group deleted successfully');
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }
}
