import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';

class ProductController extends GetxController {
  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;
  final MerchantContextService _contextService;

  ProductController({
    required ProductRepository productRepo,
    required CategoryRepository categoryRepo,
    required MerchantContextService contextService,
  }) : _productRepo = productRepo,
       _categoryRepo = categoryRepo,
       _contextService = contextService;

  final RxList<AdminProductModel> products = <AdminProductModel>[].obs;
  final RxList<AdminCategoryModel> categories = <AdminCategoryModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString selectedCategoryId = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxnBool filterVeg = RxnBool();

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  List<AdminProductModel> get filteredProducts {
    var list = products.toList();

    if (selectedCategoryId.isNotEmpty) {
      list = list
          .where((p) => p.categoryId == selectedCategoryId.value)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.description?.toLowerCase().contains(q) ?? false) ||
                (p.sku?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    if (filterVeg.value != null) {
      list = list.where((p) => p.isVeg == filterVeg.value).toList();
    }

    return list;
  }

  Future<void> loadInitialData() async {
    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) {
      errorMessage.value = 'No active restaurant context.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final catsFuture = _categoryRepo.getCategories(
        restaurantId: restaurantId,
        branchId: _contextService.branchId,
      );
      final prodsFuture = _productRepo.getProducts(
        restaurantId: restaurantId,
        branchId: _contextService.branchId,
      );

      final results = await Future.wait([catsFuture, prodsFuture]);
      categories.assignAll(results[0] as List<AdminCategoryModel>);
      products.assignAll(results[1] as List<AdminProductModel>);
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadProducts() async {
    final restaurantId = _contextService.restaurantId;
    if (restaurantId == null) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _productRepo.getProducts(
        restaurantId: restaurantId,
        branchId: _contextService.branchId,
      );
      products.assignAll(result);
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleAvailability(AdminProductModel product) async {
    final newAvailability = !product.isAvailable;
    try {
      await _productRepo.toggleProductAvailability(
        productId: product.id,
        isAvailable: newAvailability,
      );
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = product.copyWith(isAvailable: newAvailability);
      }
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }

  Future<void> toggleActive(AdminProductModel product) async {
    final newActive = !product.isActive;
    try {
      await _productRepo.toggleProductActive(
        productId: product.id,
        isActive: newActive,
      );
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = product.copyWith(isActive: newActive);
      }
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productRepo.deleteProduct(productId);
      products.removeWhere((p) => p.id == productId);
      Get.snackbar('Success', 'Product deleted successfully');
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }
}
