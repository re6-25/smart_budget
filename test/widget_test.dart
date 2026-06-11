import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/main.dart';

void main() {
  testWidgets('Smart Budget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBudgetApp());
    expect(find.byType(SmartBudgetApp), findsOneWidget);
  });
}
