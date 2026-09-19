import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';
import '../../../core/services/restaurant_context_service.dart';
import '../../../data/repositories/customer_menu_repository.dart';
import '../../menu/controllers/menu_controller.dart' as menu_ctrl;

class ProductDetailController extends GetxController {
  final CustomerMenuRepository _menuRepository =
      Get.find<CustomerMenuRepository>();
  final RestaurantContextService contextService =
      Get.find<RestaurantContextService>();

  final Rxn<ProductModel> product = Rxn<ProductModel>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final RxInt quantity = 1.obs;
  final RxMap<String, Set<String>> selectedModifiers =
      <String, Set<String>>{}.obs;
  final TextEditingController notesController = TextEditingController();

  String? productId;

  String get currencyCode => contextService.currencyCode;

  @override
  void onInit() {
    super.onInit();
    productId = Get.parameters['id'];
    final argProduct = Get.arguments;

    if (argProduct is ProductModel) {
      _initProduct(argProduct);
    } else {
      _loadProduct();
    }
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  void _initProduct(ProductModel prod) {
    product.value = prod;
    isLoading.value = false;

    // Auto-select single required options by default for smoother UX
    for (final group in prod.modifierGroups) {
      if (group.isRequired &&
          group.minSelect == 1 &&
          group.maxSelect == 1 &&
          group.modifiers.isNotEmpty) {
        final available = group.modifiers.firstWhereOrNull(
          (m) => m.isAvailable,
        );
        if (available != null) {
          selectedModifiers[group.id] = {available.id};
        }
      } else {
        selectedModifiers[group.id] = <String>{};
      }
    }
  }

  Future<void> _loadProduct() async {
    final id = productId;
    if (id == null) {
      errorMessage.value = 'Product ID missing.';
      isLoading.value = false;
      return;
    }

    // Try finding in MenuController first
    if (Get.isRegistered<menu_ctrl.MenuController>()) {
      final menuController = Get.find<menu_ctrl.MenuController>();
      final found = menuController.findProductById(id);
      if (found != null) {
        _initProduct(found);
        return;
      }
    }

    // Otherwise fetch public menu for active branch
    final branchId = contextService.branchId;
    if (branchId == null) {
      errorMessage.value = 'Branch context missing.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final menu = await _menuRepository.getPublicMenu(branchId);
      ProductModel? found;
      for (final cat in menu.categories) {
        for (final p in cat.products) {
          if (p.id == id) {
            found = p;
            break;
          }
        }
        if (found != null) break;
      }

      if (found != null) {
        _initProduct(found);
      } else {
        errorMessage.value = 'This item is no longer available on the menu.';
      }
    } catch (e, st) {
      developer.log(
        'ProductDetailController: Failed to fetch product: $e',
        name: 'ProductDetailController',
        error: e,
        stackTrace: st,
      );
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isLoading.value = false;
    }
  }

  void toggleModifier(ModifierGroupModel group, ModifierModel modifier) {
    if (!modifier.isAvailable) return;

    final currentSet = Set<String>.from(selectedModifiers[group.id] ?? {});

    if (group.maxSelect == 1) {
      if (currentSet.contains(modifier.id)) {
        if (!group.isRequired) {
          currentSet.remove(modifier.id);
        }
      } else {
        currentSet.clear();
        currentSet.add(modifier.id);
      }
    } else {
      if (currentSet.contains(modifier.id)) {
        currentSet.remove(modifier.id);
      } else {
        if (currentSet.length < group.maxSelect) {
          currentSet.add(modifier.id);
        } else {
          Get.snackbar(
            'Limit Reached',
            'You can select at most ${group.maxSelect} options for ${group.name}.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(AppSpacing.md),
          );
          return;
        }
      }
    }

    selectedModifiers[group.id] = currentSet;
  }

  bool isModifierSelected(String groupId, String modifierId) {
    final set = selectedModifiers[groupId];
    return set != null && set.contains(modifierId);
  }

  String? groupValidationError(ModifierGroupModel group) {
    final count = (selectedModifiers[group.id] ?? {}).length;
    if (count < group.minSelect) {
      if (group.minSelect == 1 && group.maxSelect == 1) {
        return 'Please choose 1 option.';
      }
      return 'Please choose at least ${group.minSelect} option(s).';
    }
    if (count > group.maxSelect) {
      return 'Please choose at most ${group.maxSelect} option(s).';
    }
    return null;
  }

  bool get isValid {
    final prod = product.value;
    if (prod == null || !prod.isAvailable) return false;

    for (final group in prod.modifierGroups) {
      if (groupValidationError(group) != null) {
        return false;
      }
    }
    return true;
  }

  /// Strict integer minor calculation: (base + sum(modifiers))
  int get unitPriceMinor {
    final prod = product.value;
    if (prod == null) return 0;

    var total = prod.basePriceMinor;

    for (final group in prod.modifierGroups) {
      final selectedIds = selectedModifiers[group.id];
      if (selectedIds != null && selectedIds.isNotEmpty) {
        for (final mod in group.modifiers) {
          if (selectedIds.contains(mod.id)) {
            total += mod.priceDeltaMinor;
          }
        }
      }
    }

    return total;
  }

  /// Strict integer minor calculation: unitPriceMinor * quantity
  int get totalPriceMinor {
    return unitPriceMinor * quantity.value;
  }

  void incrementQuantity() {
    quantity.value++;
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }
  

  void onAddToCartTapped() {
    final prod = product.value;
    if (prod == null) return;

    if (!isValid) {
      for (final group in prod.modifierGroups) {
        final err = groupValidationError(group);
        if (err != null) {
          Get.snackbar(
            group.name,
            err,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.danger.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(AppSpacing.md),
          );
          return;
        }
      }
      return;
    }

    // Phase 7 scope boundary: Cart & Checkout are Phase 8.
    Get.snackbar(
      'Product Configured',
      '${prod.name} (x${quantity.value}) configured • ${CurrencyFormatter.format(totalPriceMinor, currencyCode: currencyCode)}.\n(Cart & Checkout arrive in Phase 8)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(AppSpacing.md),
    );

    Get.back();
  }
}
