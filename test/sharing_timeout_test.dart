import 'package:bumpshare/screens/sharing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  const MethodChannel nfcChannel = MethodChannel('bumpshare_nfc');
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nfcChannel, (MethodCall call) async => true);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nfcChannel, null);
  });
  testWidgets('timeout shows retry and QR fallback', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SharingScreen(
          shareUrl: 'https://bumbshare.vercel.app/#demo',
          timeout: Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Ready to share'), findsOneWidget);
    expect(find.text('Waiting for a tap…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('No tap detected'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Use QR code'), findsOneWidget);
  });
}
