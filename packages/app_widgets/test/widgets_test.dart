import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_models/app_models.dart';
import 'package:app_widgets/app_widgets.dart';

void main() {
  testWidgets('AppButton renders label and triggers callback', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton(label: 'Test CTA', onPressed: () => pressed = true),
        ),
      ),
    );

    expect(find.text('Test CTA'), findsOneWidget);
    await tester.tap(find.text('Test CTA'));
    expect(pressed, isTrue);
  });

  testWidgets('AppStatusChip renders OrderStatus label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppStatusChip.forOrderStatus(OrderStatus.preparing),
        ),
      ),
    );

    expect(find.text('Preparing'), findsOneWidget);
  });
}
