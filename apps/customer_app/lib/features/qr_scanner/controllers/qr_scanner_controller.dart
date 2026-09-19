import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_core/app_core.dart';
import 'package:app_models/app_models.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/restaurant_context_service.dart';
import '../../../core/utils/qr_token_parser.dart';
import '../../../data/repositories/customer_qr_repository.dart';

class QrScannerController extends GetxController {
  final CustomerQrRepository _qrRepository = Get.find<CustomerQrRepository>();
  final RestaurantContextService _contextService =
      Get.find<RestaurantContextService>();

  late final MobileScannerController scannerController;

  final RxBool isResolving = false.obs;
  final RxBool torchEnabled = false.obs;
  final RxnString errorMessage = RxnString();
  final TextEditingController manualInputController = TextEditingController();

  String? _lastScannedToken;
  DateTime? _lastScanTime;

  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void onClose() {
    scannerController.dispose();
    manualInputController.dispose();
    super.onClose();
  }

  void onDetect(BarcodeCapture capture) {
    if (isResolving.value) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        final token = QrTokenParser.parse(raw);
        if (token != null) {
          // Debounce same token scan within 3 seconds
          final now = DateTime.now();
          if (_lastScannedToken == token &&
              _lastScanTime != null &&
              now.difference(_lastScanTime!) < const Duration(seconds: 3)) {
            return;
          }
          _lastScannedToken = token;
          _lastScanTime = now;

          resolveToken(token);
          return;
        } else {
          errorMessage.value =
              'Unrecognized QR format. Please scan a valid table QR code.';
        }
      }
    }
  }

  Future<void> resolveToken(String token) async {
    isResolving.value = true;
    errorMessage.value = null;

    try {
      developer.log(
        'QrScannerController: Resolving QR token $token',
        name: 'QrScannerController',
      );

      final qrContext = await _qrRepository.resolveQr(token);

      final context = CustomerRestaurantContext(
        restaurantId: qrContext.restaurant.id,
        restaurantName: qrContext.restaurant.name,
        branchId: qrContext.branch.id,
        branchName: qrContext.branch.name,
        tableId: qrContext.table.id,
        tableName: qrContext.table.name,
        currencyCode: qrContext.restaurant.currencyCode,
        resolvedAt: DateTime.now(),
      );

      _contextService.setContext(context);

      developer.log(
        'QrScannerController: Resolved table ${context.tableName} at ${context.restaurantName}. Routing to menu.',
        name: 'QrScannerController',
      );

      Get.offNamed(AppRoutes.menu);
    } catch (e, st) {
      developer.log(
        'QrScannerController: Failed to resolve QR: $e',
        name: 'QrScannerController',
        error: e,
        stackTrace: st,
      );
      final mapped = ErrorMapper.map(e, st);
      errorMessage.value = mapped.message;
    } finally {
      isResolving.value = false;
    }
  }

  Future<void> toggleTorch() async {
    try {
      await scannerController.toggleTorch();
      torchEnabled.toggle();
    } catch (_) {}
  }

  void submitManualInput() {
    final raw = manualInputController.text.trim();
    if (raw.isEmpty) {
      errorMessage.value = 'Please enter a QR code or link.';
      return;
    }

    final token = QrTokenParser.parse(raw);
    if (token == null) {
      errorMessage.value =
          'Invalid QR token or URL format. Please check the code.';
      return;
    }

    // Dismiss any open bottom sheet or dialog
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
      Get.back();
    }

    manualInputController.clear();
    resolveToken(token);
  }

  void clearError() {
    errorMessage.value = null;
  }
}
