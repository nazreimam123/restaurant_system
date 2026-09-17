import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/modifier_repository.dart';
import 'modifier_controller.dart';

class ModifierOptionFormItem {
  final String? id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final RxBool isAvailable;
  final RxBool isActive;

  ModifierOptionFormItem({
    this.id,
    String initialName = '',
    String initialPrice = '0.00',
    bool initialAvailable = true,
    bool initialActive = true,
  }) : nameController = TextEditingController(text: initialName),
       priceController = TextEditingController(text: initialPrice),
       isAvailable = RxBool(initialAvailable),
       isActive = RxBool(initialActive);

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class ModifierFormController extends GetxController {
  final ModifierRepository _modifierRepo;
  final MerchantContextService _contextService;

  ModifierFormController({
    required ModifierRepository modifierRepo,
    required MerchantContextService contextService,
  }) : _modifierRepo = modifierRepo,
       _contextService = contextService;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  final RxBool isRequired = false.obs;
  final RxInt minSelect = 0.obs;
  final RxInt maxSelect = 1.obs;
  final RxBool isActive = true.obs;
  final RxInt sortOrder = 0.obs;

  final RxList<ModifierOptionFormItem> options = <ModifierOptionFormItem>[].obs;

  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingData = false.obs;
  final RxString errorMessage = ''.obs;

  String? groupId;
  bool get isEditMode => groupId != null && groupId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final paramId = Get.parameters['id'];
    if (paramId != null && paramId.isNotEmpty) {
      groupId = paramId;
      _loadGroup(paramId);
    } else {
      // Add one default empty option for convenience
      addOption();
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    for (final opt in options) {
      opt.dispose();
    }
    super.onClose();
  }

  void addOption() {
    options.add(ModifierOptionFormItem());
  }

  void removeOption(int index) {
    if (options.length > 1) {
      final removed = options.removeAt(index);
      removed.dispose();
    } else {
      Get.snackbar('Notice', 'At least one option is required.');
    }
  }

  Future<void> _loadGroup(String id) async {
    try {
      isLoadingData.value = true;
      errorMessage.value = '';
      final group = await _modifierRepo.getModifierGroupById(id);

      nameController.text = group.name;
      isRequired.value = group.isRequired;
      minSelect.value = group.minSelect;
      maxSelect.value = group.maxSelect;
      isActive.value = group.isActive;
      sortOrder.value = group.sortOrder;

      // Clear existing default options
      for (final opt in options) {
        opt.dispose();
      }
      options.clear();

      if (group.modifiers.isEmpty) {
        addOption();
      } else {
        for (final m in group.modifiers) {
          final priceFormatted = (m.priceDeltaMinor / 100.0).toStringAsFixed(2);
          options.add(
            ModifierOptionFormItem(
              id: m.id,
              initialName: m.name,
              initialPrice: priceFormatted,
              initialAvailable: m.isAvailable,
              initialActive: m.isActive,
            ),
          );
        }
      }
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoadingData.value = false;
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    // Validation rules:
    if (maxSelect.value < minSelect.value) {
      Get.snackbar(
        'Validation Error',
        'Max select must be greater than or equal to Min select.',
      );
      return;
    }

    if (isRequired.value && minSelect.value < 1) {
      Get.snackbar(
        'Validation Error',
        'When a group is required, Min select must be at least 1.',
      );
      return;
    }

    if (options.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please add at least one modifier option.',
      );
      return;
    }

    // Validate options
    final List<CreateModifierOptionDraft> optionDrafts = [];
    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final optName = opt.nameController.text.trim();
      if (optName.isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Option #${i + 1} name cannot be empty.',
        );
        return;
      }

      final parsedPrice =
          double.tryParse(opt.priceController.text.trim()) ?? 0.0;
      if (parsedPrice < 0) {
        Get.snackbar(
          'Validation Error',
          'Option #${i + 1} price delta cannot be negative.',
        );
        return;
      }
      final priceDeltaMinor = (parsedPrice * 100).round();

      optionDrafts.add(
        CreateModifierOptionDraft(
          id: opt.id,
          name: optName,
          priceDeltaMinor: priceDeltaMinor,
          sortOrder: i * 10,
          isAvailable: opt.isAvailable.value,
          isActive: opt.isActive.value,
        ),
      );
    }

    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) {
      Get.snackbar('Error', 'No active restaurant selected.');
      return;
    }

    try {
      isSubmitting.value = true;
      errorMessage.value = '';

      if (isEditMode) {
        final request = UpdateModifierGroupRequest(
          groupId: groupId!,
          name: nameController.text.trim(),
          minSelect: minSelect.value,
          maxSelect: maxSelect.value,
          isRequired: isRequired.value,
          sortOrder: sortOrder.value,
          isActive: isActive.value,
          options: optionDrafts,
        );
        await _modifierRepo.updateModifierGroup(
          request: request,
          restaurantId: restaurantId,
        );
      } else {
        final request = CreateModifierGroupRequest(
          restaurantId: restaurantId,
          name: nameController.text.trim(),
          minSelect: minSelect.value,
          maxSelect: maxSelect.value,
          isRequired: isRequired.value,
          sortOrder: sortOrder.value,
          isActive: isActive.value,
          options: optionDrafts,
        );
        await _modifierRepo.createModifierGroup(request);
      }

      if (Get.isRegistered<ModifierController>()) {
        Get.find<ModifierController>().loadModifierGroups();
      }

      Get.back();
      Get.snackbar(
        'Success',
        isEditMode
            ? 'Modifier group updated successfully'
            : 'Modifier group created successfully',
      );
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
      Get.snackbar('Error', appError.message);
    } finally {
      isSubmitting.value = false;
    }
  }
}
