import 'package:bumpshare/screens/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });
  testWidgets('success screen invites the receiver to make a card',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SuccessScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Contact shared'), findsOneWidget);
    expect(
      find.text('They can make their own BumpShare card too.'),
      findsOneWidget,
    );
  });
}
