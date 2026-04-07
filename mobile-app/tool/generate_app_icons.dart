import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

final _root = Directory.current.path;

String _p(List<String> parts) => parts.join(Platform.pathSeparator);

Future<void> main(List<String> args) async {
  final source =
      args.isNotEmpty ? args.first : _p(['assets', 'app_logo', 'App_Icon.png']);
  final sourceFile = File(source);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Icon source not found: ${sourceFile.path}');
    exitCode = 2;
    return;
  }

  final decoded = img.decodePng(sourceFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Failed to decode PNG: ${sourceFile.path}');
    exitCode = 3;
    return;
  }

  stdout.writeln('Using source: ${sourceFile.path}');
  stdout.writeln('Decoded size: ${decoded.width}x${decoded.height}');

  await _generateIos(decoded);
  await _generateAndroid(decoded);

  stdout.writeln('Done.');
}

Future<void> _generateIos(img.Image base) async {
  final appIconDir = Directory(
    _p([
      'ios',
      'Runner',
      'Assets.xcassets',
      'AppIcon.appiconset',
    ]),
  );
  final contentsFile = File(_p([appIconDir.path, 'Contents.json']));
  if (!contentsFile.existsSync()) {
    stderr.writeln('iOS Contents.json not found: ${contentsFile.path}');
    return;
  }

  final contents =
      jsonDecode(contentsFile.readAsStringSync()) as Map<String, dynamic>;
  final images = (contents['images'] as List).cast<Map<String, dynamic>>();

  int generated = 0;
  for (final entry in images) {
    final filename = entry['filename'] as String?;
    if (filename == null || filename.trim().isEmpty) continue;

    final sizeStr = entry['size'] as String?; // e.g. "20x20"
    final scaleStr = entry['scale'] as String?; // e.g. "2x"
    if (sizeStr == null || scaleStr == null) continue;

    final parts = sizeStr.split('x');
    if (parts.length != 2) continue;
    final logical = double.tryParse(parts[0]);
    final scale = int.tryParse(scaleStr.replaceAll('x', ''));
    if (logical == null || scale == null) continue;

    final px = (logical * scale).round();
    final outPath = _p([appIconDir.path, filename]);
    await _writeResizedPng(base, px, px, outPath);
    generated++;
  }

  stdout.writeln('iOS icons generated: $generated → ${appIconDir.path}');
}

Future<void> _generateAndroid(img.Image base) async {
  final resDir = Directory(_p(['android', 'app', 'src', 'main', 'res']));
  if (!resDir.existsSync()) {
    stderr.writeln('Android res dir not found: ${resDir.path}');
    return;
  }

  // Standard launcher icon sizes (px).
  const mipmaps = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  int generated = 0;
  for (final e in mipmaps.entries) {
    final dir = Directory(_p([resDir.path, e.key]));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final size = e.value;
    final launcher = _p([dir.path, 'ic_launcher.png']);
    final round = _p([dir.path, 'ic_launcher_round.png']);

    await _writeResizedPng(base, size, size, launcher);
    await _writeResizedPng(base, size, size, round);
    generated += 2;
  }

  stdout.writeln('Android icons generated: $generated → ${resDir.path}');
}

Future<void> _writeResizedPng(
  img.Image base,
  int width,
  int height,
  String outPath,
) async {
  final resized = img.copyResize(
    base,
    width: width,
    height: height,
    interpolation: img.Interpolation.cubic,
  );
  final bytes = img.encodePng(resized);
  final outFile = File(outPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(bytes);
}

