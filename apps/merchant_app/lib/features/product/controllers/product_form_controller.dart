import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/modifier_repository.dart';
import '../../../data/repositories/product_repository.dart';
import 'product_controller.dart';

class ProductFormController extends GetxController {
  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;
  final ModifierRepository _modifierRepo;
  final MerchantContextService _contextService;

  ProductFormController({
    required ProductRepository productRepo,
    required CategoryRepository categoryRepo,
    required ModifierRepository modifierRepo,
    required MerchantContextService contextService,
  }) : _productRepo = productRepo,
       _categoryRepo = categoryRepo,
       _modifierRepo = modifierRepo,
       _contextService = contextService;

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final skuController = TextEditingController();
  final priceController = TextEditingController();
  final imagePathController = TextEditingController();
  final prepMinutesController = TextEditingController();

  final RxString selectedCategoryId = ''.obs;
  final RxnBool isVeg = RxnBool();
  final RxBool isAvailable = true.obs;
  final RxBool isActive = true.obs;
  final RxInt sortOrder = 0.obs;

  final RxList<AdminCategoryModel> categories = <AdminCategoryModel>[].obs;
  final RxList<AdminModifierGroupModel> availableModifierGroups =
      <AdminModifierGroupModel>[].obs;
  final RxSet<String> selectedModifierGroupIds = <String>{}.obs;

  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingData = false.obs;
  final RxString errorMessage = ''.obs;

  String? productId;
  bool get isEditMode => productId != null && productId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final paramId = Get.parameters['id'];
    if (paramId != null && paramId.isNotEmpty) {
      productId = paramId;
    }
    _loadPrerequisites();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    skuController.dispose();
    priceController.dispose();
    imagePathController.dispose();
    prepMinutesController.dispose();
    super.onClose();
  }

  Future<void> _loadPrerequisites() async {
    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) {
      errorMessage.value = 'No active restaurant context.';
      return;
    }

    try {
      isLoadingData.value = true;
      errorMessage.value = '';

      final catsFuture = _categoryRepo.getCategories(
        restaurantId: restaurantId,
        branchId: _contextService.branchId,
      );
      final groupsFuture = _modifierRepo.getModifierGroups(restaurantId);

      final results = await Future.wait([catsFuture, groupsFuture]);
      categories.assignAll(results[0] as List<AdminCategoryModel>);
      availableModifierGroups.assignAll(
        results[1] as List<AdminModifierGroupModel>,
      );

      if (isEditMode) {
        await _loadProduct(productId!);
      } else {
        if (categories.isNotEmpty) {
          selectedCategoryId.value = categories.first.id;
        }
      }
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoadingData.value = false;
    }
  }

  Future<void> _loadProduct(String id) async {
    final product = await _productRepo.getProductById(id);
    nameController.text = product.name;
    descriptionController.text = product.description ?? '';
    skuController.text = product.sku ?? '';
    priceController.text = (product.basePriceMinor / 100.0).toStringAsFixed(2);
    imagePathController.text = product.imagePath ?? '';
    prepMinutesController.text = product.preparationMinutes != null
        ? '${product.preparationMinutes}'
        : '';
    selectedCategoryId.value = product.categoryId;
    isVeg.value = product.isVeg;
    isAvailable.value = product.isAvailable;
    isActive.value = product.isActive;
    sortOrder.value = product.sortOrder;

    selectedModifierGroupIds.assignAll(product.modifierGroupIds);
  }

  void toggleModifierGroup(String groupId) {
    if (selectedModifierGroupIds.contains(groupId)) {
      selectedModifierGroupIds.remove(groupId);
    } else {
      selectedModifierGroupIds.add(groupId);
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedCategoryId.isEmpty) {
      Get.snackbar('Validation Error', 'Please select a menu category.');
      return;
    }

    final priceDouble = double.tryParse(priceController.text.trim()) ?? -1.0;
    if (priceDouble < 0) {
      Get.snackbar(
        'Validation Error',
        'Price must be greater than or equal to 0.',
      );
      return;
    }

    final basePriceMinor = (priceDouble * 100).round();
    final prepMinutes = int.tryParse(prepMinutesController.text.trim());

    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) {
      Get.snackbar('Error', 'No active restaurant selected.');
      return;
    }

    try {
      isSubmitting.value = true;
      errorMessage.value = '';

      if (isEditMode) {
        final request = UpdateProductRequest(
          productId: productId!,
          categoryId: selectedCategoryId.value,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          sku: skuController.text.trim().isEmpty
              ? null
              : skuController.text.trim(),
          basePriceMinor: basePriceMinor,
          imagePath: imagePathController.text.trim().isEmpty
              ? null
              : imagePathController.text.trim(),
          isVeg: isVeg.value,
          isAvailable: isAvailable.value,
          isActive: isActive.value,
          sortOrder: sortOrder.value,
          preparationMinutes: prepMinutes,
          modifierGroupIds: selectedModifierGroupIds.toList(),
        );

        await _productRepo.updateProduct(
          request: request,
          restaurantId: restaurantId,
        );
      } else {
        final request = CreateProductRequest(
          restaurantId: restaurantId,
          branchId: _contextService.branchId,
          categoryId: selectedCategoryId.value,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          sku: skuController.text.trim().isEmpty
              ? null
              : skuController.text.trim(),
          basePriceMinor: basePriceMinor,
          imagePath: imagePathController.text.trim().isEmpty
              ? null
              : imagePathController.text.trim(),
          isVeg: isVeg.value,
          isAvailable: isAvailable.value,
          isActive: isActive.value,
          sortOrder: sortOrder.value,
          preparationMinutes: prepMinutes,
          modifierGroupIds: selectedModifierGroupIds.toList(),
        );

        await _productRepo.createProduct(request);
      }

      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().reloadProducts();
      }

      Get.back();
      Get.snackbar(
        'Success',
        isEditMode
            ? 'Product updated successfully'
            : 'Product created successfully',
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
