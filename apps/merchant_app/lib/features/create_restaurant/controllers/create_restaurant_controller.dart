import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../app/routes/admin_routes.dart';
import '../../../core/services/admin_session_service.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/merchant_membership_repository.dart';

class CreateRestaurantController extends GetxController {
  final MerchantMembershipRepository _membershipRepo =
      Get.find<MerchantMembershipRepository>();
  final MerchantContextService _contextService =
      Get.find<MerchantContextService>();
  final AdminSessionService _sessionService = Get.find<AdminSessionService>();

  final formKey = GlobalKey<FormState>();

  // Restaurant fields
  final nameController = TextEditingController();
  final slugController = TextEditingController();
  final currencyController = TextEditingController(text: 'INR');
  final timezoneController = TextEditingController(text: 'Asia/Kolkata');

  // Branch fields
  final branchNameController = TextEditingController(text: 'Main Branch');
  final branchCodeController = TextEditingController(text: 'MAIN');
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryCodeController = TextEditingController(text: 'IN');

  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isManualSlug = false.obs;

  static final RegExp _slugRegex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final RegExp _currencyRegex = RegExp(r'^[A-Z]{3}$');
  static final RegExp _countryCodeRegex = RegExp(r'^[A-Z]{2}$');

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (!isManualSlug.value) {
      final generated = generateSlug(nameController.text);
      slugController.text = generated;
    }
  }

  void onSlugUserEdited(String val) {
    isManualSlug.value = val.trim().isNotEmpty;
  }

  static String generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'[\s-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String? validateRestaurantName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Restaurant name is required.';
    }
    return null;
  }

  String? validateSlug(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Slug is required.';
    }
    final trimmed = value.trim().toLowerCase();
    if (!_slugRegex.hasMatch(trimmed)) {
      return 'Slug must only contain lowercase alphanumeric characters and hyphens (e.g. pizza-house).';
    }
    return null;
  }

  String? validateCurrency(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Currency code is required.';
    }
    final trimmed = value.trim().toUpperCase();
    if (!_currencyRegex.hasMatch(trimmed)) {
      return 'Currency must be a 3-letter ISO code (e.g. INR, USD).';
    }
    return null;
  }

  String? validateTimezone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Timezone is required.';
    }
    return null;
  }

  String? validateBranchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Initial branch name is required.';
    }
    return null;
  }

  String? validateCountryCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country code is required.';
    }
    final trimmed = value.trim().toUpperCase();
    if (!_countryCodeRegex.hasMatch(trimmed)) {
      return 'Country code must be 2 uppercase letters (e.g. IN).';
    }
    return null;
  }

  Future<void> submit() async {
    errorMessage.value = null;

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!_sessionService.isAuthenticated.value) {
      errorMessage.value = 'Authentication required. Please sign in again.';
      return;
    }

    isSubmitting.value = true;

    try {
      final request = CreateRestaurantRequest(
        name: nameController.text.trim(),
        slug: slugController.text.trim().toLowerCase(),
        currencyCode: currencyController.text.trim().toUpperCase(),
        timezone: timezoneController.text.trim(),
        branch: CreateBranchInput(
          name: branchNameController.text.trim(),
          code: branchCodeController.text.trim().isNotEmpty
              ? branchCodeController.text.trim()
              : null,
          phone: phoneController.text.trim().isNotEmpty
              ? phoneController.text.trim()
              : null,
          addressLine1: addressController.text.trim().isNotEmpty
              ? addressController.text.trim()
              : null,
          city: cityController.text.trim().isNotEmpty
              ? cityController.text.trim()
              : null,
          state: stateController.text.trim().isNotEmpty
              ? stateController.text.trim()
              : null,
          postalCode: postalCodeController.text.trim().isNotEmpty
              ? postalCodeController.text.trim()
              : null,
          countryCode: countryCodeController.text.trim().toUpperCase(),
        ),
      );

      // 1. Call trusted backend RPC create_restaurant
      final result = await _membershipRepo.createRestaurant(request);
      developer.log(
        'CreateRestaurantController: Restaurant created with ID: ${result.restaurantId}, Branch ID: ${result.branchId}',
        name: 'CreateRestaurantController',
      );

      // 2. Reload validated memberships directly from backend (security rule: do not trust RPC response alone)
      final memberships = await _membershipRepo.loadMemberships();
      final createdMembership = memberships.firstWhereOrNull(
        (m) => m.restaurantId == result.restaurantId,
      );

      final restaurantName = createdMembership?.restaurantName ?? request.name;
      final role = createdMembership?.role ?? result.role;

      // 3. Reload validated accessible branches from backend
      final branches = await _membershipRepo.loadAccessibleBranches(
        restaurantId: result.restaurantId,
        role: role,
      );

      final selectedBranch =
          branches.firstWhereOrNull((b) => b.branchId == result.branchId) ??
          branches.firstOrNull;

      final branchId = selectedBranch?.branchId ?? result.branchId;
      final branchName = selectedBranch?.branchName ?? request.branch.name;

      // 4. Populate MerchantContextService with validated backend state
      _contextService.setContext(
        MerchantContext(
          restaurantId: result.restaurantId,
          restaurantName: restaurantName,
          branchId: branchId,
          branchName: branchName,
          role: role,
        ),
      );

      // 5. Navigate to Dashboard
      Get.offAllNamed(AdminRoutes.dashboard);
    } catch (e, st) {
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    slugController.dispose();
    currencyController.dispose();
    timezoneController.dispose();
    branchNameController.dispose();
    branchCodeController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryCodeController.dispose();
    super.onClose();
  }
}
