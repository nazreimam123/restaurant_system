import 'package:app_models/app_models.dart';

abstract class CategoryRepository {
  Future<List<AdminCategoryModel>> getCategories({
    required String restaurantId,
    String? branchId,
  });

  Future<AdminCategoryModel> getCategoryById(String categoryId);

  Future<AdminCategoryModel> createCategory(CreateCategoryRequest request);

  Future<AdminCategoryModel> updateCategory(UpdateCategoryRequest request);

  Future<void> toggleCategoryActive({
    required String categoryId,
    required bool isActive,
  });

  Future<void> reorderCategories(List<String> categoryIdsInOrder);

  Future<void> deleteCategory(String categoryId);
}
