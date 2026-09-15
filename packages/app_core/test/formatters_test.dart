import 'package:test/test.dart';
import 'package:app_core/app_core.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats INR minor units correctly without floating point errors', () {
      expect(CurrencyFormatter.format(19950), '₹199.50');
      expect(CurrencyFormatter.format(0), '₹0.00');
      expect(CurrencyFormatter.format(50), '₹0.50');
      expect(CurrencyFormatter.format(100), '₹1.00');
      expect(CurrencyFormatter.format(1000000), '₹10000.00');
    });

    test('formats other currencies with symbols or codes', () {
      expect(CurrencyFormatter.format(1500, currencyCode: 'USD'), '\$15.00');
      expect(CurrencyFormatter.format(2500, currencyCode: 'AED'), 'AED 25.00');
    });
  });

  group('ErrorMapper', () {
    test('maps raw network socket errors to NetworkException', () {
      final error = FormatException('Failed host lookup: api.supabase.co');
      final mapped = ErrorMapper.map(error);
      expect(mapped, isA<NetworkException>());
    });

    test('maps known API error code correctly', () {
      final mapped = ErrorMapper.fromApiError(
        code: ErrorCode.orderingPaused,
        message: 'Kitchen is currently not accepting orders',
      );
      expect(mapped, isA<DomainException>());
      expect(mapped.code, ErrorCode.orderingPaused);
    });
  });
}
