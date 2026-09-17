import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/category_repository.dart';

class CategoryController extends GetxController {
  final CategoryRepository _categoryRepo;
  final MerchantContextService _contextService;

  CategoryController({
    required CategoryRepository categoryRepo,
    required MerchantContextService contextService,
  }) : _categoryRepo = categoryRepo,
       _contextService = contextService;

  final RxList<AdminCategoryModel> categories = <AdminCategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  List<AdminCategoryModel> get filteredCategories {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return categories;
    return categories
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              (c.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) {
      errorMessage.value = 'No active restaurant context.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _categoryRepo.getCategories(
        restaurantId: restaurantId,
        branchId: _contextService.branchId,
      );
      categories.assignAll(result);
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleActive(AdminCategoryModel category) async {
    final newStatus = !category.isActive;
    try {
      await _categoryRepo.toggleCategoryActive(
        categoryId: category.id,
        isActive: newStatus,
      );
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category.copyWith(isActive: newStatus);
      }
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }

  Future<void> onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = categories.removeAt(oldIndex);
    categories.insert(newIndex, item);

    try {
      final ids = categories.map((c) => c.id).toList();
      await _categoryRepo.reorderCategories(ids);
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', 'Failed to save reorder: ${appError.message}');
      await loadCategories(); // rollback
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoryRepo.deleteCategory(categoryId);
      categories.removeWhere((c) => c.id == categoryId);
      Get.snackbar('Success', 'Category deleted successfully');
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }
}
