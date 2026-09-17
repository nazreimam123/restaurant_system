import 'package:app_models/app_models.dart';

abstract class ProductRepository {
  Future<List<AdminProductModel>> getProducts({
    required String restaurantId,
    String? branchId,
    String? categoryId,
    String? search,
  });

  Future<AdminProductModel> getProductById(String productId);

  Future<AdminProductModel> createProduct(CreateProductRequest request);

  Future<AdminProductModel> updateProduct({
    required UpdateProductRequest request,
    required String restaurantId,
  });

  Future<void> toggleProductAvailability({
    required String productId,
    required bool isAvailable,
  });

  Future<void> toggleProductActive({
    required String productId,
    required bool isActive,
  });

  Future<void> deleteProduct(String productId);
}
