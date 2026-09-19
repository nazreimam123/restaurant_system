import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/restaurant_context_service.dart';
import '../../../data/repositories/customer_menu_repository.dart';

class MenuController extends GetxController {
  final CustomerMenuRepository _menuRepository =
      Get.find<CustomerMenuRepository>();
  final RestaurantContextService contextService =
      Get.find<RestaurantContextService>();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<RestaurantMenu> menu = Rxn<RestaurantMenu>();

  final RxnString selectedCategoryId = RxnString();
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadMenu();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadMenu() async {
    final branchId = contextService.branchId;
    if (branchId == null) {
      developer.log(
        'MenuController: No branchId found in context. Routing to QR scan.',
        name: 'MenuController',
      );
      Get.offNamed(AppRoutes.scan);
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      developer.log(
        'MenuController: Fetching public menu for branch: $branchId',
        name: 'MenuController',
      );

      final result = await _menuRepository.getPublicMenu(branchId);
      menu.value = result;

      // Select first category by default if available
      if (selectedCategoryId.value == null && result.categories.isNotEmpty) {
        selectedCategoryId.value = result.categories.first.id;
      }
    } catch (e, st) {
      developer.log(
        'MenuController: Failed to load menu: $e',
        name: 'MenuController',
        error: e,
        stackTrace: st,
      );
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query.trim().toLowerCase();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  /// Filtered list of products matching the selected category and search query.
  List<ProductModel> get displayedProducts {
    final currentMenu = menu.value;
    if (currentMenu == null) return [];

    final query = searchQuery.value;
    final catId = selectedCategoryId.value;

    // 1. Filter by category
    List<ProductModel> products = [];
    if (catId == null || catId == 'all') {
      for (final cat in currentMenu.categories) {
        products.addAll(cat.products);
      }
    } else {
      final category = currentMenu.categories.firstWhereOrNull(
        (c) => c.id == catId,
      );
      if (category != null) {
        products.addAll(category.products);
      }
    }

    // 2. Filter by search query
    if (query.isNotEmpty) {
      products = products.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final descMatch = (p.description ?? '').toLowerCase().contains(query);
        final tagMatch = p.tags.any((t) => t.toLowerCase().contains(query));
        return nameMatch || descMatch || tagMatch;
      }).toList();
    }

    return products;
  }

  void onProductTapped(ProductModel product) {
    Get.toNamed('/product/${product.id}', arguments: product);
  }

  void changeTable() {
    Get.defaultDialog(
      title: 'Switch Table',
      middleText: 'Do you want to scan a different table QR code?',
      textConfirm: 'Scan New QR',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        Get.toNamed(AppRoutes.scan);
      },
    );
  }

  ProductModel? findProductById(String id) {
    final currentMenu = menu.value;
    if (currentMenu == null) return null;
    for (final cat in currentMenu.categories) {
      for (final prod in cat.products) {
        if (prod.id == id) return prod;
      }
    }
    return null;
  }
}
