import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/services/updater_service.dart';

void main() {
  group('UpdaterService.compareVersions', () {
    final cmp = UpdaterService.compareVersions;

    test('compares parts numerically, not as text', () {
      expect(cmp('1.0.10', '1.0.9'), greaterThan(0));
      expect(cmp('1.0.9', '1.0.10'), lessThan(0));
    });

    test('equal versions compare as 0', () {
      expect(cmp('1.2.3', '1.2.3'), 0);
    });

    test('strips a leading v', () {
      expect(cmp('v1.0.5', '1.0.5'), 0);
      expect(cmp('V1.0.6', '1.0.5'), greaterThan(0));
    });

    test('ignores +build and -pre suffixes', () {
      expect(cmp('1.0.5+42', '1.0.5+1'), 0);
      expect(cmp('1.0.5-beta', '1.0.5'), 0);
    });

    test('pads missing parts with 0', () {
      expect(cmp('1.0', '1.0.0'), 0);
      expect(cmp('1.1', '1.0.9'), greaterThan(0));
    });
  });
}
