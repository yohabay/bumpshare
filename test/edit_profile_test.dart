import 'package:bumpshare/screens/edit_profile_screen.dart';
import 'package:bumpshare/widgets/social_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
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

    // Name, phone, email and exactly one link field.
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.byType(SocialBadge), findsOneWidget);

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.byType(SocialBadge), findsNWidgets(2));

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('the logo and label follow the pasted link',
      (WidgetTester tester) async {
    await pumpEditor(tester);

    final Finder linkField = find.byType(TextField).at(3);
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

    // With one field the remove button clears it instead of deleting it.
    await tester.enterText(find.byType(TextField).at(3), 'github.com/ada');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text('github.com/ada'), findsNothing);

    // Adding and removing a second field returns to one.
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(5));
    await tester.tap(find.byIcon(Icons.remove_circle_outline).last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(4));
  });
}
