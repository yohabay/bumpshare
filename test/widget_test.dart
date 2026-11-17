// BumpShare smoke test: verifies the app boots into the Home screen.
//
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';

import 'package:bumpshare/main.dart';

void main() {
  testWidgets('BumpShare boots into the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BumpShareApp());

    // BumpShare wordmark renders (hero).
    expect(find.text('BumpShare'), findsOneWidget);

    // Primary call to action is present.
    expect(find.text('Share Contact Card'), findsOneWidget);
  });
}
