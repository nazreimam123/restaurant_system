import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/category_repository.dart';
import 'category_controller.dart';

class CategoryFormController extends GetxController {
  final CategoryRepository _categoryRepo;
  final MerchantContextService _contextService;

  CategoryFormController({
    required CategoryRepository categoryRepo,
    required MerchantContextService contextService,
  }) : _categoryRepo = categoryRepo,
       _contextService = contextService;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final imagePathController = TextEditingController();

  final RxBool isActive = true.obs;
  final RxInt sortOrder = 0.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingData = false.obs;
  final RxString errorMessage = ''.obs;

  String? categoryId;
  bool get isEditMode => categoryId != null && categoryId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final paramId = Get.parameters['id'];
    if (paramId != null && paramId.isNotEmpty) {
      categoryId = paramId;
      _loadCategory(paramId);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    imagePathController.dispose();
    super.onClose();
  }

  Future<void> _loadCategory(String id) async {
    try {
      isLoadingData.value = true;
      errorMessage.value = '';
      final category = await _categoryRepo.getCategoryById(id);
      nameController.text = category.name;
      descriptionController.text = category.description ?? '';
      imagePathController.text = category.imagePath ?? '';
      isActive.value = category.isActive;
      sortOrder.value = category.sortOrder;
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoadingData.value = false;
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) {
      Get.snackbar('Error', 'No active restaurant selected.');
      return;
    }

    try {
      isSubmitting.value = true;
      errorMessage.value = '';

      if (isEditMode) {
        final request = UpdateCategoryRequest(
          categoryId: categoryId!,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          imagePath: imagePathController.text.trim().isEmpty
              ? null
              : imagePathController.text.trim(),
          sortOrder: sortOrder.value,
          isActive: isActive.value,
        );
        await _categoryRepo.updateCategory(request);
      } else {
        final request = CreateCategoryRequest(
          restaurantId: restaurantId,
          branchId: _contextService.branchId,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          imagePath: imagePathController.text.trim().isEmpty
              ? null
              : imagePathController.text.trim(),
          sortOrder: sortOrder.value,
          isActive: isActive.value,
        );
        await _categoryRepo.createCategory(request);
      }

      // Refresh list if controller is registered
      if (Get.isRegistered<CategoryController>()) {
        Get.find<CategoryController>().loadCategories();
      }

      Get.back();
      Get.snackbar(
        'Success',
        isEditMode
            ? 'Category updated successfully'
            : 'Category created successfully',
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
