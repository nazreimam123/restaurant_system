import 'package:app_models/app_models.dart';

/// Repository interface for customer table QR token resolution.
abstract class CustomerQrRepository {
  /// Resolves an opaque table QR token into verified ordering context.
  Future<QrContext> resolveQr(String qrToken);
}
