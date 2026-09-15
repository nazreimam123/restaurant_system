import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:customer_app/main.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CustomerApp bootstrap and splash test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CustomerApp());

    // Verify brand splash elements render initially
    expect(find.text('Restaurant Ordering'), findsOneWidget);
    expect(find.text('Scan • Browse • Order • Enjoy'), findsOneWidget);

    // Advance time past the splash delay to complete transition
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
  });
}
