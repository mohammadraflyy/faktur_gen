// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Generates the Faktura app icon (1024x1024) matching the AppLogo widget.
/// Gradient blue→green background, white "F", fold corner, receipt lines.
///
/// Run: dart run tool/generate_icon.dart
void main() {
  const size = 1024;
  final radius = (size * 0.22).toInt(); // ~225

  final image = img.Image(width: size, height: size);

  // Colors
  const blueR = 0x25, blueG = 0x63, blueB = 0xEB;
  const greenR = 0x05, greenG = 0x96, greenB = 0x69;

  // Draw rounded rect with gradient
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      // Check if inside rounded rect
      if (!_inRoundedRect(x, y, size, size, radius)) continue;

      // Diagonal gradient (top-left to bottom-right)
      final t = ((x + y) / (2 * size)).clamp(0.0, 1.0);
      final r = _lerp(blueR, greenR, t);
      final g = _lerp(blueG, greenG, t);
      final b = _lerp(blueB, greenB, t);

      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Draw fold corner (top-right triangle with slight transparency)
  final foldSize = (size * 0.28).toInt();
  for (var y = 0; y < foldSize; y++) {
    for (var x = size - foldSize; x < size; x++) {
      final lx = x - (size - foldSize);
      if (lx > y) continue; // below diagonal
      if (!_inRoundedRect(x, y, size, size, radius)) continue;

      final existing = image.getPixel(x, y);
      // Blend white at 15% opacity
      final nr = _lerp(existing.r.toInt(), 255, 0.15);
      final ng = _lerp(existing.g.toInt(), 255, 0.15);
      final nb = _lerp(existing.b.toInt(), 255, 0.15);
      image.setPixelRgba(x, y, nr, ng, nb, 255);
    }
  }

  // Draw "F" letter - simple block letter
  _drawF(image, size);

  // Draw receipt lines at bottom
  _drawLine(image, (size * 0.22).toInt(), (size * 0.82).toInt(),
      (size * 0.78).toInt(), 3, 255, 255, 255, 60);
  _drawLine(image, (size * 0.32).toInt(), (size * 0.86).toInt(),
      (size * 0.68).toInt(), 3, 255, 255, 255, 38);

  // Save
  final pngBytes = img.encodePng(image);
  final outPath = 'assets/app_icon.png';
  Directory('assets').createSync(recursive: true);
  File(outPath).writeAsBytesSync(pngBytes);
  print('Icon generated: $outPath (${pngBytes.length} bytes)');
}

void _drawF(img.Image image, int size) {
  // F letter positioned centered, sized ~48% of icon
  final fontSize = (size * 0.48).toInt();
  final letterW = (fontSize * 0.55).toInt();
  final letterH = (fontSize * 0.72).toInt();
  final strokeW = (fontSize * 0.14).toInt();

  final startX = (size - letterW) ~/ 2;
  final startY = (size - letterH) ~/ 2 - (size * 0.04).toInt();

  // Vertical bar (left side of F)
  _fillRect(image, startX, startY, startX + strokeW, startY + letterH,
      255, 255, 255, 230);

  // Top horizontal bar
  _fillRect(image, startX, startY, startX + letterW, startY + strokeW,
      255, 255, 255, 230);

  // Middle horizontal bar
  final midY = startY + (letterH * 0.42).toInt();
  _fillRect(image, startX, midY, startX + (letterW * 0.8).toInt(),
      midY + strokeW, 255, 255, 255, 230);
}

void _fillRect(img.Image image, int x1, int y1, int x2, int y2, int r,
    int g, int b, int a) {
  for (var y = y1; y < y2; y++) {
    for (var x = x1; x < x2; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        if (a >= 255) {
          image.setPixelRgba(x, y, r, g, b, 255);
        } else {
          final existing = image.getPixel(x, y);
          final t = a / 255.0;
          final nr = _lerp(existing.r.toInt(), r, t);
          final ng = _lerp(existing.g.toInt(), g, t);
          final nb = _lerp(existing.b.toInt(), b, t);
          image.setPixelRgba(x, y, nr, ng, nb, 255);
        }
      }
    }
  }
}

void _drawLine(img.Image image, int x1, int y, int x2, int thickness, int r,
    int g, int b, int a) {
  _fillRect(image, x1, y, x2, y + thickness, r, g, b, a);
}

bool _inRoundedRect(int x, int y, int w, int h, int r) {
  // Check corners
  if (x < r && y < r) {
    return _dist(x, y, r, r) <= r;
  }
  if (x >= w - r && y < r) {
    return _dist(x, y, w - r - 1, r) <= r;
  }
  if (x < r && y >= h - r) {
    return _dist(x, y, r, h - r - 1) <= r;
  }
  if (x >= w - r && y >= h - r) {
    return _dist(x, y, w - r - 1, h - r - 1) <= r;
  }
  return true;
}

double _dist(int x1, int y1, int x2, int y2) {
  return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)).toDouble();
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);
