import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumpshare/screens/splash_screen.dart';
void main() {
  const MethodChannel nfcChannel = MethodChannel('bumpshare_nfc');
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nfcChannel, (MethodCall call) async => true);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nfcChannel, null);
  });
  testWidgets('splash shows branding then opens the home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(duration: Duration(milliseconds: 100)),
      ),
    );
    expect(find.byIcon(Icons.nfc), findsWidgets);
    expect(find.text('BumpShare'), findsNothing);
    expect(find.text('Tap two phones. Share a contact.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Share Contact Card'), findsOneWidget);
  });
}
