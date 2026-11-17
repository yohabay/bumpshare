import 'dart:io';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// One-off generator for the launcher icon source images.
/// Uses the exact brand color and Material NFC glyph from BumpShareLogo.
void main() {
  test('render launcher icon sources', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    const double canvasSize = 1024;
    const ui.Color brand = ui.Color(0xFF6D28D9);

    // Material Icons `nfc` glyph (Icons.nfc, 24px), from
    // material-design-icons/src/device/nfc/materialicons/24px.svg
    const String nfcPath =
        'M20 2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 18H4V4h16v16zM18 6h-5c-1.1 0-2 .9-2 2v2.28c-.6.35-1 .98-1 1.72 0 1.1.9 2 2 2s2-.9 2-2c0-.74-.4-1.38-1-1.72V8h3v8H8V8h2V6H6v12h12V6z';

    final List<_Cmd> commands = _parseSvgPath(nfcPath);

    Future<void> render({
      required String path,
      required bool withBackground,
    }) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      if (withBackground) {
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, canvasSize, canvasSize),
          ui.Paint()..color = brand,
        );
      }

      const double glyphSize = 640;
      final double scale = glyphSize / 24;
      final double offset = (canvasSize - glyphSize) / 2;

      final ui.Path glyph = _buildPath(commands, scale, offset);
      canvas.drawPath(
        glyph,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.fill,
      );

      final ui.Image image = await recorder.endRecording().toImage(
            canvasSize.toInt(),
            canvasSize.toInt(),
          );
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);

      final File file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    }

    await render(path: 'assets/icon/app_icon.png', withBackground: true);
    await render(
      path: 'assets/icon/app_icon_foreground.png',
      withBackground: false,
    );
  });
}

class _Cmd {
  const _Cmd(this.op, this.values);

  final String op;
  final List<double> values;
}

List<_Cmd> _parseSvgPath(String source) {
  final RegExp tokenPattern = RegExp(r'[a-zA-Z]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?');
  final Iterable<Match> matches = tokenPattern.allMatches(source);
  final List<String> tokens = matches.map((Match m) => m.group(0)!).toList();

  final List<_Cmd> commands = <_Cmd>[];
  int i = 0;
  while (i < tokens.length) {
    final String op = tokens[i++];
    final int count = _valuesPerCommand(op);
    if (count == 0) {
      commands.add(_Cmd(op, const <double>[]));
      continue;
    }
    final List<double> values = <double>[];
    for (int n = 0; n < count && i < tokens.length; n++) {
      values.add(double.parse(tokens[i++]));
    }
    commands.add(_Cmd(op, values));
  }
  return commands;
}

int _valuesPerCommand(String op) {
  switch (op.toLowerCase()) {
    case 'm':
    case 'l':
    case 't':
      return 2;
    case 'h':
    case 'v':
      return 1;
    case 'c':
      return 6;
    case 's':
    case 'q':
      return 4;
    case 'a':
      return 7;
    case 'z':
      return 0;
    default:
      throw ArgumentError('Unsupported SVG path command: $op');
  }
}

ui.Path _buildPath(List<_Cmd> commands, double scale, double offset) {
  final ui.Path path = ui.Path();
  double x = 0;
  double y = 0;
  double subX = 0;
  double subY = 0;
  double lastCubicX = 0;
  double lastCubicY = 0;

  double sx(double v) => offset + v * scale;
  double sy(double v) => offset + v * scale;

  for (final _Cmd cmd in commands) {
    final bool relative = cmd.op == cmd.op.toLowerCase();
    final String op = cmd.op.toLowerCase();
    final List<double> v = cmd.values;

    switch (op) {
      case 'm':
        x = relative ? x + v[0] : v[0];
        y = relative ? y + v[1] : v[1];
        subX = x;
        subY = y;
        path.moveTo(sx(x), sy(y));
        break;
      case 'l':
        x = relative ? x + v[0] : v[0];
        y = relative ? y + v[1] : v[1];
        path.lineTo(sx(x), sy(y));
        break;
      case 'h':
        x = relative ? x + v[0] : v[0];
        path.lineTo(sx(x), sy(y));
        break;
      case 'v':
        y = relative ? y + v[0] : v[0];
        path.lineTo(sx(x), sy(y));
        break;
      case 'c':
        final double c1x = relative ? x + v[0] : v[0];
        final double c1y = relative ? y + v[1] : v[1];
        final double c2x = relative ? x + v[2] : v[2];
        final double c2y = relative ? y + v[3] : v[3];
        x = relative ? x + v[4] : v[4];
        y = relative ? y + v[5] : v[5];
        path.cubicTo(sx(c1x), sy(c1y), sx(c2x), sy(c2y), sx(x), sy(y));
        lastCubicX = c2x;
        lastCubicY = c2y;
        break;
      case 's':
        final double c2x = relative ? x + v[0] : v[0];
        final double c2y = relative ? y + v[1] : v[1];
        final double c1x = 2 * x - lastCubicX;
        final double c1y = 2 * y - lastCubicY;
        x = relative ? x + v[2] : v[2];
        y = relative ? y + v[3] : v[3];
        path.cubicTo(sx(c1x), sy(c1y), sx(c2x), sy(c2y), sx(x), sy(y));
        lastCubicX = c2x;
        lastCubicY = c2y;
        break;
      case 'z':
        path.close();
        x = subX;
        y = subY;
        break;
    }
  }
  return path;
}
