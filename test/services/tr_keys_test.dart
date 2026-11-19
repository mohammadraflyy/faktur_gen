import 'dart:io';

import 'package:faktur_gen/services/locale_service.dart';
import 'package:flutter_test/flutter_test.dart';

// tr() falls back to the raw key, so a typo shows "settings.foo" to the user.
void main() {
  test('every tr() key used in lib/ exists', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final call = RegExp(r"trN?\('([a-z_.0-9]+)'");
    final missing = {
      for (final f in files)
        for (final m in call.allMatches(f.readAsStringSync()))
          if (tr(m.group(1)!) == m.group(1)) m.group(1)!,
    };
    expect(missing, isEmpty);
  });
}
