import 'package:get/get.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../core/services/merchant_context_service.dart';
import '../../../data/repositories/table_repository.dart';

class QrController extends GetxController {
  final TableRepository _tableRepo;
  final MerchantContextService _contextService;

  QrController({
    required TableRepository tableRepo,
    required MerchantContextService contextService,
  }) : _tableRepo = tableRepo,
       _contextService = contextService;

  final Rxn<DiningTableModel> table = Rxn<DiningTableModel>();
  final RxBool isLoading = false.obs;
  final RxBool isRotating = false.obs;
  final RxString errorMessage = ''.obs;

  String? get restaurantName => _contextService.restaurantName;
  String? get branchName => _contextService.branchName;

  String get qrUrl {
    final token = table.value?.qrToken ?? '';
    if (token.isEmpty) return '';
    final baseUrl = AppConfig.current.orderBaseUrl.replaceAll(
      RegExp(r'/+$'),
      '',
    );
    return '$baseUrl/q/$token';
  }

  @override
  void onInit() {
    super.onInit();
    final tableId = Get.parameters['id'];
    if (tableId != null && tableId.isNotEmpty) {
      loadTable(tableId);
    } else {
      errorMessage.value = 'No table specified.';
    }
  }

  Future<void> loadTable(String tableId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final t = await _tableRepo.getTableById(tableId);
      table.value = t;
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rotateQr() async {
    final currentTable = table.value;
    if (currentTable == null) return;

    try {
      isRotating.value = true;
      errorMessage.value = '';

      // Calls trusted backend RPC rotate_table_qr
      final result = await _tableRepo.rotateTableQr(currentTable.id);

      table.value = currentTable.copyWith(qrToken: result.qrToken);

      Get.snackbar(
        'QR Code Rotated',
        'A new secure QR token has been generated. Previous printed codes will no longer work.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      final appError = ErrorMapper.map(e);
      errorMessage.value = appError.message;
      Get.snackbar('Rotation Failed', appError.message);
    } finally {
      isRotating.value = false;
    }
  }
}
