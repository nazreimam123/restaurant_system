import 'package:test/test.dart';
import 'package:app_models/app_models.dart';

void main() {
  group('Enums serialization', () {
    test('OrderStatus round-trips correctly and validates snake_case', () {
      expect(OrderStatus.awaitingPayment.toJson(), 'awaiting_payment');
      expect(
        OrderStatus.fromJson('awaiting_payment'),
        OrderStatus.awaitingPayment,
      );
      expect(OrderStatus.preparing.toJson(), 'preparing');
      expect(OrderStatus.fromJson('preparing'), OrderStatus.preparing);
      expect(
        () => OrderStatus.fromJson('invalid_status'),
        throwsFormatException,
      );
    });

    test('OrderType round-trips correctly', () {
      expect(OrderType.dineIn.toJson(), 'dine_in');
      expect(OrderType.fromJson('dine_in'), OrderType.dineIn);
      expect(() => OrderType.fromJson('curbside'), throwsFormatException);
    });

    test('PaymentStatus round-trips correctly', () {
      expect(PaymentStatus.partiallyRefunded.toJson(), 'partially_refunded');
      expect(
        PaymentStatus.fromJson('partially_refunded'),
        PaymentStatus.partiallyRefunded,
      );
    });
  });

  group('Cart and Product calculations', () {
    test(
      'CartItem calculates unitPriceMinor and lineTotalMinor in integer units',
      () {
        const item = CartItem(
          lineId: 'line-1',
          productId: 'prod-1',
          productName: 'Paneer Butter Masala',
          basePriceMinor: 25000,
          quantity: 2,
          modifiers: [
            CartItemModifier(
              modifierId: 'mod-1',
              name: 'Extra Butter',
              priceDeltaMinor: 3000,
            ),
            CartItemModifier(
              modifierId: 'mod-2',
              name: 'Extra Spicy',
              priceDeltaMinor: 0,
            ),
          ],
        );

        // Base: 25000, modifier: +3000 => unit: 28000
        expect(item.unitPriceMinor, 28000);
        // Line total: 28000 * 2 => 56000
        expect(item.lineTotalMinor, 56000);
      },
    );

    test('ApiResult validates success and failure invariants', () {
      final success = ApiResult<String>.success('test_data');
      expect(success.isSuccess, isTrue);
      expect(success.data, 'test_data');

      final failure = ApiResult<String>.failure(
        const ApiError(code: 'TEST_ERROR', message: 'Test error message'),
      );
      expect(failure.isFailure, isTrue);
      expect(failure.error?.code, 'TEST_ERROR');
    });
  });
}
