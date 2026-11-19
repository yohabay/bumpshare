import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumpshare/main.dart';
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
  testWidgets('BumpShare boots into the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BumpShareApp());
    expect(find.text('BumpShare'), findsOneWidget);
    expect(find.text('Share Contact Card'), findsOneWidget);
  });
  testWidgets('QR dialog lays out without intrinsic-dimension errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BumpShareApp());
    await tester.tap(find.text('Show QR code instead'));
    await tester.pumpAndSettle();
    expect(find.text('Share via QR code'), findsOneWidget);
    expect(
      find.text('Scan to save the contact — works without NFC or internet.'),
      findsOneWidget,
    );
  });
}
