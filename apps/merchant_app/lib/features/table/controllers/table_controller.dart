import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/table_repository.dart';

class TableController extends GetxController {
  final TableRepository _tableRepo;
  final MerchantContextService _contextService;

  TableController({
    required TableRepository tableRepo,
    required MerchantContextService contextService,
  }) : _tableRepo = tableRepo,
       _contextService = contextService;

  final RxList<DiningTableModel> tables = <DiningTableModel>[].obs;
  final RxList<DiningAreaModel> areas = <DiningAreaModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedAreaId = ''.obs;

  List<DiningTableModel> get filteredTables {
    if (selectedAreaId.isEmpty) return tables;
    return tables.where((t) => t.diningAreaId == selectedAreaId.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadTables();
  }

  Future<void> loadTables() async {
    final restaurantId = _contextService.restaurantId;
    final branchId = _contextService.branchId;
    if (restaurantId == null || branchId == null) {
      errorMessage.value = 'Please select a restaurant and branch first.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final areasFuture = _tableRepo.getDiningAreas(
        restaurantId: restaurantId,
        branchId: branchId,
      );
      final tablesFuture = _tableRepo.getTables(
        restaurantId: restaurantId,
        branchId: branchId,
      );

      final results = await Future.wait([areasFuture, tablesFuture]);
      areas.assignAll(results[0] as List<DiningAreaModel>);
      tables.assignAll(results[1] as List<DiningTableModel>);
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleTableActive(DiningTableModel table) async {
    final newActive = !table.isActive;
    try {
      await _tableRepo.toggleTableActive(
        tableId: table.id,
        isActive: newActive,
      );
      final index = tables.indexWhere((t) => t.id == table.id);
      if (index != -1) {
        tables[index] = table.copyWith(isActive: newActive);
      }
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }

  Future<void> deleteTable(String tableId) async {
    try {
      await _tableRepo.deleteTable(tableId);
      tables.removeWhere((t) => t.id == tableId);
      Get.snackbar('Success', 'Table deleted successfully');
    } catch (e) {
      final appError = ErrorMapper.map(e);
      Get.snackbar('Error', appError.message);
    }
  }

  Future<void> createAreaDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final isCreating = false.obs;

    await Get.dialog(
      AlertDialog(
        title: const Text('Add Dining Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create a section to group tables (e.g. Patio, Rooftop, Indoor).',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Area Name *',
                hintText: 'e.g. Ground Floor, Balcony',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(
            () => ElevatedButton(
              onPressed: isCreating.value
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      try {
                        isCreating.value = true;
                        final newArea = await _tableRepo.createDiningArea(
                          restaurantId: _contextService.restaurantId!,
                          branchId: _contextService.branchId!,
                          name: name,
                          sortOrder: areas.length * 10,
                        );
                        areas.add(newArea);
                        Get.back();
                        Get.snackbar('Success', 'Area "$name" added.');
                      } catch (e) {
                        final err = ErrorMapper.map(e);
                        Get.snackbar('Error', err.message);
                      } finally {
                        isCreating.value = false;
                      }
                    },
              child: isCreating.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}
