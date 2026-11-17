// Renders the real app screens to PNG files for review / store listings.
//
// Run explicitly (it is not part of `flutter test` because it lives in tools/):
//
//   flutter test tools/render_screens_test.dart
//
// Output: screenshots/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bumpshare/main.dart';
import 'package:bumpshare/models/profile.dart';
import 'package:bumpshare/screens/edit_profile_screen.dart';
import 'package:bumpshare/screens/home_screen.dart';
import 'package:bumpshare/screens/profile_screen.dart';
import 'package:bumpshare/screens/sharing_screen.dart';
import 'package:bumpshare/screens/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _fontRoot =
    r'C:\tools\flutter\bin\cache\artifacts\material_fonts';
const String _faFontRoot =
    r'C:\Users\HP\AppData\Local\Pub\Cache\hosted\pub.dev\font_awesome_flutter-11.0.0\lib\fonts';
const String _outDir = 'screenshots';

Future<void> _loadFonts() async {
  const Map<String, List<String>> families = <String, List<String>>{
    'Roboto': <String>[
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ],
    'MaterialIcons': <String>['materialicons-regular.otf'],
  };

  for (final MapEntry<String, List<String>> entry in families.entries) {
    final FontLoader loader = FontLoader(entry.key);
    for (final String file in entry.value) {
      final File fontFile = File('$_fontRoot\\$file');
      if (!fontFile.existsSync()) continue;
      loader.addFont(
        fontFile.readAsBytes().then(
              (Uint8List bytes) => ByteData.sublistView(bytes),
            ),
      );
    }
    await loader.load();
  }

  // Brand marks for the social badges.
  final FontLoader brands = FontLoader('FontAwesomeBrands');
  final Directory faDir = Directory(_faFontRoot);
  if (faDir.existsSync()) {
    for (final File file in faDir.listSync().whereType<File>()) {
      if (!file.path.toLowerCase().endsWith('.otf')) continue;
      brands.addFont(
        file.readAsBytes().then(
              (Uint8List bytes) => ByteData.sublistView(bytes),
            ),
      );
    }
    await brands.load();
  }
}

void _mockNfc() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('bumpshare_nfc'),
    (MethodCall call) async => switch (call.method) {
      'isNfcAvailable' => true,
      'isNfcEnabled' => true,
      'isHceSupported' => true,
      'startSharing' => true,
      'stopSharing' => true,
      'openNfcSettings' => true,
      _ => null,
    },
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  final RenderRepaintBoundary boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundaryKey));
  final ui.Image image = await boundary.toImage(pixelRatio: 2);
  final ByteData? data = await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  final Directory dir = Directory(_outDir)..createSync(recursive: true);
  File('${dir.path}\\$name.png')
      .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  image.dispose();
}

final Key _boundaryKey = UniqueKey();

Future<void> _show(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    RepaintBoundary(key: _boundaryKey, child: BumpShareApp(home: screen)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  setUp(() {
    _mockNfc();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bumpshare_profile':
          '{"name":"Ada Lovelace","phone":"+1 555 0100","email":"ada@example.com",'
              '"socialLinks":["https://linkedin.com/in/ada",'
              '"https://instagram.com/ada","https://x.com/ada",'
              '"https://github.com/ada","https://adalovelace.dev"]}',
    });
  });

  testWidgets('render app screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _show(tester, const HomeScreen());
    await _capture(tester, '01_home');

    await tester.tap(find.text('Show QR code instead'));
    await tester.pumpAndSettle();
    await _capture(tester, '02_home_qr_fallback');

    await _show(tester, const SharingScreen());
    await _capture(tester, '03_sharing');

    await _show(tester, const SuccessScreen());
    await _capture(tester, '04_success');

    await _show(tester, const ProfileScreen());
    await _capture(tester, '05_profile');

    const Profile sample = Profile(
      name: 'Ada Lovelace',
      phone: '+1 555 0100',
      email: 'ada@example.com',
      socialLinks: <String>[
        'https://linkedin.com/in/ada',
        'https://instagram.com/ada',
        'https://x.com/ada',
        'https://github.com/ada',
        'https://adalovelace.dev',
      ],
    );
    await _show(tester, const EditProfileScreen(initial: sample));
    await _capture(tester, '06_edit_profile');
  });
}
