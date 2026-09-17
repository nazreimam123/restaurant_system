import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/table_repository.dart';
import 'table_controller.dart';

class TableFormController extends GetxController {
  final TableRepository _tableRepo;
  final MerchantContextService _contextService;

  TableFormController({
    required TableRepository tableRepo,
    required MerchantContextService contextService,
  }) : _tableRepo = tableRepo,
       _contextService = contextService;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final capacityController = TextEditingController();

  final RxnString selectedAreaId = RxnString();
  final RxBool isActive = true.obs;

  final RxList<DiningAreaModel> areas = <DiningAreaModel>[].obs;

  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingData = false.obs;
  final RxString errorMessage = ''.obs;

  String? tableId;
  bool get isEditMode => tableId != null && tableId!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final paramId = Get.parameters['id'];
    if (paramId != null && paramId.isNotEmpty) {
      tableId = paramId;
    }
    _loadInitial();
  }

  @override
  void onClose() {
    nameController.dispose();
    capacityController.dispose();
    super.onClose();
  }

  Future<void> _loadInitial() async {
    final restaurantId = _contextService.restaurantId;
    final branchId = _contextService.branchId;
    if (restaurantId == null || branchId == null) {
      errorMessage.value = 'No active restaurant or branch context.';
      return;
    }

    try {
      isLoadingData.value = true;
      errorMessage.value = '';

      final areaList = await _tableRepo.getDiningAreas(
        restaurantId: restaurantId,
        branchId: branchId,
      );
      areas.assignAll(areaList);

      if (isEditMode) {
        final table = await _tableRepo.getTableById(tableId!);
        nameController.text = table.name;
        capacityController.text = table.capacity != null
            ? '${table.capacity}'
            : '';
        selectedAreaId.value = table.diningAreaId;
        isActive.value = table.isActive;
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

    final restaurantId = _contextService.restaurantId;
    final branchId = _contextService.branchId;
    if (restaurantId == null || branchId == null) {
      Get.snackbar('Error', 'No active restaurant/branch context.');
      return;
    }

    final capacity = int.tryParse(capacityController.text.trim());

    try {
      isSubmitting.value = true;
      errorMessage.value = '';

      if (isEditMode) {
        final request = UpdateTableRequest(
          tableId: tableId!,
          diningAreaId: selectedAreaId.value,
          name: nameController.text.trim(),
          capacity: capacity,
          isActive: isActive.value,
        );
        await _tableRepo.updateTable(request);
      } else {
        // Omits qr_token per spec: DB default generates uuid
        final request = CreateTableRequest(
          restaurantId: restaurantId,
          branchId: branchId,
          diningAreaId: selectedAreaId.value,
          name: nameController.text.trim(),
          capacity: capacity,
          isActive: isActive.value,
        );
        await _tableRepo.createTable(request);
      }

      if (Get.isRegistered<TableController>()) {
        Get.find<TableController>().loadTables();
      }

      Get.back();
      Get.snackbar(
        'Success',
        isEditMode
            ? 'Table updated successfully'
            : 'Table created successfully',
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
