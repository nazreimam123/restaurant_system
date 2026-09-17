import 'package:app_models/app_models.dart';

abstract class TableRepository {
  Future<List<DiningAreaModel>> getDiningAreas({
    required String restaurantId,
    required String branchId,
  });

  Future<DiningAreaModel> createDiningArea({
    required String restaurantId,
    required String branchId,
    required String name,
    int sortOrder = 0,
  });

  Future<List<DiningTableModel>> getTables({
    required String restaurantId,
    required String branchId,
    String? diningAreaId,
  });

  Future<DiningTableModel> getTableById(String tableId);

  Future<DiningTableModel> createTable(CreateTableRequest request);

  Future<DiningTableModel> updateTable(UpdateTableRequest request);

  Future<void> toggleTableActive({
    required String tableId,
    required bool isActive,
  });

  Future<void> deleteTable(String tableId);

  /// Rotates table QR using trusted RPC function `rotate_table_qr`.
  /// Never executes direct update on qr_token column.
  Future<QrRotationResult> rotateTableQr(String tableId);
}
