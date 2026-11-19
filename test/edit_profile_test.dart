import 'package:bumpshare/screens/edit_profile_screen.dart';
import 'package:bumpshare/widgets/social_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });
  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EditProfileScreen()),
    );
    await tester.pumpAndSettle();
  }
  testWidgets('starts with a single link field and adds more with +',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    expect(find.byType(TextField), findsNWidgets(7));
    expect(find.byType(SocialBadge), findsOneWidget);
    await tester.ensureVisible(find.text('Add link'));
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(8));
    expect(find.byType(SocialBadge), findsNWidgets(2));
    await tester.ensureVisible(find.text('Add link'));
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(9));
  });
  testWidgets('the logo and label follow the pasted link',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    final Finder linkField = find.byType(TextField).at(6);
    await tester.enterText(linkField, 'linkedin.com/in/ada');
    await tester.pump();
    expect(find.text('LinkedIn link'), findsOneWidget);
    await tester.enterText(linkField, 'https://instagram.com/ada');
    await tester.pump();
    expect(find.text('Instagram link'), findsOneWidget);
    await tester.enterText(linkField, 'https://example.com');
    await tester.pump();
    expect(find.text('Social link'), findsOneWidget);
  });
  testWidgets('removing a link field keeps at least one', (WidgetTester tester) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField).at(6), 'github.com/ada');
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.remove_circle_outline));
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(7));
    expect(find.text('github.com/ada'), findsNothing);
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(8));
    await tester.ensureVisible(find.byIcon(Icons.remove_circle_outline).last);
    await tester.tap(find.byIcon(Icons.remove_circle_outline).last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(7));
  });
  testWidgets('card colour options are available', (WidgetTester tester) async {
    await pumpEditor(tester);
    expect(find.text('Card colour'), findsOneWidget);
    for (final String name in <String>['Purple', 'Teal', 'Rose', 'Indigo']) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
