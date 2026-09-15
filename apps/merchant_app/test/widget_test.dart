import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:merchant_app/main.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('MerchantApp bootstrap and splash test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MerchantApp());

    // Verify merchant splash elements render initially
    expect(find.text('Merchant Portal'), findsOneWidget);
    expect(find.text('Operations • Live Orders • KDS'), findsOneWidget);

    // Advance time past the splash delay to complete transition
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
  });
}
